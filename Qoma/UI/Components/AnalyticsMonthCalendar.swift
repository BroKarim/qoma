import SwiftUI

struct AnalyticsMonthCalendar: View {
    @Binding var selectedDay: Date
    let focusByDay: [Date: Double]
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)

    private var month: Date {
        calendar.dateInterval(of: .month, for: selectedDay)?.start ?? selectedDay
    }

    private var leadingDays: Int {
        (calendar.component(.weekday, from: month) - calendar.firstWeekday + 7) % 7
    }

    private var dayCount: Int { calendar.range(of: .day, in: .month, for: month)?.count ?? 0 }

    var body: some View {
        VStack(spacing: 13) {
            HStack(spacing: 5) {
                Text(month.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 17, weight: .medium, design: .serif))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Previous month", systemImage: "chevron.left") { moveMonth(-1) }
                    .labelStyle(.iconOnly)
                    .frame(width: 26, height: 26)
                Button("Next month", systemImage: "chevron.right") { moveMonth(1) }
                    .labelStyle(.iconOnly)
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.qyubeAccent)
            .controlSize(.small)

            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(0..<7, id: \.self) { index in
                    let weekday = (calendar.firstWeekday - 1 + index) % 7
                    Text(calendar.veryShortStandaloneWeekdaySymbols[weekday])
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 3)
                        .accessibilityHidden(true)
                }
                ForEach(0..<((leadingDays + dayCount + 6) / 7 * 7), id: \.self) { index in
                    if index >= leadingDays, index < leadingDays + dayCount,
                       let day = calendar.date(byAdding: .day, value: index - leadingDays, to: month) {
                        dayButton(day)
                    } else {
                        Color.clear.frame(height: 44).accessibilityHidden(true)
                    }
                }
            }

            HStack {
                Label("Focus time per day", systemImage: "clock")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 4)
                Button("Today") { selectedDay = calendar.startOfDay(for: Date()) }
                    .font(.system(size: 10, weight: .semibold))
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.qyubeAccent)
            }
        }
        .padding(11)
        .qyubeInkSurface(fill: .white.opacity(0.7), stroke: Color.qyubeAccent.opacity(0.35), lineWidth: 0.8)
    }

    private func dayButton(_ day: Date) -> some View {
        let selected = calendar.isDate(day, inSameDayAs: selectedDay)
        let seconds = focusByDay[calendar.startOfDay(for: day), default: 0]
        return Button {
            selectedDay = day
        } label: {
            VStack(spacing: 4) {
                Text(day.formatted(.dateTime.day()))
                    .font(.system(size: 12, weight: selected ? .bold : .medium))
                Text(Self.focusLabel(seconds))
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .opacity(seconds > 0 || selected ? 1 : 0.45)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(selected ? Color.white : Color.qyubeMenuInk)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background {
                RoundedRectangle(cornerRadius: 7)
                    .fill(selected ? Color.qyubeAccent : Color.clear)
            }
            .overlay {
                if calendar.isDateInToday(day) {
                    RoundedRectangle(cornerRadius: 7)
                        .strokeBorder(selected ? Color.white.opacity(0.7) : Color.qyubeAccent, lineWidth: 1)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
        .accessibilityValue("\(QyubeFormat.duration(seconds)) focus\(calendar.isDateInToday(day) ? ", today" : "")")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    static func focusLabel(_ seconds: Double) -> String {
        let minutes = max(0, Int(seconds / 60))
        return minutes < 60 ? "\(minutes)m" : String(format: "%d:%02d", minutes / 60, minutes % 60)
    }

    private func moveMonth(_ offset: Int) {
        guard let next = calendar.date(byAdding: .month, value: offset, to: month),
              let days = calendar.range(of: .day, in: .month, for: next),
              let date = calendar.date(
                byAdding: .day,
                value: min(calendar.component(.day, from: selectedDay), days.count) - 1,
                to: next) else { return }
        selectedDay = date
    }
}
