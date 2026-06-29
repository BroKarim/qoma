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
    // Hitung tinggi berdasarkan jumlah item, dengan batas min & max
            let store = AnalyticsStore.shared
            let items = store.loadTodoItems()
            let pendingCount = items.filter { !$0.isCompleted }.count

            let rowHeight: CGFloat = 36
            let topBarHeight: CGFloat = 34    // topBar
            let divider1: CGFloat = 1
            let addFieldHeight: CGFloat = 37  // addField
            let divider2: CGFloat = 1
            let padding: CGFloat = 8

            let visibleRows = max(1, min(5, pendingCount))  // minimal 1, maksimal 5
            let listHeight = CGFloat(visibleRows) * rowHeight + padding

            let totalHeight = topBarHeight + divider1 + addFieldHeight + divider2 + listHeight

            return CGSize(
                width: AppConstants.ExtensionSettings.extendedWidth,
                height: max(AppConstants.ExtensionSettings.expandedStateMinHeight, totalHeight)
            )
    }

    func collapsedView(
        theme: FloatingTheme,
        onTap: @escaping () -> Void
    ) -> AnyView {
        AnyView(TodolistExtensionCollapsedView(theme: theme, onTap: onTap))
    }

    func expandedView(
        theme: FloatingTheme,
        onCollapse: @escaping () -> Void,
        onFocusChange: @escaping (Bool) -> Void
    ) -> AnyView {
        AnyView(TodolistExtensionExpandedView(
            theme: theme,
            onCollapse: onCollapse,
            onFocusChange: onFocusChange
        ))
    }

    func analyticsSection(selectedDay: Date) -> AnyView? {
        AnyView(TodolistAnalyticsSection(selectedDay: selectedDay))
    }
}

private struct TodolistExtensionCollapsedView: View {
    @ObservedObject private var todoStore = TodoStore.shared
    let theme: FloatingTheme
    let onTap: () -> Void

    @Environment(\.shouldStartDraft) private var shouldStartDraft

    var body: some View {
        TodolistCompactBar(
            todoItems: $todoStore.items,
            onAdd: {
                shouldStartDraft.wrappedValue = true
                onTap()
            },
            onShowCompleted: {},
            theme: theme,
            onTap: onTap
        )
    }
}

private struct TodolistExtensionExpandedView: View {
    @ObservedObject private var todoStore = TodoStore.shared
    let theme: FloatingTheme
    let onCollapse: () -> Void
    let onFocusChange: (Bool) -> Void

    var body: some View {
        TodolistFullView(
            todoItems: $todoStore.items,
            onAdd: {},
            theme: theme,
            onCollapse: onCollapse,
            onFocusChange: onFocusChange
        )
    }
}

private struct TodolistAnalyticsSection: View {
    @ObservedObject private var todoStore = TodoStore.shared
    let selectedDay: Date

    var body: some View {
        let items = todoStore.items
        let doneToday = items.filter { $0.isCompleted(on: selectedDay) }
        let totalToday = items.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: selectedDay) }

        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeading(
                    title: "Todolist",
                    subtitle: "Task completion and focus time by task for today.")

                if totalToday.isEmpty {
                    Text("No tasks created on this day.")
                        .font(.qomaSubheadline)
                        .foregroundColor(.secondary)
                } else {
                    HStack(spacing: 16) {
                        OverviewStatCard(
                            title: "Completion",
                            value: "\(totalToday.isEmpty ? 0 : Int(min(1.0, Double(doneToday.count) / Double(totalToday.count)) * 100))%",
                            icon: "checkmark.circle.fill",
                            color: .green)

                        OverviewStatCard(
                            title: "Done Today",
                            value: "\(doneToday.count)",
                            icon: "calendar.badge.checkmark",
                            color: .blue)

                        OverviewStatCard(
                            title: "Pending",
                            value: "\(totalToday.filter { !$0.isCompleted }.count)",
                            icon: "circle",
                            color: .orange)

                        OverviewStatCard(
                            title: "Total Tasks",
                            value: "\(totalToday.count)",
                            icon: "list.bullet",
                            color: .purple)
                    }

                    if !doneToday.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Completed Today")
                                .font(.qoma(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)

                            let sorted = doneToday.sorted(by: {
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
