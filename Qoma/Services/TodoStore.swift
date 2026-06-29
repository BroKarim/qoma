import Combine
import Foundation

@MainActor
final class TodoStore: ObservableObject {
    static let shared = TodoStore()

    @Published var items: [TodoItem] = []

    private init() {
        items = AnalyticsStore.shared.loadTodoItems()
    }
}
