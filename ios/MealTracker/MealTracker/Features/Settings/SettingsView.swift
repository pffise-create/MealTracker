import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: MealTrackerStore
    @Environment(\.dismiss) private var dismiss
    @State private var settings: UserSettings = .defaults
    @State private var backendToken = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    targetsCard
                    privacyCard
                    healthCard
                    integrationCard
                }
                .padding(AppSpacing.md)
            }
            .background(AppColors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.saveSettings(settings)
                        try? BackendCredentialStore.save(accessToken: backendToken)
                        dismiss()
                    }
                    .accessibilityIdentifier("settings.save")
                }
            }
        }
        .onAppear {
            settings = store.settings
            backendToken = BackendCredentialStore.accessToken ?? ""
        }
    }

    private var targetsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            cardTitle("Nutrition targets", icon: .utensils)
            target("Calories", value: $settings.targets.calories, range: 1_000...5_000, step: 50, unit: "kcal")
            target("Protein", value: $settings.targets.protein, range: 40...300, step: 5, unit: "g")
            target("Fat", value: $settings.targets.fat, range: 20...200, step: 5, unit: "g")
            target("Carbohydrates", value: $settings.targets.carbohydrates, range: 40...500, step: 5, unit: "g")
        }
        .padding(AppSpacing.md)
        .appSurface()
    }

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            cardTitle("Privacy", icon: .shieldCheck)
            HStack(alignment: .firstTextBaseline) {
                Text("Original meal photos")
                Spacer()
                Text("Never saved")
                    .foregroundStyle(AppColors.muted)
            }
            .font(.appBody(.callout, weight: .semibold))
            Text("Analyzed, then discarded.")
                .font(.appBody(.caption)).foregroundStyle(AppColors.muted)
        }
        .padding(AppSpacing.md)
        .appSurface()
    }

    private var healthCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            cardTitle("Apple Health", icon: .heartPulse)
            Text("Read-only access")
                .font(.appBody(.subheadline)).foregroundStyle(AppColors.muted)
            healthState
        }
        .padding(AppSpacing.md)
        .appSurface()
    }

    @ViewBuilder
    private var healthState: some View {
        switch store.healthState {
        case .idle:
            Button("Connect Apple Health") { Task { await store.connectHealthKit() } }
                .buttonStyle(QuietActionButtonStyle())
                .disabled(!store.healthKit.isAvailable)
                .accessibilityIdentifier("settings.health")
        case .loading:
            ProgressView("Requesting read access…").tint(AppColors.brand)
        case .failed(let message):
            Text(message).font(.appBody(.caption)).foregroundStyle(AppColors.muted)
            Button("Try again") { Task { await store.connectHealthKit() } }
                .font(.appBody(.callout, weight: .semibold)).foregroundStyle(AppColors.brand)
        case .loaded(let snapshot):
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Connected")
                    .font(.appBody(.callout, weight: .bold)).foregroundStyle(AppColors.ink)
                Text(healthSummary(snapshot))
                    .font(.appBody(.caption)).foregroundStyle(AppColors.muted)
            }
        }
    }

    private var integrationCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            cardTitle("Connections", icon: .info)
            statusRow("Nutrition", BackendMealAnalyzer() == nil ? "Demo" : "AI")
            statusRow("Voice", "On device")
            statusRow("Restaurants", "Official menus")
            if BackendMealAnalyzer() != nil {
                SecureField("Backend access token", text: $backendToken)
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Private backend access token")
                Text("Saved in this iPhone’s Keychain.")
                    .font(.appBody(.caption)).foregroundStyle(AppColors.muted)
            } else {
                Text("Add an HTTPS backend URL in Xcode.")
                    .font(.appBody(.caption)).foregroundStyle(AppColors.muted)
            }
        }
        .padding(AppSpacing.md)
        .appSurface()
    }

    private func cardTitle(_ text: String, icon: Lucide) -> some View {
        HStack {
            LucideIcon(icon: icon, size: 20).foregroundStyle(AppColors.brand)
            Text(text).font(.appDisplay(.title3, weight: .bold)).foregroundStyle(AppColors.ink)
        }
    }

    private func target(
        _ label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        unit: String
    ) -> some View {
        Stepper(value: value, in: range, step: step) {
            HStack {
                Text(label)
                Spacer()
                Text("\(Int(value.wrappedValue)) \(unit)").foregroundStyle(AppColors.muted)
            }
            .font(.appBody(.callout))
        }
        .accessibilityIdentifier("settings.target.\(label.lowercased())")
    }

    private func statusRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).foregroundStyle(AppColors.ink)
            Spacer()
            Text(value).foregroundStyle(AppColors.muted).multilineTextAlignment(.trailing)
        }
        .font(.appBody(.caption))
    }

    private func healthSummary(_ snapshot: HealthContextSnapshot) -> String {
        let steps = snapshot.stepsToday.map { "\(Int($0)) steps" } ?? "steps unavailable"
        let energy = snapshot.activeEnergyToday.map { "\(Int($0)) active kcal" } ?? "active energy unavailable"
        let workouts = snapshot.recentWorkoutCount.map { "\($0) workouts in 14 days" } ?? "workouts unavailable"
        return "\(steps) • \(energy) • \(workouts)"
    }
}
