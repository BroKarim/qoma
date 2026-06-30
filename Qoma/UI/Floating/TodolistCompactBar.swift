import SwiftUI

struct TodolistCompactBar: View {
    @ObservedObject private var timer = FocusSessionManager.shared.timerService

    @Binding var todoItems: [TodoItem]
    let onAdd: () -> Void
    let onShowCompleted: () -> Void
    let theme: FloatingTheme
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            topRow

            if let first = todoItems.first(where: { !$0.isCompleted }) {
                compactItemView(first)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
            } else if let first = todoItems.first {
                compactItemView(first)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }

    private var topRow: some View {
        HStack(spacing: 6) {

            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(theme.textColor.opacity(0.7))
            }
            .buttonStyle(.plain)

            Button(action: onShowCompleted) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(theme.textColor.opacity(0.7))
            }
            .buttonStyle(.plain)

            Spacer()

        // Timer rata KANAN
            Text(format(timer.remainingTime))
            .font(.custom("RobotoMono-VariableFont_wght", size: 20))  // ⬅ dari 22 → 20
            .foregroundColor(theme.textColor)
            .baselineOffset(-2)  // ⬅ dari -3 → -2
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func compactItemView(_ item: TodoItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(item.isCompleted ? .green : theme.secondaryTextColor)

            Text(item.title)
                .font(.qoma(size: 13, weight: .medium))
                .foregroundColor(
                    item.isCompleted ? theme.secondaryTextColor.opacity(0.5) : theme.textColor
                )
                .strikethrough(item.isCompleted)
                .lineLimit(1)

            Spacer()
        }
    }

    private func format(_ time: TimeInterval) -> String {
        let total = max(0, Int(time.rounded(.down)))
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
