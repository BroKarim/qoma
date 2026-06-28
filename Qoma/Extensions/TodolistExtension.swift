import SwiftUI

struct TodolistExtension: FeatureExtension {
    let id = "todolist"
    let title = "Todolist"
    let description = "Checklist inside the floating timer. Add, complete, and reorder tasks during focus sessions."
    let systemImage = "checklist"
    let settingsKey = AppConstants.ExtensionSettings.todolistEnabledKey
    let defaultValue = AppConstants.ExtensionSettings.defaultTodolistEnabled

    func collapsedSize() -> CGSize {
        CGSize(
            width: AppConstants.ExtensionSettings.extendedWidth,
            height: AppConstants.ExtensionSettings.collapsedStateHeight)
    }

    func expandedSize() -> CGSize {
        CGSize(
            width: AppConstants.ExtensionSettings.extendedWidth,
            height: AppConstants.ExtensionSettings.expandedStateMinHeight)
    }

    func collapsedView(
        theme: FloatingTheme,
        onTap: @escaping () -> Void
    ) -> AnyView {
        AnyView(TodolistExtensionCollapsedView(theme: theme, onTap: onTap))
    }

    func expandedView(theme: FloatingTheme) -> AnyView {
        AnyView(TodolistExtensionExpandedView(theme: theme))
    }

    func analyticsSection() -> AnyView? {
        AnyView(TodolistAnalyticsSection())
    }
}

private struct TodolistExtensionCollapsedView: View {
    @State private var todoItems: [TodoItem] = []
    let theme: FloatingTheme
    let onTap: () -> Void

    private let store = AnalyticsStore.shared

    var body: some View {
        TodolistCompactBar(
            todoItems: $todoItems,
            onAdd: {},
            onShowCompleted: {},
            theme: theme,
            onTap: onTap
        )
        .onAppear {
            todoItems = store.loadTodoItems()
        }
    }
}

private struct TodolistExtensionExpandedView: View {
    @State private var todoItems: [TodoItem] = []
    let theme: FloatingTheme

    private let store = AnalyticsStore.shared

    var body: some View {
        TodolistFullView(
            todoItems: $todoItems,
            onAdd: {},
            theme: theme
        )
        .onAppear {
            todoItems = store.loadTodoItems()
        }
    }
}

private struct TodolistAnalyticsSection: View {
    var body: some View {
        let todoItems = AnalyticsStore.shared.loadTodoItems()
        let completedToday = todoItems.filter { $0.isCompletedToday }
        let pending = todoItems.filter { !$0.isCompleted }
        let completionRate: Double = todoItems.isEmpty
            ? 0
            : Double(todoItems.filter(\.isCompleted).count) / Double(todoItems.count)

        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeading(
                    title: "Todolist",
                    subtitle: "Task completion and focus time by task for today.")

                if todoItems.isEmpty {
                    Text("No tasks yet. Add tasks from the floating timer panel.")
                        .font(.qomaSubheadline)
                        .foregroundColor(.secondary)
                } else {
                    HStack(spacing: 16) {
                        OverviewStatCard(
                            title: "Completion",
                            value: "\\(Int(completionRate * 100))%",
                            icon: "checkmark.circle.fill",
                            color: .green)

                        OverviewStatCard(
                            title: "Done Today",
                            value: "\\(completedToday.count)",
                            icon: "calendar.badge.checkmark",
                            color: .blue)

                        OverviewStatCard(
                            title: "Pending",
                            value: "\\(pending.count)",
                            icon: "circle",
                            color: .orange)

                        OverviewStatCard(
                            title: "Total Tasks",
                            value: "\\(todoItems.count)",
                            icon: "list.bullet",
                            color: .purple)
                    }

                    if !completedToday.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Completed Today")
                                .font(.qoma(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)

                            let sorted = completedToday.sorted(by: {
                                ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast)
                            })
                            ForEach(sorted) { item in
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                    Text(item.title)
                                        .font(.qoma(size: 13, weight: .regular))
                                        .foregroundColor(.primary)
                                        .strikethrough()
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
        }
    }
}
