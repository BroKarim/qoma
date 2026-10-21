import Foundation
import Testing
@testable import Qoma

struct SessionRepeatDraftTests {
    @MainActor @Test func repeatUsesSavedDraftAndRejectsInvalidConfiguration() {
        var policy = SessionPolicy(mode: .allowing)
        policy.allowedApps = ["com.apple.Safari"]
        let draft = SessionDraft(taskTitle: "  Write proposal  ", plannedMinutes: 45, policy: policy)
        let session = FocusSession(
            accountID: "local", startedAt: .now, endedAt: .now,
            plannedMinutes: 45, actualActiveSeconds: 2700, status: .completed,
            draftSnapshot: draft, taskTitle: "Write proposal")

        let repeated = QyubeAppCoordinator.repeatDraft(for: session)
        #expect(repeated?.taskTitle == "Write proposal")
        #expect(repeated?.plannedMinutes == 45)
        #expect(repeated?.policy.allowedApps == ["com.apple.Safari"])

        var invalid = session
        invalid.draftSnapshot.policy.allowedApps = []
        #expect(QyubeAppCoordinator.repeatDraft(for: invalid) == nil)
        invalid.draftSnapshot.policy.allowedApps = ["com.apple.Safari"]
        invalid.draftSnapshot.taskTitle = "  "
        #expect(QyubeAppCoordinator.repeatDraft(for: invalid) == nil)
    }
}
