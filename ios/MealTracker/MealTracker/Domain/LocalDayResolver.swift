import Foundation

protocol AppClock: Sendable {
    var now: Date { get }
    var timeZone: TimeZone { get }
}

struct SystemClock: AppClock {
    var now: Date { Date() }
    var timeZone: TimeZone { .autoupdatingCurrent }
}

struct FixedClock: AppClock {
    var now: Date
    var timeZone: TimeZone
}

enum LocalDayResolver {
    static func identifier(for date: Date, in timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    static func date(from identifier: String, hour: Int = 12, timeZone: TimeZone) -> Date? {
        let values = identifier.split(separator: "-").compactMap { Int($0) }
        guard values.count == 3 else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(
            from: DateComponents(
                timeZone: timeZone,
                year: values[0],
                month: values[1],
                day: values[2],
                hour: hour
            )
        )
    }

    static func addingDays(_ days: Int, to identifier: String) -> String? {
        let utc = TimeZone(identifier: "UTC") ?? .autoupdatingCurrent
        guard let date = date(from: identifier, timeZone: utc) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        guard let result = calendar.date(byAdding: .day, value: days, to: date) else { return nil }
        return self.identifier(for: result, in: utc)
    }
}
