import Foundation
import SwiftData

@MainActor
final class AppContainer {
    let modelContainer: ModelContainer
    let store: MealTrackerStore

    init(inMemory: Bool = false) throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        modelContainer = try ModelContainer(
            for: MealEntryRecord.self,
            DayRecord.self,
            RewardRecord.self,
            SettingsRecord.self,
            configurations: configuration
        )
        let repository = SwiftDataMealRepository(context: modelContainer.mainContext)
        let analyzer: any MealTextAnalyzing & MealPhotoAnalyzing = BackendMealAnalyzer() ?? DemoMealAnalyzer()
        store = MealTrackerStore(
            repository: repository,
            textAnalyzer: analyzer,
            photoAnalyzer: analyzer,
            voiceTranscriber: LiveSpeechTranscriber(),
            venueResolver: LiveVenueResolver(),
            healthKit: LiveHealthKitService()
        )
    }
}
