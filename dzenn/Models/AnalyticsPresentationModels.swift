import Foundation
import SwiftUI

struct AnalyticsHeatmapCell: Identifiable, Hashable {
    let id = UUID()
    var date: Date
    var focusSeconds: Double
    var intensityLevel: Int

    var displayDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var weekdayAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

struct AnalyticsBreakdownItem: Identifiable, Hashable, Codable {
    let id = UUID()
    var name: String
    var seconds: Double
    var icon: String?

    var percentage: Double = 0
    var displayDuration: String {
        let minutes = seconds / 60.0
        if minutes >= 60 {
            let hours = Int(minutes / 60)
            let mins = Int(minutes.truncatingRemainder(dividingBy: 60))
            return "\(hours)h \(mins)m"
        }
        return "\(Int(minutes))m"
    }
}

struct AnalyticsTimelineEntry: Identifiable, Hashable {
    let id = UUID()
    var startedAt: Date
    var endedAt: Date
    var kind: TimelineEntryKind
    var name: String
    var detail: String?
    var seconds: Double

    enum TimelineEntryKind: String, Codable, Hashable {
        case app
        case website
    }

    var timeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startedAt)) - \(formatter.string(from: endedAt))"
    }
}
