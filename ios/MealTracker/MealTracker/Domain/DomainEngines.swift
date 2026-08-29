import Foundation

enum NutritionEngine {
    static func aggregate(_ entries: [MealEntry]) -> NutritionSummary {
        entries.reduce(into: NutritionSummary()) { summary, entry in
            summary.add(entry.nutrition, provenance: entry.provenance)
        }
    }
}

enum DayCompletionEngine {
    static func isComplete(entries: [MealEntry], skipped: Set<MealCategory>) -> Bool {
        MealCategory.allCases.allSatisfy { category in
            skipped.contains(category) || entries.contains { $0.category == category }
        }
    }
}

enum StreakEngine {
    static func calculate(days: [DaySnapshot], currentDayIdentifier: String) -> StreakSummary {
        guard !days.isEmpty else { return .zero }
        let byIdentifier = Dictionary(uniqueKeysWithValues: days.map { ($0.dayIdentifier, $0) })
        let sorted = days.sorted { $0.dayIdentifier < $1.dayIdentifier }
        var longest = 0
        var running = 0
        var previousIdentifier: String?

        for day in sorted {
            let isConsecutive = previousIdentifier.flatMap { LocalDayResolver.addingDays(1, to: $0) } == day.dayIdentifier
            if day.isComplete {
                running = isConsecutive ? running + 1 : 1
                longest = max(longest, running)
            } else {
                running = 0
            }
            previousIdentifier = day.dayIdentifier
        }

        let anchor: String
        if byIdentifier[currentDayIdentifier]?.isComplete == true {
            anchor = currentDayIdentifier
        } else {
            anchor = LocalDayResolver.addingDays(-1, to: currentDayIdentifier) ?? currentDayIdentifier
        }

        var current = 0
        var cursor: String? = anchor
        while let identifier = cursor, byIdentifier[identifier]?.isComplete == true {
            current += 1
            cursor = LocalDayResolver.addingDays(-1, to: identifier)
        }

        return StreakSummary(
            current: current,
            longest: longest,
            totalCompleteDays: days.filter(\.isComplete).count
        )
    }
}

enum RewardEngine {
    static let mealAmount = 3
    static let completedDayAmount = 8

    static func mealEvent(entryID: UUID, at date: Date) -> RewardEvent {
        RewardEvent(
            sourceID: "meal:\(entryID.uuidString)",
            kind: .mealLogged,
            amount: mealAmount,
            createdAt: date
        )
    }

    static func completionEvent(dayIdentifier: String, at date: Date) -> RewardEvent {
        RewardEvent(
            sourceID: "day:\(dayIdentifier)",
            kind: .dayCompleted,
            amount: completedDayAmount,
            createdAt: date
        )
    }
}

protocol MealPredicting: Sendable {
    func predictions(
        templates: [MealTemplate],
        entries: [MealEntry],
        now: Date,
        timeZone: TimeZone
    ) -> [MealPrediction]

    func draft(for prediction: MealPrediction, entries: [MealEntry]) -> MealDraft
}

struct DeterministicMealPredictionEngine: MealPredicting {
    func predictions(
        templates: [MealTemplate],
        entries: [MealEntry],
        now: Date,
        timeZone: TimeZone
    ) -> [MealPrediction] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        let likelyCategory = category(for: hour)

        return templates.map { template in
            let matching = entries.filter { $0.templateID == template.id }
            let recent = matching.max(by: { $0.consumedAt < $1.consumedAt })
            let frequencyScore = min(Double(matching.count) * 5, 25)
            let recencyScore: Double
            if let recent {
                let days = max(now.timeIntervalSince(recent.consumedAt) / 86_400, 0)
                recencyScore = max(24 - days * 1.5, 0)
            } else {
                recencyScore = 0
            }
            let correctionScore = Double(matching.map(\.correctionCount).reduce(0, +)) * 8
            let sameWeekday = matching.contains { calendar.component(.weekday, from: $0.consumedAt) == weekday }
            let hourDistance = template.typicalHours.contains(hour)
                ? 16.0
                : max(10 - Double(distance(from: hour, to: template.typicalHours)), 0)
            let categoryScore = template.category == likelyCategory ? 32.0 : 0
            let score = categoryScore + hourDistance + frequencyScore + recencyScore + correctionScore + (sameWeekday ? 6 : 0)
            let learned = !matching.isEmpty
            let reason = learned
                ? learnedReason(count: matching.count, recent: recent, now: now)
                : "Starter suggestion • not learned from you"
            return MealPrediction(template: template, score: score, reason: reason, isLearned: learned)
        }
        .sorted {
            if $0.score == $1.score { return $0.template.name < $1.template.name }
            return $0.score > $1.score
        }
    }

    func draft(for prediction: MealPrediction, entries: [MealEntry]) -> MealDraft {
        var draft = MealDraft(template: prediction.template)
        guard let latest = entries
            .filter({ $0.templateID == prediction.template.id })
            .max(by: { $0.consumedAt < $1.consumedAt }) else {
            return draft
        }

        if let portion = draft.portions.min(by: {
            abs($0.factor - latest.portionFactor) < abs($1.factor - latest.portionFactor)
        }) {
            draft.selectedPortionID = portion.id
        }
        let loggedNames = Set(latest.ingredients.map { $0.name.lowercased() })
        for index in draft.ingredients.indices {
            let matchingOption = draft.ingredients[index].options.first {
                loggedNames.contains($0.name.lowercased())
            }
            if let matchingOption {
                draft.ingredients[index].selectedOptionID = matchingOption.id
                draft.ingredients[index].isIncluded = true
            } else {
                draft.ingredients[index].isIncluded = false
            }
        }
        return draft
    }

    private func category(for hour: Int) -> MealCategory {
        switch hour {
        case 4..<11: .breakfast
        case 11..<15: .lunch
        case 17..<22: .dinner
        default: .snacks
        }
    }

    private func distance(from hour: Int, to range: ClosedRange<Int>) -> Int {
        if hour < range.lowerBound { return range.lowerBound - hour }
        if hour > range.upperBound { return hour - range.upperBound }
        return 0
    }

    private func learnedReason(count: Int, recent: MealEntry?, now: Date) -> String {
        guard let recent else { return "Logged before"
        }
        let days = Int(max(now.timeIntervalSince(recent.consumedAt) / 86_400, 0))
        if days <= 2 { return "Recent choice • usual edits applied" }
        return "Logged \(count) \(count == 1 ? "time" : "times")"
    }
}
