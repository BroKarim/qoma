import SwiftUI
import Combine

@MainActor
final class QyubeNavigation: ObservableObject {
  enum Page: Equatable { case home, newSession, catalog, insight, settings, report }
  @Published var page: Page = .home
  @Published var draft = SessionDraft()
  @Published var report: FocusSession?
  @Published private(set) var history: [FocusSession] = []
  @Published private(set) var catches: [CatchEvent] = []

  func refresh() {
    history = SessionRepository.shared.loadHistory(accountID: "local").sorted {
      $0.startedAt > $1.startedAt
    }
    catches = CatchRepository.shared.listBanked(accountID: "local").sorted {
      $0.depositedAt > $1.depositedAt
    }
  }

  func showReport(_ session: FocusSession) {
    refresh()
    report = session
    page = .report
  }

  func repeatSession(_ session: FocusSession) {
    draft = session.draftSnapshot
    draft.taskTitle = session.taskTitle
    page = .newSession
  }
}

struct QyubeHomeView: View {
  @ObservedObject var sessionCoordinator: SessionCoordinator
  @ObservedObject var navigation: QyubeNavigation
  let onClose: () -> Void
  let onShowTimer: () -> Void
  let onStarted: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      header
      if navigation.page != .home {
        HStack {
          Button {
            navigation.page = .home
          } label: {
            Label("Back", systemImage: "arrow.left")
          }
          .buttonStyle(.plain).help("Back to Home")
          Spacer()
        }.font(.system(size: 12)).padding(.horizontal, 22).padding(.bottom, 12)
      }
      content.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    .foregroundStyle(Color.qyubeInk).background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.qyubeLine, lineWidth: 1))
    .environment(\.colorScheme, .light).tint(.qyubeInk)
    .scrollIndicators(.never)
    .onAppear { navigation.refresh() }
    .onChange(of: sessionCoordinator.snapshot?.id) { navigation.refresh() }
    .onChange(of: sessionCoordinator.lastCatchEvent?.id) { navigation.refresh() }
  }

  private var header: some View {
    HStack(spacing: 12) {
      icon("xmark", label: "Close main window", action: onClose)
      Text("qyube").font(.system(size: 20, weight: .medium, design: .rounded))
      Spacer(minLength: 8)
      icon("chart.bar", label: "Insight", selected: navigation.page == .insight) {
        navigation.refresh()
        navigation.page = .insight
      }
      icon("archivebox", label: "Catalog", selected: navigation.page == .catalog) {
        navigation.refresh()
        navigation.page = .catalog
      }
      Menu {
        Button("Settings", systemImage: "gearshape") { navigation.page = .settings }
        Divider()
        Button("Manage subscription") {}.disabled(true)
        Button("Sign out") {}.disabled(true)
        Divider()
        Button("Quit qyube") { NSApp.terminate(nil) }.keyboardShortcut("q")
      } label: {
        Image(systemName: "gearshape").font(.system(size: 17)).frame(width: 26, height: 30)
      }.menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
        .help("Settings and account").accessibilityLabel("Settings and account")
    }.padding(.horizontal, 18).frame(height: 58).background(WindowDragArea())
  }

  private func icon(
    _ symbol: String, label: String, selected: Bool = false, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Image(systemName: symbol).font(.system(size: 17)).frame(width: 26, height: 30)
        .background(selected ? Color.qyubeSelection : .clear, in: RoundedRectangle(cornerRadius: 6))
    }.buttonStyle(.plain).help(label).accessibilityLabel(label)
  }

  @ViewBuilder private var content: some View {
    switch navigation.page {
    case .home:
      CompactTodayView(
        coordinator: sessionCoordinator, history: navigation.history,
        onReport: navigation.showReport,
        onAction: {
          if sessionCoordinator.snapshot != nil {
            onShowTimer()
          } else {
            navigation.page = .newSession
          }
        })
    case .newSession:
      NewSessionView(
        coordinator: sessionCoordinator, draft: $navigation.draft,
        onStarted: {
          navigation.page = .home
          onStarted()
        })
    case .catalog: CatalogView(catches: navigation.catches)
    case .insight: InsightView(history: navigation.history, catches: navigation.catches)
    case .settings: QyubeCompactSettingsView()
    case .report:
      if let session = navigation.report {
        FishingReportView(
          session: session,
          catches: navigation.catches.filter { $0.sessionID == session.id },
          hasActiveSession: sessionCoordinator.snapshot != nil,
          onStartAgain: {
            if sessionCoordinator.snapshot != nil { onShowTimer() }
            else { navigation.repeatSession(session) }
          },
          onGoHome: { navigation.page = .home })
      }
    }
  }
}

private struct CompactTodayView: View {
  @ObservedObject var coordinator: SessionCoordinator
  let history: [FocusSession]
  let onReport: (FocusSession) -> Void
  let onAction: () -> Void

  private var today: [FocusSession] {
    history.filter { Calendar.current.isDateInToday($0.startedAt) }
  }
  private var focusSeconds: TimeInterval {
    let saved = today.reduce(0) { $0 + $1.actualActiveSeconds }
    guard let snapshot = coordinator.snapshot, Calendar.current.isDateInToday(snapshot.startedAt),
      !today.contains(where: { $0.id == snapshot.id })
    else { return saved }
    return saved + max(0, Double(snapshot.draft.plannedMinutes * 60) - coordinator.remainingTime)
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 0) {
        VStack(alignment: .leading, spacing: 10) {
          Text("Today").font(.system(size: 17))
          Text(QyubeFormat.duration(focusSeconds))
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .minimumScaleFactor(0.65).lineLimit(1).monospacedDigit()
          Text("Focused today").font(.system(size: 12)).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading)
        QyubePenguinArt().frame(width: 155, height: 160)
      }.padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 22)
      ScrollView {
        LazyVStack(spacing: 20) {
          if let snapshot = coordinator.snapshot {
            Button(action: onAction) {
              HStack(alignment: .top, spacing: 10) {
                Image(systemName: coordinator.isPaused ? "pause.circle" : "timer")
                VStack(alignment: .leading, spacing: 5) {
                  Text(snapshot.draft.displayTitle).lineLimit(2)
                  Text(coordinator.isPaused ? "Paused" : "In progress")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer()
                Text(QyubeFormat.countdown(coordinator.remainingTime)).monospacedDigit()
              }.font(.system(size: 13)).padding(12)
                .background(Color.qyubeSelection, in: RoundedRectangle(cornerRadius: 9))
            }.buttonStyle(.plain)
          }
          ForEach(today) { session in
            Button {
              onReport(session)
            } label: {
              HStack(alignment: .top, spacing: 12) {
                Image(systemName: session.status == .completed ? "checkmark" : "circle")
                  .frame(width: 16)
                VStack(alignment: .leading, spacing: 5) {
                  Text(session.taskTitle.isEmpty ? "Focus session" : session.taskTitle).lineLimit(2)
                  Text(
                    "\(session.startedAt.formatted(date: .omitted, time: .shortened)) · \(session.status.rawValue.capitalized)"
                  )
                  .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Text(QyubeFormat.duration(session.actualActiveSeconds)).font(.system(size: 13))
              }.font(.system(size: 14)).frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }.buttonStyle(.plain)
          }
          if today.isEmpty && coordinator.snapshot == nil {
            VStack(spacing: 8) {
              Text("A little focus. A new discovery.").font(.system(size: 13))
              Text("Your sessions will appear here.").font(.system(size: 11)).foregroundStyle(
                .secondary)
            }.frame(maxWidth: .infinity).padding(.top, 38)
          }
        }.padding(.horizontal, 22).padding(.vertical, 4)
      }
      QyubePrimaryButton(
        title: coordinator.snapshot == nil ? "New session" : "Show timer", action: onAction
      ).padding(22)
    }
  }
}

extension Color {
  static let qyubeBackground = Color.white
  static let qyubeSidebar = Color(white: 0.98)
  static let qyubeCardBackground = Color.white
  static let qyubeInk = Color(white: 0.13)
  static let qyubeLine = Color(white: 0.88)
  static let qyubeSelection = Color(white: 0.95)
  static let qyubeAccent = Color(red: 0.76, green: 0.42, blue: 0.32)
}
