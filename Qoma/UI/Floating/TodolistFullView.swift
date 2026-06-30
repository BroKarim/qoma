import SwiftUI

struct TodolistFullView: View {
    @ObservedObject private var timer = FocusSessionManager.shared.timerService

    @Binding var todoItems: [TodoItem]
    let onAdd: () -> Void
    let theme: FloatingTheme
    let onCollapse: () -> Void
    let onFocusChange: (Bool) -> Void

    @State private var showingCompleted: Bool = false
    @State private var editingBackup: String?
    @State private var draftItemID: UUID?
    @State private var lastFocusedID: UUID?
    @State private var pendingExit: Set<UUID> = []
    @FocusState private var focusedField: UUID?

    @Environment(\.shouldStartDraft) private var shouldStartDraft

    private let store = AnalyticsStore.shared

    var body: some View {
        VStack(spacing: 0) {
            topBar

            Divider()
                .background(theme.borderColor)

            checklist
        }
        .onChange(of: focusedField) { newValue in
            if let prev = lastFocusedID, newValue == nil {
                if editingBackup != nil {
                    commitEdit(id: prev)
                }
                lastFocusedID = nil
            } else if let id = newValue {
                lastFocusedID = id
            }
            onFocusChange(isEngaged)
        }
        .onAppear {
            if shouldStartDraft.wrappedValue {
                shouldStartDraft.wrappedValue = false
                startNewDraft()
            }
        }
    }

    private var isEngaged: Bool {
        focusedField != nil
    }

   private var topBar: some View {
    HStack(spacing: 6) {
        // Icons rata KIRI
        Button(action: startNewDraft) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(theme.textColor.opacity(0.7))
        }
        .buttonStyle(.plain)

        Button(action: { showingCompleted.toggle() }) {
            Image(systemName: showingCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                .font(.system(size: 16))
                .foregroundColor(
                    showingCompleted ? .green : theme.textColor.opacity(0.7)
                )
        }
        .buttonStyle(.plain)

        Spacer()

        // Timer rata KANAN
        Text(format(timer.remainingTime))
            .font(.custom("RobotoMono-VariableFont_wght", size: 20))
            .foregroundColor(theme.textColor)
            .baselineOffset(-2)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .contentShape(Rectangle())
    .onTapGesture {
        onCollapse()
    }
}

    private var checklist: some View {
        let visibleItems = showingCompleted
            ? todoItems.filter { $0.isCompleted && $0.isCompletedToday && !pendingExit.contains($0.id) }
            : todoItems.filter { !$0.isCompleted || pendingExit.contains($0.id) }

        return ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 2) {
                if visibleItems.isEmpty {
                    emptyMessage
                } else {
                    ForEach(visibleItems, id: \.id) { item in
                        todoRow(item)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .frame(maxHeight: maxListHeight(visibleItems.count))
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: todoItems.map(\.id))
    }

    private var emptyMessage: some View {
        Text(showingCompleted ? "No tasks completed today." : "No tasks. Tap + to add one.")
            .font(.qoma(size: 12, weight: .regular))
            .foregroundColor(theme.secondaryTextColor)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
    }



    private func todoRow(_ item: TodoItem) -> some View {
            return HStack(spacing: 8) {
                Button(action: { toggleComplete(item) }) {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 15))
                        .foregroundColor(item.isCompleted ? .green : theme.secondaryTextColor)
                        .animation(.easeInOut(duration: 0.2), value: item.isCompleted)
                }
                .buttonStyle(.plain)

                ZStack(alignment: .leading) {
                    if focusedField != item.id {
                        Text(item.title.isEmpty ? " " : item.title)
                            .font(.qoma(size: 13, weight: .medium))
                            .foregroundColor(
                                item.isCompleted
                                    ? theme.secondaryTextColor.opacity(0.5)
                                    : theme.textColor
                            )
                            .strikethrough(item.isCompleted)
                            .lineLimit(2)
                            .animation(.easeInOut(duration: 0.2), value: item.isCompleted)
                    }

                    TextField("", text: bindingForTitle(item))
                        .textFieldStyle(.plain)
                        .font(.qoma(size: 13, weight: .medium))
                        .foregroundColor(theme.textColor)
                        .focused($focusedField, equals: item.id)
                        .onSubmit { commitEdit() }
                        .onExitCommand { cancelEdit() }
                        .opacity(focusedField == item.id ? 1 : 0)
                }

                Spacer()

                if focusedField != item.id && !item.isCompleted {
                    Button(action: { moveItemUp(item) }) {
                        Image(systemName: "arrow.up.circle")
                            .font(.system(size: 11))
                            .foregroundColor(theme.secondaryTextColor.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(
                        focusedField == item.id ? 0.06 : 0.03
                    ))
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if !item.isCompleted && focusedField != item.id {
                    startEdit(item)
                }
            }
            .contextMenu {
                Button("Delete") { deleteItem(item) }
            }
        }

    private func bindingForTitle(_ item: TodoItem) -> Binding<String> {
        Binding(
            get: { item.title },
            set: { newValue in
                if let index = todoItems.firstIndex(where: { $0.id == item.id }) {
                    todoItems[index].title = newValue
                }
            }
        )
    }

    private func maxListHeight(_ itemCount: Int) -> CGFloat {
        let rowHeight: CGFloat = 36
        let minHeight: CGFloat = 80
        let maxHeight: CGFloat = 360
        let calculated = CGFloat(max(1, itemCount)) * rowHeight + 8
        return min(maxHeight, max(minHeight, calculated))
    }

    private func startEdit(_ item: TodoItem) {
        guard focusedField != item.id else { return }
        editingBackup = item.title

        // ⬅ delay agar TextField sudah ada di view tree
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.focusedField = item.id
    }
}

    private func commitEdit() {
        commitEdit(id: focusedField)
    }

    private func commitEdit(id targetID: UUID?) {
        guard let id = targetID,
            let index = todoItems.firstIndex(where: { $0.id == id }) else {
            editingBackup = nil
            focusedField = nil
            return
        }
        let item = todoItems[index]
        let trimmed = item.title.trimmingCharacters(in: .whitespacesAndNewlines)

        if id == draftItemID {
            if trimmed.isEmpty {
                todoItems.remove(at: index)
            } else {
                var saved = item
                saved.title = trimmed
                todoItems[index] = saved
                store.appendTodoItem(saved)
            }
            draftItemID = nil
        } else {
            if trimmed.isEmpty {
                // ⬅ hapus jika dikosongkan
                todoItems.remove(at: index)
                store.deleteTodoItem(item)
            } else {
                var updated = item
                updated.title = trimmed
                todoItems[index] = updated
                store.updateTodoItem(updated)
            }
        }
        editingBackup = nil
        focusedField = nil
    }

    private func cancelEdit() {
        guard let id = focusedField,
              let index = todoItems.firstIndex(where: { $0.id == id }) else {
            focusedField = nil
            return
        }

        if id == draftItemID {
            todoItems.remove(at: index)
            draftItemID = nil
        } else if let backup = editingBackup {
            todoItems[index].title = backup
        }
        editingBackup = nil
        focusedField = nil
    }

    private func startNewDraft() {
            if let draftID = draftItemID,
            todoItems.contains(where: { $0.id == draftID }) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.focusedField = draftID
                }
                return
            }

            let maxOrder = todoItems.map(\.sortOrder).max() ?? 0
            let draft = TodoItem(title: "", sortOrder: maxOrder + 1)
            todoItems.append(draft)
            draftItemID = draft.id
            editingBackup = ""

            // ⬅ delay agar SwiftUI sempat render row baru dulu
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.focusedField = draft.id
            }
    }

    private func toggleComplete(_ item: TodoItem) {
        guard let index = todoItems.firstIndex(where: { $0.id == item.id }) else { return }

        var updated = item
        if !item.isCompleted {
            updated.isCompleted = true
            updated.completedAt = Date()
            todoItems[index] = updated
            store.updateTodoItem(updated)

            let id = item.id
            pendingExit.insert(id)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    _ = pendingExit.remove(id)
                }
            }
        } else {
            updated.isCompleted = false
            updated.completedAt = nil
            todoItems[index] = updated
            store.updateTodoItem(updated)
            pendingExit.remove(item.id)
        }
    }

    private func moveItemUp(_ item: TodoItem) {
        guard let index = todoItems.firstIndex(where: { $0.id == item.id }),
              todoItems.count > 1 else { return }
        let newIndex = index == 0 ? todoItems.count - 1 : index - 1

        var newItems = todoItems
        let moved = newItems.remove(at: index)
        newItems.insert(moved, at: newIndex)

        for i in newItems.indices {
            newItems[i].sortOrder = i
        }

        todoItems = newItems
        store.saveTodoItems(newItems)
    }

    private func deleteItem(_ item: TodoItem) {
        todoItems.removeAll { $0.id == item.id }
        store.deleteTodoItem(item)
    }

    private func format(_ time: TimeInterval) -> String {
        let total = max(0, Int(time.rounded(.down)))
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
