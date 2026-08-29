import Foundation
import HealthKit

enum HealthKitServiceError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        "Apple Health is not available on this device. Meal tracking works normally without it."
    }
}

@MainActor
final class LiveHealthKitService: HealthKitReading {
    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestReadAccess() async throws -> Bool {
        guard isAvailable else { throw HealthKitServiceError.unavailable }
        let types = Set([
            HKObjectType.quantityType(forIdentifier: .bodyMass),
            HKObjectType.quantityType(forIdentifier: .stepCount),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            HKObjectType.workoutType()
        ].compactMap { $0 })

        return try await withCheckedThrowingContinuation { continuation in
            store.requestAuthorization(toShare: [], read: types) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }

    func currentSnapshot() async throws -> HealthContextSnapshot {
        guard isAvailable else { throw HealthKitServiceError.unavailable }
        async let weight = mostRecentQuantity(.bodyMass, unit: .gramUnit(with: .kilo))
        async let steps = cumulativeToday(.stepCount, unit: .count())
        async let energy = cumulativeToday(.activeEnergyBurned, unit: .kilocalorie())
        async let workouts = workoutCount(days: 14)
        return try await HealthContextSnapshot(
            latestWeightKilograms: weight,
            stepsToday: steps,
            activeEnergyToday: energy,
            recentWorkoutCount: workouts
        )
    }

    private func mostRecentQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                let sample = samples?.first as? HKQuantitySample
                continuation.resume(returning: sample?.quantity.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func cumulativeToday(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        let start = Calendar.autoupdatingCurrent.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) {
                _, statistics, error in
                if let error { continuation.resume(throwing: error); return }
                continuation.resume(returning: statistics?.sumQuantity()?.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func workoutCount(days: Int) async throws -> Int? {
        guard let start = Calendar.autoupdatingCurrent.date(byAdding: .day, value: -days, to: Date()) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) {
                _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                continuation.resume(returning: samples?.count)
            }
            store.execute(query)
        }
    }
}
