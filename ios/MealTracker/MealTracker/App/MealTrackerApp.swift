import SwiftData
import SwiftUI
import UIKit

@main
struct MealTrackerApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store: MealTrackerStore
    private let modelContainer: ModelContainer

    init() {
        let inMemory = ProcessInfo.processInfo.arguments.contains("-uiTesting")
        do {
            let container = try AppContainer(inMemory: inMemory)
            _store = StateObject(wrappedValue: container.store)
            modelContainer = container.modelContainer
        } catch {
            fatalError("MealTracker could not initialize its local database: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .task { store.bootstrap() }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                    store.refreshForSignificantTimeChange()
                }
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.refreshForSignificantTimeChange() }
        }
    }
}
