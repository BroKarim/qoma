import Foundation

struct TodoItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    var notes: String
    var sortOrder: Int
    var sessionID: UUID?

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        notes: String = "",
        sortOrder: Int = 0,
        sessionID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.notes = notes
        self.sortOrder = sortOrder
        self.sessionID = sessionID
    }

    var isCompletedToday: Bool {
        guard isCompleted, let completedAt else { return false }
        return Calendar.current.isDate(completedAt, inSameDayAs: Date())
    }
}
