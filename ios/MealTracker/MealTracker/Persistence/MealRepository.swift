import Foundation
import SwiftData

@MainActor
protocol MealRepository: AnyObject {
    func ensureDay(identifier: String, timeZoneIdentifier: String) throws
    func fetchEntries() throws -> [MealEntry]
    func saveEntry(_ entry: MealEntry) throws
    func deleteEntry(id: UUID) throws
    func fetchDays() throws -> [DaySnapshot]
    func setSkipped(_ value: Bool, category: MealCategory, dayIdentifier: String, timeZoneIdentifier: String) throws
    func endDay(identifier: String, at date: Date, timeZoneIdentifier: String) throws
    func fetchRewards() throws -> [RewardEvent]
    func addRewardIfNeeded(_ event: RewardEvent) throws
    func removeReward(sourceID: String) throws
    func fetchSettings() throws -> UserSettings
    func saveSettings(_ settings: UserSettings) throws
}

@MainActor
final class SwiftDataMealRepository: MealRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func ensureDay(identifier: String, timeZoneIdentifier: String) throws {
        guard try dayRecord(identifier: identifier) == nil else { return }
        context.insert(DayRecord(dayIdentifier: identifier, timeZoneIdentifier: timeZoneIdentifier))
        try context.save()
    }

    func fetchEntries() throws -> [MealEntry] {
        let descriptor = FetchDescriptor<MealEntryRecord>(sortBy: [SortDescriptor(\.consumedAt, order: .reverse)])
        return try context.fetch(descriptor).map { try $0.snapshot() }
    }

    func saveEntry(_ entry: MealEntry) throws {
        let identifier = entry.id
        let descriptor = FetchDescriptor<MealEntryRecord>(predicate: #Predicate { $0.id == identifier })
        if let record = try context.fetch(descriptor).first {
            try record.update(from: entry)
        } else {
            context.insert(try MealEntryRecord(entry: entry))
        }
        try ensureDay(identifier: entry.localDayIdentifier, timeZoneIdentifier: entry.timeZoneIdentifier)
        if let day = try dayRecord(identifier: entry.localDayIdentifier) {
            var skipped = day.skippedCategories
            skipped.remove(entry.category)
            day.setSkipped(skipped)
        }
        try context.save()
    }

    func deleteEntry(id: UUID) throws {
        let descriptor = FetchDescriptor<MealEntryRecord>(predicate: #Predicate { $0.id == id })
        if let record = try context.fetch(descriptor).first {
            context.delete(record)
            try context.save()
        }
    }

    func fetchDays() throws -> [DaySnapshot] {
        let entries = try fetchEntries()
        let dayRecords = try context.fetch(FetchDescriptor<DayRecord>())
        var identifiers = Set(dayRecords.map(\.dayIdentifier))
        identifiers.formUnion(entries.map(\.localDayIdentifier))

        return identifiers.map { identifier in
            let record = dayRecords.first { $0.dayIdentifier == identifier }
            let matchingEntries = entries.filter { $0.localDayIdentifier == identifier }
            return DaySnapshot(
                dayIdentifier: identifier,
                timeZoneIdentifier: record?.timeZoneIdentifier
                    ?? matchingEntries.first?.timeZoneIdentifier
                    ?? TimeZone.autoupdatingCurrent.identifier,
                entries: matchingEntries,
                skippedCategories: record?.skippedCategories ?? [],
                endedAt: record?.endedAt
            )
        }
        .sorted { $0.dayIdentifier > $1.dayIdentifier }
    }

    func setSkipped(
        _ value: Bool,
        category: MealCategory,
        dayIdentifier: String,
        timeZoneIdentifier: String
    ) throws {
        try ensureDay(identifier: dayIdentifier, timeZoneIdentifier: timeZoneIdentifier)
        guard let record = try dayRecord(identifier: dayIdentifier) else { return }
        var skipped = record.skippedCategories
        if value {
            skipped.insert(category)
        } else {
            skipped.remove(category)
        }
        record.setSkipped(skipped)
        try context.save()
    }

    func endDay(identifier: String, at date: Date, timeZoneIdentifier: String) throws {
        try ensureDay(identifier: identifier, timeZoneIdentifier: timeZoneIdentifier)
        guard let record = try dayRecord(identifier: identifier) else { return }
        record.endedAt = date
        try context.save()
    }

    func fetchRewards() throws -> [RewardEvent] {
        let descriptor = FetchDescriptor<RewardRecord>(sortBy: [SortDescriptor(\.createdAt)])
        return try context.fetch(descriptor).compactMap(\.event)
    }

    func addRewardIfNeeded(_ event: RewardEvent) throws {
        let sourceID = event.sourceID
        let descriptor = FetchDescriptor<RewardRecord>(predicate: #Predicate { $0.sourceID == sourceID })
        guard try context.fetch(descriptor).isEmpty else { return }
        context.insert(RewardRecord(event: event))
        try context.save()
    }

    func removeReward(sourceID: String) throws {
        let descriptor = FetchDescriptor<RewardRecord>(predicate: #Predicate { $0.sourceID == sourceID })
        if let record = try context.fetch(descriptor).first {
            context.delete(record)
            try context.save()
        }
    }

    func fetchSettings() throws -> UserSettings {
        if let record = try context.fetch(FetchDescriptor<SettingsRecord>()).first {
            return record.settings
        }
        let record = SettingsRecord(settings: .defaults)
        context.insert(record)
        try context.save()
        return record.settings
    }

    func saveSettings(_ settings: UserSettings) throws {
        if let record = try context.fetch(FetchDescriptor<SettingsRecord>()).first {
            record.update(from: settings)
        } else {
            context.insert(SettingsRecord(settings: settings))
        }
        try context.save()
    }

    private func dayRecord(identifier: String) throws -> DayRecord? {
        let descriptor = FetchDescriptor<DayRecord>(predicate: #Predicate { $0.dayIdentifier == identifier })
        return try context.fetch(descriptor).first
    }
}
