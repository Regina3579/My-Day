import Foundation
import HealthKit
import Observation

/// The steps walked each day, read from Apple Health (with the person's permission), for the
/// 🚶 line on journal pages. Nothing is written to Health, and nothing leaves the iPhone. Without
/// permission, or on a device without Health, there are simply no steps to show.
@MainActor
@Observable
final class StepCounter {
    static let shared = StepCounter()

    /// Steps per day (keyed by the day's start), as last read.
    private(set) var steps: [Date: Int] = [:]
    @ObservationIgnored private var readAt: [Date: Date] = [:]
    @ObservationIgnored private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// Goes up each time Health's answer may have changed, so the pages read their steps again.
    private(set) var permissionVersion = 0

    /// The only thing My Day reads from Health.
    private static let read: Set<HKObjectType> = [HKQuantityType(.stepCount)]

    /// Whether Health has not asked for the steps yet, so `HealthPrivacyNote` shows first.
    func needsPermission() async -> Bool {
        guard isAvailable else { return false }
        #if DEBUG
        if DebugLaunchRoute.isScreenshotRun { return false }
        #endif
        let status = try? await store.statusForAuthorizationRequest(toShare: [], read: Self.read)
        return status == .shouldRequest
    }

    /// Asks Health for permission to read steps (Health's own sheet) whenever Health says it
    /// has not been asked yet, then has the pages read their steps again. Health never says
    /// whether reading was allowed; when it wasn't, the days simply have no steps.
    func requestAccess() async {
        guard isAvailable else { return }
        #if DEBUG
        if DebugLaunchRoute.isScreenshotRun { return }
        #endif
        if let status = try? await store.statusForAuthorizationRequest(toShare: [], read: Self.read),
           status == .shouldRequest {
            try? await store.requestAuthorization(toShare: [], read: Self.read)
        }
        readAt = [:]
        permissionVersion += 1
    }

    /// The day's steps, reading them from Health when they are not known yet (today's again
    /// after a minute, as they still grow).
    func load(_ day: Date) async {
        let start = Calendar.current.startOfDay(for: day)
        #if DEBUG
        if DebugLaunchRoute.isScreenshotRun {
            // Screenshot runs: a believable count, the same each time.
            steps[start] = 3_000 + Int(start.timeIntervalSinceReferenceDate / 86_400) % 9 * 917
            return
        }
        #endif
        guard isAvailable else { return }
        if let read = readAt[start], !start.isToday || Date().timeIntervalSince(read) < 60 { return }
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        let predicate = HKSamplePredicate.quantitySample(
            type: HKQuantityType(.stepCount),
            predicate: HKQuery.predicateForSamples(withStart: start, end: end)
        )
        let query = HKStatisticsQueryDescriptor(predicate: predicate, options: .cumulativeSum)
        // Only a read that worked counts: one that failed (say, while the iPhone was locked)
        // is tried again the next time the page shows.
        let result: HKStatistics?
        do { result = try await query.result(for: store) } catch { return }
        readAt[start] = .now
        guard let total = result?.sumQuantity()?.doubleValue(for: .count()) else { return }
        steps[start] = Int(total.rounded())
    }

    func steps(on day: Date) -> Int? {
        steps[Calendar.current.startOfDay(for: day)]
    }
}
