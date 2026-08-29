import SwiftUI

struct RestaurantModeView: View {
    @EnvironmentObject private var store: MealTrackerStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedVenue: VenueCandidate?
    let onUseFallback: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    header
                    venueContent
                    fallback
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle("Restaurant mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.prominent, style: .continuous).fill(AppColors.brandSoft)
                LucideIcon(icon: .mapPin, size: 34).foregroundStyle(AppColors.brand)
            }
            .frame(width: 68, height: 68)
            Text("Find the likely place, not a perfect menu.")
                .font(.appDisplay(.title2, weight: .bold))
                .foregroundStyle(AppColors.ink)
            Text("MealTracker requests While Using the App location only. Nearby results may be approximate, and you always choose the venue.")
                .font(.appBody(.subheadline))
                .foregroundStyle(AppColors.muted)
        }
    }

    @ViewBuilder
    private var venueContent: some View {
        switch store.venueState {
        case .idle:
            Button("Detect nearby restaurants") {
                Task { await store.detectVenues() }
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityIdentifier("restaurant.detect")
        case .loading:
            LoadingPanel(title: "Looking nearby", detail: "Using foreground location only")
        case .failed(let message):
            StatePanel(icon: .mapPin, title: "Location isn’t available", detail: message) {
                Task { await store.detectVenues() }
            }
        case .loaded(let venues):
            if venues.isEmpty {
                StatePanel(
                    icon: .search,
                    title: "No nearby restaurant found",
                    detail: "You can still log immediately with photo, voice, or text."
                ) { Task { await store.detectVenues() } }
            } else {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("CHOOSE A VENUE")
                        .font(.appBody(.caption2, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(AppColors.muted)
                    ForEach(venues) { venue in
                        Button {
                            selectedVenue = venue
                            store.resetMenuState()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(venue.name).font(.appBody(.headline, weight: .bold))
                                    Text(venue.confidence).font(.appBody(.caption)).foregroundStyle(AppColors.muted)
                                }
                                Spacer()
                                LucideIcon(icon: .chevronRight, size: 18).foregroundStyle(AppColors.brand)
                            }
                            .foregroundStyle(AppColors.ink)
                            .padding(AppSpacing.md)
                            .appSurface(prominent: selectedVenue?.id == venue.id)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("restaurant.venue.\(venue.id)")
                    }
                    if let selectedVenue {
                        previousOrders(venue: selectedVenue)
                        Button("View Full Menu") {
                            Task { await store.searchMenu(for: selectedVenue) }
                        }
                        .buttonStyle(QuietActionButtonStyle())
                        .accessibilityIdentifier("restaurant.fullMenu")
                        Text("Not the right place? Choose another venue above.")
                            .font(.appBody(.caption))
                            .foregroundStyle(AppColors.muted)
                        menuContent(venue: selectedVenue)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func menuContent(venue: VenueCandidate) -> some View {
        switch store.menuState {
        case .idle:
            EmptyView()
        case .loading:
            LoadingPanel(title: "Checking reliable sources", detail: "Fallback logging stays available")
        case .failed(let message):
            StatePanel(icon: .wifiOff, title: "Menu search paused", detail: message) {
                Task { await store.searchMenu(for: venue) }
            }
        case .loaded(let result):
            switch result {
            case .noReliableMenu:
                StatePanel(
                    icon: .info,
                    title: "No reliable menu in this build",
                    detail: "No menu is presented as live or official. Use capture now; a private menu provider can be connected later."
                ) { Task { await store.searchMenu(for: venue) } }
                .accessibilityIdentifier("restaurant.noMenu")
            case .available(let items, let source):
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(source).font(.appBody(.caption)).foregroundStyle(AppColors.muted)
                    ForEach(items) { item in
                        Button {
                            let option = IngredientOption(id: item.id, name: item.name, nutrition: item.nutrition)
                            let draft = MealDraft(
                                name: item.name,
                                category: inferredCategory,
                                ingredients: [
                                    IngredientSlot(
                                        id: item.id,
                                        options: [option],
                                        selectedOptionID: option.id,
                                        isIncluded: true
                                    )
                                ],
                                portions: [
                                    PortionOption(id: "menu-serving", label: "Menu serving", exactQuantity: nil, factor: 1)
                                ],
                                provenance: item.isOfficial ? .official : .database
                            )
                            store.log(
                                draft: draft,
                                inputMethod: .restaurantMenu,
                                disclosure: item.sourceDescription,
                                venueID: venue.id
                            )
                            dismiss()
                        } label: {
                            HStack {
                                Text(item.name).font(.appBody(.headline))
                                Spacer()
                                LucideIcon(icon: .plus, size: 18).foregroundStyle(AppColors.brand)
                            }
                            .foregroundStyle(AppColors.ink)
                            .padding(AppSpacing.md)
                            .appSurface()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func previousOrders(venue: VenueCandidate) -> some View {
        let entries = store.previousOrders(venueID: venue.id)
        return VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("LIKELY / PREVIOUS ORDERS")
                .font(.appBody(.caption2, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(AppColors.muted)
            if entries.isEmpty {
                Text("No logged orders at this venue yet.")
                    .font(.appBody(.subheadline))
                    .foregroundStyle(AppColors.muted)
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appSurface()
            } else {
                ForEach(entries.prefix(3)) { entry in
                    Text(entry.name)
                        .font(.appBody(.callout, weight: .semibold))
                        .foregroundStyle(AppColors.ink)
                        .padding(AppSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appSurface()
                }
            }
        }
    }

    private var inferredCategory: MealCategory {
        let hour = Calendar.autoupdatingCurrent.component(.hour, from: Date())
        switch hour {
        case 4..<11: .breakfast
        case 11..<15: .lunch
        case 17..<22: .dinner
        default: .snacks
        }
    }

    private var fallback: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Divider()
            Text("LOG WITHOUT A MENU")
                .font(.appBody(.caption2, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(AppColors.muted)
            Button {
                onUseFallback()
            } label: {
                HStack {
                    LucideIcon(icon: .sparkles, size: 18)
                    Text("Use photo, voice, or text")
                }
            }
            .buttonStyle(QuietActionButtonStyle())
            .accessibilityIdentifier("restaurant.fallback")
        }
    }
}

private struct LoadingPanel: View {
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ProgressView().tint(AppColors.brand)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.appBody(.headline, weight: .bold))
                Text(detail).font(.appBody(.caption)).foregroundStyle(AppColors.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .appSurface()
    }
}

private struct StatePanel: View {
    let icon: Lucide
    let title: String
    let detail: String
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            LucideIcon(icon: icon, size: 22).foregroundStyle(AppColors.brand)
            Text(title).font(.appBody(.headline, weight: .bold)).foregroundStyle(AppColors.ink)
            Text(detail).font(.appBody(.subheadline)).foregroundStyle(AppColors.muted)
            Button("Try again", action: retry).font(.appBody(.callout, weight: .semibold)).foregroundStyle(AppColors.brand)
        }
        .padding(AppSpacing.md)
        .appSurface()
    }
}
