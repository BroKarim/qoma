import SwiftUI

struct TodolistFullView: View {
    @ObservedObject private var timer = FocusSessionManager.shared.timerService

    @Binding var todoItems: [TodoItem]
    let onAdd: () -> Void
    let theme: FloatingTheme

    @State private var newItemText: String = ""
    @State private var showingCompleted: Bool = false

    private let store = AnalyticsStore.shared

    var body: some View {
        VStack(spacing: 0) {
            topBar

            Divider()
                .background(theme.borderColor)

            addField

            Divider()
                .background(theme.borderColor)

            checklist
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Spacer()

            Text(format(timer.remainingTime))
                .font(.custom("RobotoMono-VariableFont_wght", size: 22))
                .foregroundColor(theme.textColor)
                .baselineOffset(-3)

            Spacer()

            Button(action: { clearCompleted() }, label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(theme.textColor.opacity(0.7))
            })
            .buttonStyle(.plain)

            Button(action: { showingCompleted.toggle() }, label: {
                Image(systemName: showingCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.system(size: 18))
                    .foregroundColor(
                        showingCompleted
                            ? .green
                            : theme.textColor.opacity(0.7)
                    )
            })
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var addField: some View {
        HStack(spacing: 8) {
            TextField("Add a task...", text: $newItemText)
                .textFieldStyle(.plain)
                .font(.qoma(size: 13, weight: .regular))
                .foregroundColor(theme.textColor)

            if !newItemText.isEmpty {
                Button(action: addItem) {
                    Text("Add")
                        .font(.qoma(size: 12, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var checklist: some View {
        let visibleItems = showingCompleted
            ? todoItems.filter { $0.isCompleted && $0.isCompletedToday }
            : todoItems.filter { !$0.isCompleted }

        return ScrollView(showsIndicators: true) {
            LazyVStack(spacing: 2) {
                if visibleItems.isEmpty {
                    emptyMessage
                } else {
                    ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                        todoRow(item, at: index)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .frame(maxHeight: maxListHeight(visibleItems.count))
    }

    private var emptyMessage: some View {
        Text(showingCompleted ? "No tasks completed today." : "No tasks. Tap + to add one.")
            .font(.qoma(size: 12, weight: .regular))
            .foregroundColor(theme.secondaryTextColor)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
    }

    private func todoRow(_ item: TodoItem, at index: Int) -> some View {
        HStack(spacing: 8) {
            Button(action: { toggleComplete(item) }, label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15))
                    .foregroundColor(item.isCompleted ? .green : theme.secondaryTextColor)
            })
            .buttonStyle(.plain)

            Text(item.title)
                .font(.qoma(size: 13, weight: .medium))
                .foregroundColor(
                    item.isCompleted ? theme.secondaryTextColor.opacity(0.5) : theme.textColor
                )
                .strikethrough(item.isCompleted)
                .lineLimit(2)

            Spacer()

            if !item.isCompleted {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 11))
                    .foregroundColor(theme.secondaryTextColor.opacity(0.4))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.03))
        )
        .contextMenu {
            Button("Delete") {
                deleteItem(item)
            }
        }
    }

    private func maxListHeight(_ itemCount: Int) -> CGFloat {
        let rowHeight: CGFloat = 36
        let minHeight: CGFloat = 80
        let maxHeight: CGFloat = 360
        let calculated = CGFloat(max(1, itemCount)) * rowHeight + 8
        return min(maxHeight, max(minHeight, calculated))
    }

    private func addItem() {
        let trimmed = newItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let maxOrder = todoItems.map(\.sortOrder).max() ?? 0
        let item = TodoItem(
            title: trimmed,
            sortOrder: maxOrder + 1
        )

        todoItems.append(item)
        store.appendTodoItem(item)
        newItemText = ""
    }

    private func toggleComplete(_ item: TodoItem) {
        guard let index = todoItems.firstIndex(where: { $0.id == item.id }) else { return }

        var updated = item
        updated.isCompleted.toggle()
        updated.completedAt = updated.isCompleted ? Date() : nil
        todoItems[index] = updated
        store.updateTodoItem(updated)
    }

    private func deleteItem(_ item: TodoItem) {
        todoItems.removeAll { $0.id == item.id }
        store.deleteTodoItem(item)
    }

    private func clearCompleted() {
        let completed = todoItems.filter { $0.isCompleted }
        for item in completed {
            store.deleteTodoItem(item)
        }
        todoItems.removeAll { $0.isCompleted }
    }

    private func format(_ time: TimeInterval) -> String {
        let total = max(0, Int(time.rounded(.down)))
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
