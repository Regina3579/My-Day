import Foundation
import CoreData
import CloudKit
import Observation

/// What iCloud sync is doing, for Settings → iCloud. SwiftData syncs through Core Data's
/// `NSPersistentCloudKitContainer`, which posts an event as each setup, import (changes coming
/// down from iCloud) and export (changes going up) starts and ends.
@MainActor
@Observable
final class CloudSyncStatus {
    enum State: Equatable {
        /// Nothing heard from iCloud yet.
        case idle
        case syncing
        /// The last sync finished, at this time.
        case upToDate(Date)
        /// The last sync failed: what to tell the person.
        case problem(String)
    }

    private(set) var state: State = .idle
    /// Goes up each time changes from iCloud have been brought in (screens tidy up after them).
    private(set) var imports = 0

    /// Events started and not yet ended.
    @ObservationIgnored private var running: Set<UUID> = []
    @ObservationIgnored private var observer: (any NSObjectProtocol)?

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification, object: nil, queue: .main
        ) { [weak self] notification in
            MainActor.assumeIsolated {
                guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event
                else { return }
                self?.record(event)
            }
        }
    }

    /// Forgets the last state (sync was switched on or off).
    func reset() {
        running.removeAll()
        state = .idle
    }

    #if DEBUG
    /// Screenshot runs only ("settings-icloud"): the simulator has no iCloud account.
    func showForScreenshot(_ demo: State) {
        state = demo
    }
    #endif

    private func record(_ event: NSPersistentCloudKitContainer.Event) {
        // Each event is posted twice: when it starts (no end date yet) and when it ends.
        guard let end = event.endDate else {
            running.insert(event.identifier)
            state = .syncing
            return
        }
        running.remove(event.identifier)
        guard event.succeeded else {
            state = .problem(Self.message(for: event.error))
            return
        }
        if event.type == .import {
            imports += 1
        }
        if running.isEmpty {
            state = .upToDate(end)
        }
    }

    /// A plain explanation of why a sync failed.
    private static func message(for error: (any Error)?) -> String {
        let nsError = error as NSError?
        let cloudError = (error as? CKError) ?? (nsError?.userInfo[NSUnderlyingErrorKey] as? CKError)
        switch cloudError?.code {
        case .notAuthenticated, .accountTemporarilyUnavailable:
            return Self.signInMessage
        case .quotaExceeded:
            return "Your iCloud storage is full, so new changes stay on this iPhone for now."
        case .networkUnavailable, .networkFailure:
            return "Waiting for the internet. My Day syncs as soon as you're online."
        default:
            // Core Data's "Unable to initialize without an iCloud account" (134400).
            if nsError?.domain == NSCocoaErrorDomain, nsError?.code == 134400 {
                return Self.signInMessage
            }
            return "iCloud couldn't sync just now. My Day will try again."
        }
    }

    private static let signInMessage = "Sign in to iCloud in the Settings app, and turn on iCloud for My Day, to keep your data safe."
}
