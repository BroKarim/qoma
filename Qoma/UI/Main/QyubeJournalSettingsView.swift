import SwiftUI
import UserNotifications

struct QyubeJournalSettingsView: View {
    @ObservedObject private var focus = FocusPreferences.shared
    @AppStorage("qyube.coveAtmosphere") private var atmosphere = "Auto"
    @AppStorage("qyube.sessionNotifications") private var sessionNotifications = false

    @State private var confirmErase = false
    @State private var errorMessage: String?

    private let atmosphereOptions = ["Auto", "Morning", "Sunset", "Night"]

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = info?["CFBundleVersion"] as? String ?? "1"
        return "Version \(v) (\(b))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                Text("Settings").font(.system(size: 25, weight: .semibold))

                section("GENERAL", seed: 0) {
                    toggleRow("Show floating timer", isOn: Binding(
                        get: { !focus.hideFloatingTimer },
                        set: { focus.hideFloatingTimer = !$0 }))
                    toggleRow("Session notifications", isOn: $sessionNotifications)
                }

                section("COVE", seed: 1) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Cove atmosphere")
                            Spacer(minLength: 12)
                            atmosphereMenu
                        }
                        Text("Auto follows the time on this Mac.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Button {
                        NotificationCenter.default.post(name: .qyubeResetFloatingPositions, object: nil)
                    } label: {
                        Text("Reset floating positions").underline()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.qyubeAccent)
                    .padding(.top, 2)
                }

                section("APP", seed: 2) {
                    Button { UpdaterManager.shared.checkForUpdates() } label: {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Check for Updates")
                                Text(versionText)
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 3) {
                        Button("Erase local data", role: .destructive) { confirmErase = true }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.red.opacity(0.8))
                        Text("Session history, catches and local preferences.")
                            .font(.caption).foregroundStyle(.secondary)
                        if let errorMessage {
                            Text(errorMessage).foregroundStyle(.red).font(.caption)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .font(.system(size: 14))
            .foregroundStyle(Color.qyubeMenuInk)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .qyubeHideNativeScrollers()
            .onChange(of: sessionNotifications) { _, enabled in
                guard enabled else { return }
                Task {
                    do {
                        let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert])
                        sessionNotifications = granted
                        if !granted { errorMessage = "Enable notifications for qyube in System Settings to receive session reminders." }
                    } catch {
                        sessionNotifications = false
                        errorMessage = error.localizedDescription
                    }
                }
            }
            .alert("Erase local data?", isPresented: $confirmErase) {
                Button("Cancel", role: .cancel) {}
                Button("Erase", role: .destructive) { erase() }
            } message: {
                Text("Permanently erase this account’s session history, catches and activity on this Mac. Purchases, account and trial are kept. Stop any active session first. Archived backups are not removed.")
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Building blocks

    private func section<Content: View>(
        _ title: String, seed: Int, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(title, seed: seed)
            content()
        }
    }

    private func sectionHeading(_ title: String, seed: Int) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.qyubeSelection.opacity(0.6), in: Capsule())
            InkLine(seed: seed)
                .stroke(Color.qyubeAccent.opacity(0.55),
                        style: StrokeStyle(lineWidth: 1, lineCap: .round))
                .frame(height: 8)
        }
    }

    /// Label kiri, toggle kanan (justify-between), toggle diberi warna aksen.
    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
            Spacer(minLength: 12)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .tint(Color.qyubeAccent)
        }
    }

    /// Dropdown custom (bukan Picker bawaan).
    private var atmosphereMenu: some View {
        Menu {
            ForEach(atmosphereOptions, id: \.self) { option in
                Button {
                    atmosphere = option
                } label: {
                    if option == atmosphere {
                        Label(option, systemImage: "checkmark")
                    } else {
                        Text(option)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(atmosphere)
                Spacer(minLength: 8)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .frame(width: 124)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.qyubeSelection.opacity(0.35)))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.qyubeAccent.opacity(0.45), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private func erase() {
        do {
            guard let database = QomaDatabase.shared else { throw QomaDatabase.error("Database unavailable") }
            let account = AccessCoordinator.shared.accountID ?? "signed-out"
            _ = AnalyticsStore.shared.loadFocusSessions()
            try database.eraseLocalData(accountID: account)
            atmosphere = "Auto"
            focus.hideFloatingTimer = false
            errorMessage = nil
            NotificationCenter.default.post(name: .qyubeCollectionChanged, object: nil)
        } catch { errorMessage = error.localizedDescription }
    }
}

/// Garis tinta ala gambar tangan: tiap `seed` punya kemiringan & lengkung berbeda,
/// jadi GENERAL / COVE / APP tidak simetris.
private struct InkLine: Shape {
    var seed: Int

    func path(in rect: CGRect) -> Path {
        let tilts: [CGFloat] = [1.2, -1.0, 0.7]
        let waves: [CGFloat] = [1.6, -1.9, 1.1]
        let tilt = tilts[seed % tilts.count]
        let wave = waves[seed % waves.count]
        let y = rect.midY

        var p = Path()
        p.move(to: CGPoint(x: 0, y: y - tilt))
        p.addCurve(
            to: CGPoint(x: rect.maxX, y: y + tilt),
            control1: CGPoint(x: rect.width * 0.30, y: y + wave),
            control2: CGPoint(x: rect.width * 0.70, y: y - wave))
        return p
    }
}

extension Notification.Name {
    static let qyubeResetFloatingPositions = Notification.Name("qyube.resetFloatingPositions")
}