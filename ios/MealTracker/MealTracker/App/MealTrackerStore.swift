import Foundation
import SwiftUI

struct RecentConfirmation: Identifiable, Equatable {
    var id: UUID { entry.id }
    var entry: MealEntry
    var disclosure: String?
    var completionRewardSourceID: String?
    var replacedSkippedCategory: MealCategory?
}

enum AsyncViewState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(String)
}

@MainActor
final class MealTrackerStore: ObservableObject {
    @Published private(set) var today: DaySnapshot
    @Published private(set) var days: [DaySnapshot] = []
    @Published private(set) var predictions: [MealPrediction] = []
    @Published private(set) var streak: StreakSummary = .zero
    @Published private(set) var resourceBalance = 0
    @Published private(set) var lifetimeCompleteDayCount = 0
    @Published private(set) var recentConfirmation: RecentConfirmation?
    @Published private(set) var settings: UserSettings = .defaults
    @Published private(set) var isAnalyzing = false
    @Published private(set) var appError: String?
    @Published private(set) var venueState: AsyncViewState<[VenueCandidate]> = .idle
    @Published private(set) var menuState: AsyncViewState<RestaurantMenuResult> = .idle
    @Published private(set) var healthState: AsyncViewState<HealthContextSnapshot> = .idle
    @Published private(set) var adventure: AdventureState

    let voiceTranscriber: any VoiceTranscribing
    let venueResolver: any VenueResolving
    let healthKit: any HealthKitReading

    private let repository: any MealRepository
    private let clock: any AppClock
    private let predictor: any MealPredicting
    private let textAnalyzer: any MealTextAnalyzing
    private let photoAnalyzer: any MealPhotoAnalyzing
    private let menuService: any RestaurantMenuSearching
    private let adventureGenerator: any AdventureContentGenerating
    private let adventurePersistence: any AdventureStatePersisting
    private let templates: [MealTemplate]

    init(
        repository: any MealRepository,
        clock: any AppClock = SystemClock(),
        predictor: any MealPredicting = DeterministicMealPredictionEngine(),
        textAnalyzer: any MealTextAnalyzing = DemoMealAnalyzer(),
        photoAnalyzer: any MealPhotoAnalyzing = DemoMealAnalyzer(),
        voiceTranscriber: any VoiceTranscribing,
        venueResolver: any VenueResolving,
        menuService: any RestaurantMenuSearching = DemoRestaurantMenuService(),
        healthKit: any HealthKitReading,
        adventureGenerator: any AdventureContentGenerating = DemoAdventureContentGenerator(),
        adventurePersistence: (any AdventureStatePersisting)? = nil,
        templates: [MealTemplate] = SeedMealCatalog.templates
    ) {
        self.repository = repository
        self.clock = clock
        self.predictor = predictor
        self.textAnalyzer = textAnalyzer
        self.photoAnalyzer = photoAnalyzer
        self.voiceTranscriber = voiceTranscriber
        self.venueResolver = venueResolver
        self.menuService = menuService
        self.healthKit = healthKit
        self.adventureGenerator = adventureGenerator
        let resolvedAdventurePersistence = adventurePersistence ?? UserDefaultsAdventureStatePersistence()
        self.adventurePersistence = resolvedAdventurePersistence
        adventure = resolvedAdventurePersistence.load() ?? .initial
        self.templates = templates
        let identifier = LocalDayResolver.identifier(for: clock.now, in: clock.timeZone)
        today = DaySnapshot(
            dayIdentifier: identifier,
            timeZoneIdentifier: clock.timeZone.identifier,
            entries: [],
            skippedCategories: [],
            endedAt: nil
        )
    }

    func bootstrap() {
        refresh()
        seedUITestRecoveryDayIfNeeded()
        seedUITestRestaurantIfNeeded()
    }

    func refreshForSignificantTimeChange() {
        refresh()
    }

    func dismissError() {
        appError = nil
    }

    func draft(for prediction: MealPrediction) -> MealDraft {
        predictor.draft(for: prediction, entries: days.flatMap(\.entries))
    }

    func day(identifier: String) -> DaySnapshot? {
        days.first { $0.dayIdentifier == identifier }
    }

    func templatesForManualEntry() -> [MealTemplate] {
        templates
    }

    func previousOrders(venueID: String) -> [MealEntry] {
        days
            .flatMap(\.entries)
            .filter { $0.venueID == venueID }
            .sorted { $0.consumedAt > $1.consumedAt }
    }

    func log(
        draft: MealDraft,
        inputMethod: MealInputMethod = .prediction,
        targetDayIdentifier: String? = nil,
        disclosure: String? = nil,
        venueID: String? = nil
    ) {
        perform {
            let dayIdentifier = targetDayIdentifier ?? today.dayIdentifier
            let zone = timeZone(for: dayIdentifier)
            let replacedSkippedCategory = day(identifier: dayIdentifier)?.skippedCategories.contains(draft.category) == true
                ? draft.category
                : nil
            let consumedAt: Date
            if dayIdentifier == LocalDayResolver.identifier(for: clock.now, in: clock.timeZone) {
                consumedAt = clock.now
            } else {
                consumedAt = LocalDayResolver.date(
                    from: dayIdentifier,
                    hour: draft.category.defaultHour,
                    timeZone: zone
                ) ?? clock.now
            }

            let selectedIngredients = draft.ingredients.compactMap { slot -> LoggedIngredient? in
                guard slot.isIncluded, let option = slot.selectedOption else { return nil }
                return LoggedIngredient(id: slot.id, name: option.name, nutrition: option.nutrition)
            }
            let portion = draft.selectedPortion
            let entry = MealEntry(
                id: UUID(),
                templateID: draft.templateID,
                name: draft.name,
                createdAt: clock.now,
                consumedAt: consumedAt,
                localDayIdentifier: dayIdentifier,
                timeZoneIdentifier: zone.identifier,
                category: draft.category,
                ingredients: selectedIngredients,
                portionLabel: portion.label,
                exactQuantity: portion.exactQuantity,
                portionFactor: portion.factor,
                nutrition: draft.nutrition,
                provenance: draft.provenance,
                inputMethod: inputMethod,
                correctionCount: 0,
                venueID: venueID
            )
            try repository.saveEntry(entry)
            try repository.addRewardIfNeeded(RewardEngine.mealEvent(entryID: entry.id, at: clock.now))
            refresh(keepingRecent: true)
            let completionSource = try awardCompletionIfNeeded(dayIdentifier: dayIdentifier)
            refresh(keepingRecent: true)
            recentConfirmation = RecentConfirmation(
                entry: entry,
                disclosure: disclosure,
                completionRewardSourceID: completionSource,
                replacedSkippedCategory: replacedSkippedCategory
            )
            Haptics.loggingConfirmation()
        }
    }

    func updateEntry(_ entry: MealEntry) {
        perform {
            var corrected = entry
            corrected.correctionCount += 1
            try repository.saveEntry(corrected)
            refresh()
            let completionSource = try awardCompletionIfNeeded(dayIdentifier: corrected.localDayIdentifier)
            refresh()
            if recentConfirmation?.entry.id == corrected.id {
                recentConfirmation?.entry = corrected
                if recentConfirmation?.completionRewardSourceID == nil {
                    recentConfirmation?.completionRewardSourceID = completionSource
                }
            }
            Haptics.selection()
        }
    }

    func deleteEntry(_ entry: MealEntry) {
        perform {
            try repository.deleteEntry(id: entry.id)
            if recentConfirmation?.entry.id == entry.id { recentConfirmation = nil }
            refresh()
        }
    }

    func undoRecent() {
        guard let confirmation = recentConfirmation else { return }
        perform {
            try repository.deleteEntry(id: confirmation.entry.id)
            try repository.removeReward(sourceID: RewardEngine.mealEvent(entryID: confirmation.entry.id, at: clock.now).sourceID)
            if let replacedSkippedCategory = confirmation.replacedSkippedCategory {
                try repository.setSkipped(
                    true,
                    category: replacedSkippedCategory,
                    dayIdentifier: confirmation.entry.localDayIdentifier,
                    timeZoneIdentifier: confirmation.entry.timeZoneIdentifier
                )
            }
            if let sourceID = confirmation.completionRewardSourceID {
                try repository.removeReward(sourceID: sourceID)
            }
            recentConfirmation = nil
            refresh()
            Haptics.undo()
        }
    }

    func markSkipped(_ category: MealCategory, dayIdentifier: String, skipped: Bool = true) {
        perform {
            let zone = timeZone(for: dayIdentifier)
            try repository.setSkipped(
                skipped,
                category: category,
                dayIdentifier: dayIdentifier,
                timeZoneIdentifier: zone.identifier
            )
            refresh()
            _ = try awardCompletionIfNeeded(dayIdentifier: dayIdentifier)
            refresh()
            Haptics.selection()
        }
    }

    func endDay(skipping categories: Set<MealCategory>) {
        perform {
            for category in categories {
                try repository.setSkipped(
                    true,
                    category: category,
                    dayIdentifier: today.dayIdentifier,
                    timeZoneIdentifier: today.timeZoneIdentifier
                )
            }
            try repository.endDay(
                identifier: today.dayIdentifier,
                at: clock.now,
                timeZoneIdentifier: today.timeZoneIdentifier
            )
            refresh()
            _ = try awardCompletionIfNeeded(dayIdentifier: today.dayIdentifier)
            refresh()
        }
    }

    func analyzeTextAndLog(_ text: String, category: MealCategory, method: MealInputMethod = .text) async -> Bool {
        isAnalyzing = true
        defer { isAnalyzing = false }
        do {
            let result = try await textAnalyzer.analyze(text: text, category: category)
            log(draft: result.draft, inputMethod: method, disclosure: result.disclosure)
            return true
        } catch {
            appError = error.localizedDescription
            return false
        }
    }

    func analyzePhotoAndLog(_ data: Data, category: MealCategory, method: MealInputMethod) async -> Bool {
        isAnalyzing = true
        defer { isAnalyzing = false }
        do {
            let result = try await photoAnalyzer.analyze(imageData: data, category: category)
            log(draft: result.draft, inputMethod: method, disclosure: result.disclosure)
            return true
        } catch {
            appError = error.localizedDescription
            return false
        }
    }

    func saveSettings(_ updated: UserSettings) {
        perform {
            try repository.saveSettings(updated)
            settings = updated
            refresh()
        }
    }

    func detectVenues() async {
        venueState = .loading
        do {
            let venues = try await venueResolver.resolveForegroundVenues()
            venueState = .loaded(venues)
        } catch {
            venueState = .failed(error.localizedDescription)
        }
    }

    func searchMenu(for venue: VenueCandidate) async {
        menuState = .loading
        do {
            menuState = .loaded(try await menuService.menu(for: venue))
        } catch {
            menuState = .failed(error.localizedDescription)
        }
    }

    func resetMenuState() {
        menuState = .idle
    }

    func connectHealthKit() async {
        healthState = .loading
        do {
            guard try await healthKit.requestReadAccess() else {
                healthState = .failed("Apple Health access was not granted. Meal tracking is unchanged.")
                return
            }
            healthState = .loaded(try await healthKit.currentSnapshot())
        } catch {
            healthState = .failed(error.localizedDescription)
        }
    }

    func adventureEntryCopy() async -> String {
        do {
            return try await adventureGenerator.entryCopy(resourceBalance: resourceBalance)
        } catch {
            return "Your banked resources are safe. Adventure content is temporarily unavailable."
        }
    }

    var adventureEnergyBalance: Int {
        max(0, resourceBalance - adventure.energySpent)
    }

    func chooseAdventure(_ choice: AdventureChoiceID) {
        perform {
            let updated = try AdventureEngine.resolve(
                choice,
                in: adventure,
                availableEnergy: adventureEnergyBalance
            )
            try adventurePersistence.save(updated)
            adventure = updated
            Haptics.selection()
        }
    }

    private func refresh(keepingRecent: Bool = false) {
        perform(reportError: false) {
            let currentIdentifier = LocalDayResolver.identifier(for: clock.now, in: clock.timeZone)
            try repository.ensureDay(identifier: currentIdentifier, timeZoneIdentifier: clock.timeZone.identifier)
            days = try repository.fetchDays()
            today = days.first { $0.dayIdentifier == currentIdentifier } ?? DaySnapshot(
                dayIdentifier: currentIdentifier,
                timeZoneIdentifier: clock.timeZone.identifier,
                entries: [],
                skippedCategories: [],
                endedAt: nil
            )
            let allEntries = days.flatMap(\.entries)
            predictions = Array(
                predictor.predictions(
                    templates: templates,
                    entries: allEntries,
                    now: clock.now,
                    timeZone: clock.timeZone
                ).prefix(3)
            )
            streak = StreakEngine.calculate(days: days, currentDayIdentifier: currentIdentifier)
            let rewards = try repository.fetchRewards()
            resourceBalance = rewards.map(\.amount).reduce(0, +)
            lifetimeCompleteDayCount = rewards.filter { $0.kind == .dayCompleted }.count
            settings = try repository.fetchSettings()
            if !keepingRecent, let recentConfirmation,
               !allEntries.contains(where: { $0.id == recentConfirmation.entry.id }) {
                self.recentConfirmation = nil
            }
        }
    }

    private func seedUITestRecoveryDayIfNeeded() {
        guard ProcessInfo.processInfo.arguments.contains("-uiTestingRecovery") else { return }
        guard let previousDay = LocalDayResolver.addingDays(-1, to: today.dayIdentifier) else { return }
        guard day(identifier: previousDay) == nil, let template = templates.first(where: { $0.category == .breakfast }) else {
            return
        }
        log(draft: MealDraft(template: template), targetDayIdentifier: previousDay)
        recentConfirmation = nil
    }

    private func seedUITestRestaurantIfNeeded() {
        guard ProcessInfo.processInfo.arguments.contains("-uiTestingRestaurantStoneWay") else { return }
        venueState = .loaded([
            VenueCandidate(
                id: "stone-way-cafe-seattle",
                name: "Stone Way Cafe",
                subtitle: "3525 Stone Way North, Seattle, WA 98103",
                latitude: 47.6509,
                longitude: -122.3422,
                confidence: "Regression test venue"
            )
        ])
    }

    @discardableResult
    private func awardCompletionIfNeeded(dayIdentifier: String) throws -> String? {
        guard let day = try repository.fetchDays().first(where: { $0.dayIdentifier == dayIdentifier }), day.isComplete else {
            return nil
        }
        let event = RewardEngine.completionEvent(dayIdentifier: dayIdentifier, at: clock.now)
        let existed = try repository.fetchRewards().contains { $0.sourceID == event.sourceID }
        try repository.addRewardIfNeeded(event)
        if !existed { Haptics.dayCompletion() }
        return existed ? nil : event.sourceID
    }

    private func timeZone(for dayIdentifier: String) -> TimeZone {
        guard
            let identifier = days.first(where: { $0.dayIdentifier == dayIdentifier })?.timeZoneIdentifier,
            let zone = TimeZone(identifier: identifier)
        else {
            return clock.timeZone
        }
        return zone
    }

    private func perform(reportError: Bool = true, _ work: () throws -> Void) {
        do {
            try work()
        } catch {
            if reportError { appError = error.localizedDescription }
        }
    }
}
