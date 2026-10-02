import Foundation
import Observation
import SwiftData
#if DEBUG
import CoreData
#endif

/// Where My Day keeps the person's to-dos, priorities, templates, categories and journal pages
/// (with their photos and voice notes): a SwiftData store on the iPhone and, while Settings →
/// iCloud → Sync with iCloud is on (it is from the start), the person's private iCloud
/// database too. Whatever is in iCloud comes back after My Day is deleted and installed again,
/// and shows on their other devices signed in with the same Apple ID.
///
/// SwiftData syncs through CloudKit by itself once the app has the iCloud (CloudKit) and Push
/// Notifications entitlements (`MyDay.entitlements`) and the Remote notifications background
/// mode (`Info.plist`). Every model is ready for it: no unique attributes, a default for every
/// value, and optional relationships with inverses.
enum MyDayStore {
    /// The models kept in the store.
    static let models: [any PersistentModel.Type] = [
        TaskItem.self, Priority.self, JournalEntry.self, JournalPhoto.self, JournalVoiceNote.self,
        TaskTemplate.self, CustomCategory.self
    ]

    /// The iCloud container, as in `MyDay.entitlements` (SwiftData uses the first one listed there).
    static let iCloudContainer = "iCloud.com.regina3579.myday"

    /// Whether Sync with iCloud is on (until the person turns it off).
    static var syncsWithICloud: Bool {
        UserDefaults.standard.object(forKey: Prefs.iCloudSync) as? Bool ?? true
    }

    /// Opens the store. It is the same file with sync on or off, so switching keeps everything on
    /// the iPhone; with sync on, SwiftData uploads what isn't in iCloud yet and brings down
    /// what is.
    static func makeContainer(syncingWithICloud: Bool) -> ModelContainer {
        let schema = Schema(models)
        var syncs = syncingWithICloud
        #if DEBUG
        // Screenshot runs stay on the simulator.
        if DebugLaunchRoute.isScreenshotRun { syncs = false }
        #endif
        // `automatic` is the first iCloud container in the app's entitlements.
        let database: ModelConfiguration.CloudKitDatabase = syncs ? .automatic : .none
        let configuration = ModelConfiguration("MyDay", schema: schema, cloudKitDatabase: database)
        #if DEBUG
        if syncs { initializeCloudKitSchemaIfAsked(at: configuration.url) }
        #endif
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not open the My Day store: \(error)")
        }
    }

    #if DEBUG
    /// Debug builds launched with `-initializeCloudKitSchema` (Xcode → Edit Scheme → Run →
    /// Arguments): writes every record type and field to the container's development schema, which
    /// then has to be deployed to production in CloudKit Console before release. These are Apple's
    /// steps in "Syncing model data across a person's devices": load the store once with Core
    /// Data's CloudKit container, initialize the schema, then unload it before SwiftData opens it.
    private static func initializeCloudKitSchemaIfAsked(at url: URL) {
        guard ProcessInfo.processInfo.arguments.contains("-initializeCloudKitSchema") else { return }
        autoreleasepool {
            let description = NSPersistentStoreDescription(url: url)
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: iCloudContainer)
            // Loaded synchronously, so it is ready before the schema is initialized.
            description.shouldAddStoreAsynchronously = false
            guard let model = NSManagedObjectModel.makeManagedObjectModel(for: models) else { return }
            let container = NSPersistentCloudKitContainer(name: "MyDay", managedObjectModel: model)
            container.persistentStoreDescriptions = [description]
            var loadError: Error?
            container.loadPersistentStores { _, error in loadError = error }
            if let loadError {
                print("CloudKit schema: the store didn't load: \(loadError)")
                return
            }
            do {
                try container.initializeCloudKitSchema()
                print("CloudKit schema: initialized in \(iCloudContainer)")
            } catch {
                print("CloudKit schema: \(error)")
            }
            // Unloaded, so only SwiftData syncs it from here on.
            if let store = container.persistentStoreCoordinator.persistentStores.first {
                try? container.persistentStoreCoordinator.remove(store)
            }
        }
    }
    #endif
}

/// Holds the open store, and opens it again when Sync with iCloud is switched on or off.
@MainActor
@Observable
final class DataStore {
    /// The open store (nil for a moment while it is switched).
    private(set) var container: ModelContainer?
    private(set) var syncsWithICloud: Bool
    /// What iCloud is doing, shown in Settings.
    let syncStatus = CloudSyncStatus()
    /// Changes each time the store is opened again, so every screen starts afresh with it.
    private(set) var generation = 0

    init() {
        let syncs = MyDayStore.syncsWithICloud
        syncsWithICloud = syncs
        container = MyDayStore.makeContainer(syncingWithICloud: syncs)
    }

    /// Turns Sync with iCloud on or off. The store is saved and closed (the screens using it go
    /// away for a moment), then opened again the new way.
    func setSyncsWithICloud(_ isOn: Bool) async {
        guard isOn != syncsWithICloud, container != nil else { return }
        try? container?.mainContext.save()
        UserDefaults.standard.set(isOn, forKey: Prefs.iCloudSync)
        syncsWithICloud = isOn
        syncStatus.reset()
        container = nil
        // Lets the screens and their contexts go, so only one container has the store open.
        try? await Task.sleep(for: .seconds(0.6))
        container = MyDayStore.makeContainer(syncingWithICloud: isOn)
        generation += 1
    }
}
