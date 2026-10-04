import SwiftUI

struct InsightView: View {
  var history: [FocusSession] = []
  var catches: [CatchEvent] = []
  @State private var period = Period.day
  @State private var anchor = Date()
  @State private var expanded = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  enum Period: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
    var component: Calendar.Component {
      switch self {
      case .day: .day
      case .week: .weekOfYear
      case .month: .month
      case .year: .year
      }
    }
  }
  private var interval: DateInterval {
    Calendar.current.dateInterval(of: period.component, for: anchor)
      ?? DateInterval(start: anchor, duration: 86400)
  }
  private var sessions: [FocusSession] {
    history.filter { $0.startedAt >= interval.start && $0.startedAt < interval.end }
  }
  private var periodCatches: [CatchEvent] {
    catches.filter { $0.depositedAt >= interval.start && $0.depositedAt < interval.end }
      .sorted { $0.depositedAt > $1.depositedAt }
  }
  private var totalSeconds: TimeInterval { sessions.reduce(0) { $0 + $1.actualActiveSeconds } }
  private var grouped: [(id: String, count: Int)] {
    Dictionary(grouping: periodCatches, by: \.kindID).map { (id: $0.key, count: $0.value.count) }
      .sorted { $0.id < $1.id }
  }
  private var title: String {
    switch period {
    case .day:
      return Calendar.current.isDateInToday(anchor)
        ? "Today" : anchor.formatted(.dateTime.month(.abbreviated).day().year())
    case .week:
      return
        "\(interval.start.formatted(.dateTime.month(.abbreviated).day())) – \(interval.end.addingTimeInterval(-1).formatted(.dateTime.month(.abbreviated).day()))"
    case .month: return anchor.formatted(.dateTime.month(.wide).year())
    case .year: return anchor.formatted(.dateTime.year())
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Insight").font(.system(size: 25, weight: .semibold)).padding(.horizontal, 22)
      Picker("Period", selection: $period) {
        ForEach(Period.allCases, id: \.self) { Text($0.rawValue).tag($0) }
      }.pickerStyle(.segmented).labelsHidden().padding(.horizontal, 22)
      HStack {
        Button {
          move(-1)
        } label: {
          Image(systemName: "chevron.left")
        }
        .accessibilityLabel("Previous \(period.rawValue.lowercased())")
        Spacer()
        Button(title) { anchor = Date() }.help("Go to the current period")
        Spacer()
        Button {
          move(1)
        } label: {
          Image(systemName: "chevron.right")
        }
        .disabled(interval.end > Date()).accessibilityLabel("Next \(period.rawValue.lowercased())")
      }.buttonStyle(.plain).font(.system(size: 12)).padding(.horizontal, 24)
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          catchesSection
          Divider()
          metrics
          focusDistribution
          taskDistribution
          if !sessions.isEmpty { sessionList }
          if !grouped.isEmpty { catchSummary }
        }.padding(.horizontal, 22).padding(.vertical, 8)
      }
    }
    .onChange(of: period) { expanded = false }
    .onChange(of: anchor) { expanded = false }
  }

  private var catchesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(period == .day ? "Latest catches" : "Your catches").font(
          .system(size: 14, weight: .semibold))
        Spacer()
        Text("\(periodCatches.count)").font(.system(size: 12)).foregroundStyle(.secondary)
      }
      if periodCatches.isEmpty {
        VStack(spacing: 8) {
          QyubeCatchArt().frame(width: 70, height: 40).opacity(0.35)
          Text("No catches in this period.").font(.system(size: 11)).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity).padding(.vertical, 14)
      } else if period == .day {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 85), spacing: 10)], spacing: 10) {
          ForEach(expanded ? periodCatches : Array(periodCatches.prefix(6))) { event in
            VStack(spacing: 7) {
              QyubeCatchArt().frame(height: 38).padding(8).background(Color(white: 0.97))
              Text(CatalogDefinitions.kind(id: event.kindID)?.name ?? "Catch")
                .font(.system(size: 9)).lineLimit(1)
              Text(event.depositedAt.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 9)).foregroundStyle(.secondary)
            }.padding(6).background(.white)
              .overlay(Rectangle().stroke(Color.qyubeLine, lineWidth: 0.6))
              .accessibilityElement(children: .combine)
          }
        }
      } else {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: 7)], spacing: 7) {
          ForEach(expanded ? periodCatches : Array(periodCatches.prefix(10))) { event in
            QyubeCatchArt().frame(height: 25).padding(6).frame(maxWidth: .infinity)
              .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.qyubeLine, lineWidth: 0.7))
              .accessibilityElement(children: .ignore)
              .accessibilityLabel(
                "\(CatalogDefinitions.kind(id: event.kindID)?.name ?? "Catch"), \(event.depositedAt.formatted())")
          }
        }
      }
      if periodCatches.count > (period == .day ? 6 : 10) {
        Button {
          setExpanded(!expanded)
        } label: {
          VStack(spacing: 5) {
            Capsule().fill(Color.qyubeLine).frame(width: 28, height: 3)
            HStack(spacing: 5) {
              Text(expanded ? "Show less" : "View all")
              Image(systemName: expanded ? "chevron.up" : "chevron.down")
            }.font(.system(size: 10)).foregroundStyle(.secondary)
          }.frame(maxWidth: .infinity).padding(.vertical, 5).contentShape(Rectangle())
        }.buttonStyle(.plain)
          .simultaneousGesture(
            DragGesture(minimumDistance: 18).onEnded { value in
              if abs(value.translation.height) > 25 { setExpanded(value.translation.height > 0) }
            }
          )
          .accessibilityHint("Expand or collapse the catch collection")
      }
    }
  }

  private var metrics: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        metric(QyubeFormat.duration(totalSeconds), "Focus time")
        metric("\(sessions.filter { $0.status == .completed }.count)", "Completed")
        metric("\(sessions.filter { $0.status == .interrupted }.count)", "Interrupted")
      }
      Text(comparison).font(.system(size: 11)).foregroundStyle(.secondary)
    }
  }
  private var comparison: String {
    let previous =
      Calendar.current.date(byAdding: period.component, value: -1, to: interval.start)
      ?? interval.start
    let previousSessions = history.filter {
      $0.startedAt >= previous && $0.startedAt < interval.start
    }
    let prior = previousSessions.reduce(0) { $0 + $1.actualActiveSeconds }
    let difference = totalSeconds - prior
    let completedDifference =
      sessions.filter { $0.status == .completed }.count
      - previousSessions.filter { $0.status == .completed }.count
    return
      "\(QyubeFormat.duration(abs(difference))) \(difference < 0 ? "less" : "more") focus · \(completedDifference >= 0 ? "+" : "")\(completedDifference) completed vs. previous \(period.rawValue.lowercased())"
  }
  private var focusDistribution: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Focus time distribution").font(.system(size: 14, weight: .semibold))
      CompactFocusChart(sessions: sessions, interval: interval, period: period)
    }
  }
  private var taskDistribution: some View {
    let tasks = Dictionary(
      grouping: sessions, by: { $0.taskTitle.isEmpty ? "Focus session" : $0.taskTitle }
    )
    .map { (title: $0.key, seconds: $0.value.reduce(0) { $0 + $1.actualActiveSeconds }) }
    .sorted { $0.seconds > $1.seconds }
    return VStack(alignment: .leading, spacing: 12) {
      Text("Task distribution").font(.system(size: 14, weight: .semibold))
      if tasks.isEmpty {
        Text("Your focus time will appear here.").font(.caption).foregroundStyle(.secondary)
      }
      ForEach(tasks, id: \.title) { task in
        VStack(spacing: 6) {
          HStack {
            Text(task.title).lineLimit(2)
            Spacer()
            Text(QyubeFormat.duration(task.seconds)).foregroundStyle(.secondary)
          }.font(.system(size: 11))
          GeometryReader { geometry in
            Capsule().fill(Color.qyubeSelection)
            Capsule().fill(Color.qyubeInk).frame(
              width: geometry.size.width * task.seconds / max(1, totalSeconds))
          }.frame(height: 3)
        }
      }
    }
  }
  private var sessionList: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Sessions").font(.system(size: 14, weight: .semibold))
      ForEach(sessions) { session in
        HStack(alignment: .top) {
          Image(systemName: session.status == .completed ? "checkmark" : "circle")
          Text(session.taskTitle.isEmpty ? "Focus session" : session.taskTitle).lineLimit(2)
          Spacer()
          Text(QyubeFormat.duration(session.actualActiveSeconds)).foregroundStyle(.secondary)
        }.font(.system(size: 11)).accessibilityElement(children: .combine)
          .accessibilityLabel(
            "\(session.taskTitle), \(session.status.rawValue), \(QyubeFormat.duration(session.actualActiveSeconds))"
          )
      }
    }
  }
  private var catchSummary: some View {
    VStack(alignment: .leading, spacing: 12) {
      Divider()
      Text(period == .day ? "Today's catch summary" : "Catch summary").font(
        .system(size: 14, weight: .semibold))
      ForEach(grouped, id: \.id) { item in
        HStack {
          QyubeCatchArt().frame(width: 30, height: 20)
          Text(CatalogDefinitions.kind(id: item.id)?.name ?? "Catch")
          Spacer()
          Text("×\(item.count)").foregroundStyle(.secondary)
        }.font(.system(size: 12))
      }
    }
  }
  private func metric(_ value: String, _ label: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(value).font(.system(size: 20, weight: .semibold, design: .rounded)).minimumScaleFactor(
        0.7
      ).lineLimit(1)
      Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
    }.frame(maxWidth: .infinity, alignment: .leading)
  }
  private func move(_ value: Int) {
    anchor = Calendar.current.date(byAdding: period.component, value: value, to: anchor) ?? anchor
  }
  private func setExpanded(_ value: Bool) {
    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { expanded = value }
  }
}

private struct CompactFocusChart: View {
  let sessions: [FocusSession]
  let interval: DateInterval
  let period: InsightView.Period
  private var bucketComponent: Calendar.Component {
    period == .day ? .hour : period == .year ? .month : .day
  }
  private var buckets: [Date] {
    var result: [Date] = []
    var date = interval.start
    while date < interval.end {
      result.append(date)
      guard let next = Calendar.current.date(byAdding: bucketComponent, value: 1, to: date),
        next > date
      else { break }
      date = next
    }
    return result
  }
  private func seconds(at date: Date) -> TimeInterval {
    let end = Calendar.current.date(byAdding: bucketComponent, value: 1, to: date) ?? date
    return sessions.filter { $0.startedAt >= date && $0.startedAt < end }.reduce(0) {
      $0 + $1.actualActiveSeconds
    }
  }
  var body: some View {
    let values = buckets.map { (date: $0, seconds: seconds(at: $0)) }
    let maximum = max(1, values.map(\.seconds).max() ?? 1)
    VStack(spacing: 8) {
      HStack(alignment: .bottom, spacing: period == .month ? 3 : 5) {
        ForEach(values, id: \.date) { item in
          RoundedRectangle(cornerRadius: 2)
            .fill(item.seconds > 0 ? Color.qyubeInk : Color.qyubeSelection)
            .frame(maxWidth: .infinity).frame(height: max(3, 70 * item.seconds / maximum))
            .help("\(item.date.formatted()): \(QyubeFormat.duration(item.seconds))")
        }
      }.frame(height: 74, alignment: .bottom)
      HStack {
        Text(
          period == .day ? "00:00" : interval.start.formatted(.dateTime.month(.abbreviated).day()))
        Spacer()
        Text(
          period == .day
            ? "24:00"
            : interval.end.addingTimeInterval(-1).formatted(.dateTime.month(.abbreviated).day()))
      }.font(.system(size: 9)).foregroundStyle(.secondary)
    }.accessibilityElement(children: .ignore)
      .accessibilityLabel(
        "Focus distribution, grouped by session start \(period == .day ? "hour" : period == .year ? "month" : "day")"
      )
      .accessibilityValue(
        values.map { "\($0.date.formatted()): \(QyubeFormat.duration($0.seconds))" }.joined(
          separator: ", "))
  }
}
