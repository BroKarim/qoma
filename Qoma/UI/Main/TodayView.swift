import SwiftUI

struct TodayView: View {
    let sessions: [FocusSession]
    let activeSession: ActiveSessionSnapshot?
    let remainingTime: TimeInterval
    let breakRemaining: TimeInterval?
    let onCreateSession: () -> Void
    let onBackToSession: () -> Void
    let onSelectSession: (FocusSession) -> Void

    private var todaySessions: [FocusSession] {
        self.sessions
            .filter { Calendar.current.isDateInToday($0.startedAt) }
            .sorted { $0.startedAt > $1.startedAt }
    }

    private var focusedSeconds: TimeInterval {
        let completedSeconds = self.todaySessions.reduce(0) { $0 + $1.actualActiveSeconds }
        guard let activeSession, Calendar.current.isDateInToday(activeSession.startedAt) else {
            return completedSeconds
        }
        let plannedSeconds = TimeInterval(activeSession.draft.plannedMinutes * 60)
        let activeSeconds = max(0, plannedSeconds - self.remainingTime)
        return completedSeconds + activeSeconds
    }

    private var actionTitle: String {
        self.activeSession == nil ? "CREATE NEW SESSION" : "BACK TO SESSION"
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TODAY")
                            .font(.caption.weight(.medium))
                            .tracking(1.6)
                            .foregroundStyle(Color.qyubeAccent)
                        Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                            .font(.headline)
                            .foregroundStyle(Color.qyubeMenuInk)
                    }

                    TodayGoalSummary(focusedSeconds: self.focusedSeconds)

                    if let breakRemaining {
                        Text(breakRemaining > 0
                             ? "Break · \(QyubeFormat.countdown(breakRemaining)) remaining"
                             : "Break finished · choose Repeat or Done in the break panel")
                            .font(.callout.weight(.medium))
                            .foregroundStyle(Color.qyubeAccent)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .qyubeInkSurface(fill: .qyubeSelection.opacity(0.5))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("SESSIONS")
                                .font(.caption.weight(.medium))
                                .tracking(1.4)
                                .foregroundStyle(Color.qyubeAccent)
                            Spacer()
                            Text("\(self.todaySessions.count + (self.activeSession == nil ? 0 : 1))")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        if let activeSession {
                            TodaySessionRow(
                                title: activeSession.draft.displayTitle,
                                detail: QyubeFormat.duration(
                                    max(0, TimeInterval(activeSession.draft.plannedMinutes * 60) - self.remainingTime)),
                                status: activeSession.status)
                        }

                        ForEach(self.todaySessions) { session in
                            Button { self.onSelectSession(session) } label: {
                                TodaySessionRow(
                                    title: session.taskTitle.isEmpty ? "Focus session" : session.taskTitle,
                                    detail: self.sessionDetail(for: session),
                                    status: session.status)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Open session details")
                        }

                        if self.todaySessions.isEmpty && self.activeSession == nil {
                            ContentUnavailableView(
                                "No sessions yet",
                                systemImage: "water.waves",
                                description: Text("Your focus sessions will appear here."))
                                .padding(.vertical, 14)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .qyubeHideNativeScrollers()
            }
            .scrollIndicators(.hidden)

            Button(action: self.activeSession == nil ? self.onCreateSession : self.onBackToSession) {
                Text(self.actionTitle)
                    .font(.headline)
                    .tracking(1.2)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .foregroundStyle(.white)
                    .background(Color.qyubeMenuInk)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
            .accessibilityHint(self.activeSession == nil
                ? "Opens the new session form"
                : "Returns to the active focus session")
            .overlay(alignment: .top) {
                QyubeInkDivider().frame(height: 3)
            }
        }
        .foregroundStyle(Color.qyubeMenuInk)
        .background(Color.qyubeBackground)
        .environment(\.colorScheme, .light)
    }

    private func sessionDetail(for session: FocusSession) -> String {
        let duration = QyubeFormat.duration(session.actualActiveSeconds)
        let endTime = session.endedAt.formatted(date: .omitted, time: .shortened)
        return "\(duration) · \(endTime)"
    }
}

#Preview("Today · compact") {
    let today = Calendar.current.startOfDay(for: .now)
    TodayView(
        sessions: [
            FocusSession(
                accountID: "preview",
                startedAt: today.addingTimeInterval(9 * 60 * 60),
                endedAt: today.addingTimeInterval(9 * 60 * 60 + 25 * 60),
                plannedMinutes: 25,
                actualActiveSeconds: 1_500,
                status: .completed,
                draftSnapshot: SessionDraft(taskTitle: "Review design notes", plannedMinutes: 25),
                taskTitle: "Review design notes"),
            FocusSession(
                accountID: "preview",
                startedAt: today.addingTimeInterval(11 * 60 * 60),
                endedAt: today.addingTimeInterval(11 * 60 * 60 + 20 * 60),
                plannedMinutes: 25,
                actualActiveSeconds: 1_200,
                status: .interrupted,
                draftSnapshot: SessionDraft(taskTitle: "Prepare the weekly project update", plannedMinutes: 25),
                taskTitle: "Prepare the weekly project update"),
        ],
        activeSession: nil,
        remainingTime: 0,
        breakRemaining: nil,
        onCreateSession: {},
        onBackToSession: {},
        onSelectSession: { _ in })
        .frame(width: 310, height: 510)
}
