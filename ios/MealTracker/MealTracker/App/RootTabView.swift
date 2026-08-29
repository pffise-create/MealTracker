import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var store: MealTrackerStore
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            TodayView()
                .tabItem {
                    LucideIcon(icon: .utensils)
                    Text("Today")
                }
                .tag(0)
                .accessibilityIdentifier("tab.today")

            HistoryView()
                .tabItem {
                    LucideIcon(icon: .calendarDays)
                    Text("History")
                }
                .tag(1)
                .accessibilityIdentifier("tab.history")

            AdventureView()
                .tabItem {
                    LucideIcon(icon: .compass)
                    Text("Adventure")
                }
                .tag(2)
                .accessibilityIdentifier("tab.adventure")
        }
        .tint(AppColors.brand)
        .font(.appBody(.caption, weight: .semibold))
        .background(AppColors.background)
        .alert(
            "MealTracker couldn’t finish that",
            isPresented: Binding(
                get: { store.appError != nil },
                set: { if !$0 { store.dismissError() } }
            )
        ) {
            Button("OK") { store.dismissError() }
        } message: {
            Text(store.appError ?? "Please try again.")
        }
    }
}
