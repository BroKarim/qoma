import Foundation
import Testing
@testable import Qoma

@MainActor
struct CoveBucketTests {
    @Test func sessionQueryIncludesProvisionalAndBankedAndIsolatesAccounts() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = CatchRepository(storageDirectory: directory)
        let session = UUID()
        let first = CatchEvent(sessionID: session, accountID: "a", kindID: "shell", depositedAt: .now)
        let second = CatchEvent(sessionID: session, accountID: "a", kindID: "shell", depositedAt: .now)
        let otherAccount = CatchEvent(sessionID: session, accountID: "b", kindID: "shell", depositedAt: .now)
        let otherSession = CatchEvent(sessionID: UUID(), accountID: "a", kindID: "shell", depositedAt: .now)
        for event in [first, second, otherAccount, otherSession] {
            #expect(repository.saveProvisional(event))
        }
        #expect(repository.bank(first.id, sessionID: session, accountID: "a", at: .now))
        let events = repository.listSession(sessionID: session, accountID: "a")
        #expect(Set(events.map(\.id)) == [first.id, second.id])
        #expect(events.filter(\.isBanked).count == 1)
    }
}
