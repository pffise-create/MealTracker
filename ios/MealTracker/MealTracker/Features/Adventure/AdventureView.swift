import SwiftUI

struct AdventureView: View {
    @EnvironmentObject private var store: MealTrackerStore
    @State private var entryCopy = "Preparing the trail…"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    hero
                    resourceCard
                    limitedState
                }
                .padding(AppSpacing.md)
            }
            .background(AppColors.background)
            .navigationTitle("Adventure")
        }
        .task { entryCopy = await store.adventureEntryCopy() }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [AppColors.brand, AppColors.brandPressed],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ZStack {
                    Circle().fill(Color.white.opacity(0.16))
                    LucideIcon(icon: .compass, size: 38).foregroundStyle(.white)
                }
                .frame(width: 76, height: 76)
                Text("The Ridge Beyond")
                    .font(.appDisplay(.title, weight: .bold))
                    .foregroundStyle(.white)
                Text(entryCopy)
                    .font(.appBody(.subheadline))
                    .foregroundStyle(Color.white.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AppSpacing.xl)
        }
        .frame(minHeight: 260)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.prominent, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var resourceCard: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous).fill(AppColors.brandSoft)
                LucideIcon(icon: .gem, size: 30).foregroundStyle(AppColors.brand)
            }
            .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 2) {
                Text("BANKED ENERGY")
                    .font(.appBody(.caption2, weight: .bold)).tracking(1.2).foregroundStyle(AppColors.muted)
                Text("\(store.resourceBalance)")
                    .font(.appDisplay(.largeTitle, weight: .bold)).foregroundStyle(AppColors.ink)
                Text("Permanent progress from logging")
                    .font(.appBody(.caption)).foregroundStyle(AppColors.muted)
            }
            Spacer()
        }
        .padding(AppSpacing.md)
        .appSurface()
        .accessibilityIdentifier("adventure.balance")
    }

    private var limitedState: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                LucideIcon(icon: .lock, size: 21).foregroundStyle(AppColors.brand)
                Text("Adventure preview")
                    .font(.appDisplay(.title3, weight: .bold)).foregroundStyle(AppColors.ink)
            }
            Text("This milestone banks rewards and protects structured progress. The full AI dungeon master, companions, and encounters are deliberately not presented as ready yet.")
                .font(.appBody(.subheadline)).foregroundStyle(AppColors.muted)
            Divider()
            HStack {
                Text("Lifetime complete days")
                Spacer()
                Text("\(store.lifetimeCompleteDayCount)").fontWeight(.bold)
            }
            .font(.appBody(.callout))
            .foregroundStyle(AppColors.ink)
        }
        .padding(AppSpacing.md)
        .appSurface()
    }
}
