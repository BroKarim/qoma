import SwiftUI

struct QyubeJournalSettingsView: View {
    @ObservedObject private var focus = FocusPreferences.shared
    @AppStorage("qyube.coveAtmosphere") private var atmosphere = "Auto"

    @State private var confirmErase = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
          VStack(alignment: .leading, spacing: 16) {
            Text("Settings").font(.title2)
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Show floating timer", isOn: Binding(
                    get: { !focus.hideFloatingTimer },
                    set: { focus.hideFloatingTimer = !$0 }))
                Picker("Cove atmosphere", selection: $atmosphere) {
                    ForEach(["Auto", "Morning", "Sunset", "Night"], id: \.self) { Text($0) }
                }
                Text("Auto follows the time on this Mac.").font(.caption).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 12) {
                Button("Check for Updates") { UpdaterManager.shared.checkForUpdates() }
                SettingsSidebarFooter()
                Button("Erase local data", role: .destructive) { confirmErase = true }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red).font(.caption) }
            }
        }
          .padding(16)
          .alert("Erase local data?", isPresented: $confirmErase) {
              Button("Cancel", role: .cancel) {}
              Button("Erase", role: .destructive) { erase() }
          } message: {
              Text("Permanently erase this account’s session history, catches and activity on this Mac. Purchases, account and trial are kept. Stop any active session first. Archived backups are not removed.")
          }
        }
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
