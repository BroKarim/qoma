import SwiftUI

struct NewSessionView: View {
    @ObservedObject var coordinator: SessionCoordinator
    @State private var taskTitle: String = ""
    @State private var selectedMode: FocusPolicyMode = .timerOnly
    @State private var selectedMinutes: Int = 10
    @State private var selectedApps: Set<String> = []
    @State private var selectedDomains: Set<String> = []
    @State private var showPermissionNeeded = false

    private let durationOptions: [Int] = [180, 10, 20, 30, 45, 60]

    var body: some View {
        Group {
            if let snapshot = coordinator.snapshot {
                ActiveSessionCard(coordinator: coordinator, snapshot: snapshot)
            } else {
                startForm
            }
        }
    }

    private var startForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New Session")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 8) {
                Text("What are you working on?")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                TextField("Optional task name", text: $taskTitle)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Focus mode")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Picker("", selection: $selectedMode) {
                    Text("Allowing").tag(FocusPolicyMode.allowing)
                    Text("Blocking").tag(FocusPolicyMode.blocking)
                    Text("Timer Only").tag(FocusPolicyMode.timerOnly)
                }
                .pickerStyle(.segmented)
                Text(modeExplanation)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Duration")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Picker("", selection: $selectedMinutes) {
                    ForEach(durationOptions, id: \.self) { minutes in
                        Text(minutes == 180 ? "3 hours" : "\(minutes) min").tag(minutes)
                    }
                }
                .pickerStyle(.segmented)
            }

            if selectedMode != .timerOnly {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Apps")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    AppDomainPicker(mode: selectedMode, selectedApps: $selectedApps, selectedDomains: $selectedDomains)
                }
            }

            if showPermissionNeeded {
                Text("App monitoring permission is needed for Allowing/Blocking mode. You can switch to Timer Only.")
                    .font(.system(size: 11))
                    .foregroundColor(.qyubeAccent)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button(action: startSession) {
                HStack {
                    Spacer()
                    Text("Start session")
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(Color.qyubeAccent)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
        }
    }

    private var modeExplanation: String {
        switch selectedMode {
        case .allowing:
            return "Only the apps and sites you choose are considered safe. Everything else gets a gentle visual nudge."
        case .blocking:
            return "The apps and sites you choose trigger a visual nudge. Everything else is safe."
        case .timerOnly:
            return "Just the timer and companion. No app or site monitoring."
        }
    }

    private func startSession() {
        var policy = SessionPolicy(mode: selectedMode)
        switch selectedMode {
        case .allowing:
            policy.allowedApps = selectedApps
            policy.allowedDomains = selectedDomains
        case .blocking:
            policy.blockedApps = selectedApps
            policy.blockedDomains = selectedDomains
        case .timerOnly:
            break
        }

        let draft = SessionDraft(taskTitle: taskTitle, plannedMinutes: selectedMinutes, policy: policy)
        coordinator.startSession(draft: draft)
    }
}

private struct ActiveSessionCard: View {
    @ObservedObject var coordinator: SessionCoordinator
    let snapshot: ActiveSessionSnapshot
    @State private var editingTitle: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Active Session")
                .font(.system(size: 24, weight: .semibold))

            VStack(alignment: .leading, spacing: 8) {
                Text("Task")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                TextField("Focus session", text: $editingTitle)
                    .textFieldStyle(.roundedBorder)
                    .onAppear { editingTitle = snapshot.draft.taskTitle }
                    .onChange(of: snapshot.draft.taskTitle) { editingTitle = snapshot.draft.taskTitle }
                    .onSubmit { coordinator.updateTask(title: editingTitle) }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Mode")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Text(modeName)
                    .font(.system(size: 13))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Time remaining")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Text(formattedTime)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
            }

            HStack(spacing: 12) {
                if coordinator.isPaused {
                    Button("Resume") { coordinator.resumeSession() }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("Pause") { coordinator.pauseSession() }
                        .buttonStyle(.bordered)
                }

                Button("Stop") { coordinator.stopSession() }
                    .buttonStyle(.bordered)
                    .tint(.qyubeAccent)
            }

            if coordinator.isDistractionActive, let activity = latestActivityDescription {
                Text(activity)
                    .font(.system(size: 11))
                    .foregroundColor(.qyubeAccent)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private var modeName: String {
        switch snapshot.draft.policy.mode {
        case .allowing: return "Allowing"
        case .blocking: return "Blocking"
        case .timerOnly: return "Timer Only"
        }
    }

    private var formattedTime: String {
        let totalSeconds = max(0, Int(coordinator.remainingTime.rounded(.down)))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var latestActivityDescription: String? {
        // Distraction state is maintained by the coordinator but activity details live in DistractionCoordinator.
        // For now, show a generic cue in the Home card.
        "Distraction detected — stay with your focus"
    }
}

private struct AppDomainPicker: View {
    let mode: FocusPolicyMode
    @Binding var selectedApps: Set<String>
    @Binding var selectedDomains: Set<String>

    private let sampleApps = [
        ("com.apple.dt.Xcode", "Xcode"),
        ("com.google.Chrome", "Google Chrome"),
        ("com.apple.Safari", "Safari"),
        ("com.tinyspeck.slackmacgap", "Slack"),
        ("com.figma.Desktop", "Figma"),
    ]

    private let sampleDomains = [
        "github.com",
        "stackoverflow.com",
        "docs.google.com",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(sampleApps, id: \.0) { bundleID, name in
                Toggle(name, isOn: Binding(
                    get: { selectedApps.contains(bundleID) },
                    set: { isOn in
                        if isOn { selectedApps.insert(bundleID) } else { selectedApps.remove(bundleID) }
                    }
                ))
                .toggleStyle(.checkbox)
            }

            Text("Domains (advanced)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.top, 4)

            ForEach(sampleDomains, id: \.self) { domain in
                Toggle(domain, isOn: Binding(
                    get: { selectedDomains.contains(domain) },
                    set: { isOn in
                        if isOn { selectedDomains.insert(domain) } else { selectedDomains.remove(domain) }
                    }
                ))
                .toggleStyle(.checkbox)
            }
        }
    }
}
