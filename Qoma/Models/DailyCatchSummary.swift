import Foundation

struct DailyCatchSummary: Identifiable {
    let kindID: String
    let events: [CatchEvent]
    var id: String {
        self.kindID
    }

    static func events(on day: Date, from catches: [CatchEvent], calendar: Calendar = .current) -> [CatchEvent] {
        guard let interval = calendar.dateInterval(of: .day, for: day) else { return [] }
        var seen = Set<UUID>()
        return catches.filter {
            $0.isBanked && $0.depositedAt >= interval.start && $0.depositedAt < interval.end
                && seen.insert($0.id).inserted
        }.sorted {
            $0.depositedAt == $1.depositedAt
                ? $0.id.uuidString < $1.id.uuidString : $0.depositedAt < $1.depositedAt
        }
    }

    static func groups(for events: [CatchEvent]) -> [DailyCatchSummary] {
        Dictionary(grouping: events, by: \.kindID).map { DailyCatchSummary(kindID: $0.key, events: $0.value) }
            .sorted {
                $0.events.count == $1.events.count ? $0.kindID < $1.kindID : $0.events.count > $1.events.count
            }
    }
}

enum CatchWeightFormat {
    static func kilograms(_ value: Double?) -> String {
        guard let value, value.isFinite, value > 0 else { return "— kg" }
        return String(format: "%.2f kg", locale: Locale(identifier: "en_US_POSIX"), max(0.01, value))
    }
}
