import CloudKit
import Foundation
import Observation
import SwiftUI

// MARK: - The lists

/// One thing on a shared list ("Tomato"), ticked off and starred by anyone who shares it.
struct SharedItem: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var title: String
    var isDone = false
    var isImportant = false
    var sortOrder: Double = Date().timeIntervalSinceReferenceDate
    /// The first name of whoever added it, when known.
    var addedBy = ""
    var modifiedAt = Date()
    /// CloudKit's own fields of the last saved copy (so a change updates it rather than clashing).
    var systemFields: Data?
}

/// A list kept in iCloud and shared with other people ("Groceries 🛒"): every list lives in its
/// own CloudKit record zone, shared as a whole with a zone-wide `CKShare`, so everyone in it sees
/// every item and every tick.
struct SharedList: Codable, Identifiable, Hashable {
    var zoneName: String
    /// `CKCurrentUserDefaultName` for the person's own lists; the owner's iCloud user for lists
    /// shared with them.
    var ownerName: String
    var name: String
    var emoji: String
    var items: [SharedItem] = []
    var createdAt = Date()
    /// Made by this person (in their private database) rather than shared with them.
    var isMine: Bool
    /// Who shared it, for a list shared with this person ("Joseph").
    var sharedBy = ""
    /// The people in it who have joined, the owner included (1 until it is shared).
    var memberCount = 1
    var systemFields: Data?

    var id: String { ownerName + "/" + zoneName }
    var zoneID: CKRecordZone.ID { CKRecordZone.ID(zoneName: zoneName, ownerName: ownerName) }

    var sortedItems: [SharedItem] { items.sorted { $0.sortOrder < $1.sortOrder } }
    var doneCount: Int { items.filter(\.isDone).count }
}

/// Someone in a shared list, for the Share List sheet.
struct SharedListMember: Identifiable {
    let id: String
    let name: String
    let detail: String
    let isOwner: Bool
    let isMe: Bool
    let isPending: Bool
    /// Nil for the person themselves before the list is shared.
    let participant: CKShare.Participant?
}

// MARK: - The store

/// The iCloud container the lists live in (the same one as the to-dos and journal).
enum SharedListCloud {
    static let container = CKContainer(identifier: MyDayStore.iCloudContainer)
}

/// Shared Lists: kept on the iPhone (so they open at once and work offline) and synced with
/// iCloud by two `CKSyncEngine`s, one for the person's own lists (their private database) and one
/// for lists others shared with them (their shared database). Sharing uses Apple's CloudKit
/// sharing: the share sheet sends an invitation link, and whoever opens it joins the list in
/// their own My Day.
@MainActor @Observable
final class SharedListStore {
    static let shared = SharedListStore()

    static let zonePrefix = "List-"
    static let listRecordName = "list"
    static let itemPrefix = "item-"
    static let listType = "SharedList"
    static let itemType = "SharedItem"
    /// SwiftData's own zone in the same private database: the lists' sync engine leaves it alone.
    nonisolated static let swiftDataZone = CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone",
                                               ownerName: CKCurrentUserDefaultName)

    private(set) var lists: [SharedList] = []
    /// Nil until asked; false when no iCloud account is signed in.
    private(set) var hasICloudAccount: Bool?
    /// A list to open (a share just accepted): the root view opens it and clears this.
    var listToOpen: String?
    /// The last thing that went wrong, for a gentle note on screen.
    var problem: String?

    /// Made on first use only (a build without the iCloud entitlement, like the screenshot
    /// runs', must never touch CloudKit).
    var container: CKContainer { SharedListCloud.container }
    @ObservationIgnored private var privateEngine: CKSyncEngine?
    @ObservationIgnored private var sharedEngine: CKSyncEngine?
    @ObservationIgnored private var syncDelegate: SharedListSyncDelegate?
    @ObservationIgnored private var started = false

    private init() {
        lists = Self.loadCache()
    }

    var ownedCount: Int { lists.filter(\.isMine).count }

    func list(_ id: String) -> SharedList? { lists.first { $0.id == id } }

    /// Free accounts can make one shared list; My Day Pro makes any number. Joining lists others
    /// share is always free.
    func canMakeList(isPro: Bool) -> Bool { isPro || ownedCount < 1 }

    // MARK: Starting

    /// Starts syncing (once), after checking for an iCloud account.
    func start() {
        guard !started else { return }
        started = true
        #if DEBUG
        guard !DebugLaunchRoute.isScreenshotRun else { return }
        #endif
        Task {
            let status = try? await container.accountStatus()
            hasICloudAccount = status == .available
            guard status == .available else {
                // Tried again later (a list opening, pull to refresh) once iCloud is signed in.
                started = false
                return
            }
            let syncDelegate = SharedListSyncDelegate(store: self)
            self.syncDelegate = syncDelegate
            privateEngine = CKSyncEngine(CKSyncEngine.Configuration(
                database: container.privateCloudDatabase,
                stateSerialization: Self.loadState(.private),
                delegate: syncDelegate))
            sharedEngine = CKSyncEngine(CKSyncEngine.Configuration(
                database: container.sharedCloudDatabase,
                stateSerialization: Self.loadState(.shared),
                delegate: syncDelegate))
            queueUnsent()
        }
    }

    /// Lists and items made before syncing started (offline, no iCloud yet, or in the moment
    /// before it starts) were never queued: they are sent now.
    private func queueUnsent() {
        for list in lists {
            if list.isMine, list.systemFields == nil {
                privateEngine?.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: list.zoneID))])
                queueSave([Self.listRecordID(list.zoneID)], in: list)
            }
            let unsent = list.items.filter { $0.systemFields == nil }.map { Self.itemRecordID($0.id, list.zoneID) }
            if !unsent.isEmpty { queueSave(unsent, in: list) }
        }
    }

    /// Starts syncing and waits (a few seconds at most) for it to be ready.
    private func startAndWait() async {
        start()
        for _ in 0..<50 where privateEngine == nil {
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    /// Fetches what changed in iCloud now (pull to refresh, or a list opening).
    func refresh() async {
        await startAndWait()
        try? await privateEngine?.fetchChanges()
        try? await sharedEngine?.fetchChanges()
    }

    // MARK: Changing lists

    @discardableResult
    func makeList(name: String, emoji: String, items titles: [String] = []) -> SharedList {
        var list = SharedList(zoneName: Self.zonePrefix + UUID().uuidString, ownerName: CKCurrentUserDefaultName,
                              name: name, emoji: emoji, isMine: true)
        let start = Date().timeIntervalSinceReferenceDate
        list.items = titles.enumerated().map { index, title in
            SharedItem(title: title, sortOrder: start + Double(index), addedBy: Self.myFirstName)
        }
        lists.append(list)
        save()
        privateEngine?.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: list.zoneID))])
        queueSave([Self.listRecordID(list.zoneID)] + list.items.map { Self.itemRecordID($0.id, list.zoneID) },
                  in: list)
        return list
    }

    func rename(_ listID: String, name: String, emoji: String) {
        guard let index = lists.firstIndex(where: { $0.id == listID }) else { return }
        lists[index].name = name
        lists[index].emoji = emoji
        save()
        queueSave([Self.listRecordID(lists[index].zoneID)], in: lists[index])
    }

    func addItem(_ title: String, to listID: String) {
        guard let index = lists.firstIndex(where: { $0.id == listID }) else { return }
        let item = SharedItem(title: title, addedBy: Self.myFirstName)
        lists[index].items.append(item)
        save()
        queueSave([Self.itemRecordID(item.id, lists[index].zoneID)], in: lists[index])
    }

    func update(_ itemID: String, in listID: String, _ change: (inout SharedItem) -> Void) {
        guard let index = lists.firstIndex(where: { $0.id == listID }),
              let itemIndex = lists[index].items.firstIndex(where: { $0.id == itemID }) else { return }
        change(&lists[index].items[itemIndex])
        lists[index].items[itemIndex].modifiedAt = .now
        save()
        queueSave([Self.itemRecordID(itemID, lists[index].zoneID)], in: lists[index])
    }

    func deleteItem(_ itemID: String, from listID: String) {
        guard let index = lists.firstIndex(where: { $0.id == listID }) else { return }
        lists[index].items.removeAll { $0.id == itemID }
        save()
        engine(for: lists[index])?.state.add(pendingRecordZoneChanges: [
            .deleteRecord(Self.itemRecordID(itemID, lists[index].zoneID)),
        ])
    }

    /// Deletes one of the person's own lists, for everyone in it; or leaves a list someone else
    /// shared (it stays for them and the others).
    func removeList(_ listID: String) {
        guard let list = list(listID) else { return }
        lists.removeAll { $0.id == listID }
        save()
        engine(for: list)?.state.add(pendingDatabaseChanges: [.deleteZone(list.zoneID)])
    }

    private func queueSave(_ recordIDs: [CKRecord.ID], in list: SharedList) {
        engine(for: list)?.state.add(pendingRecordZoneChanges: recordIDs.map { .saveRecord($0) })
    }

    private func engine(for list: SharedList) -> CKSyncEngine? {
        list.isMine ? privateEngine : sharedEngine
    }

    // MARK: Sharing

    /// The list's share: the one it has, or a new one (the list is sent to iCloud first).
    func share(for listID: String) async throws -> CKShare {
        guard let list = list(listID) else { throw CKError(.unknownItem) }
        if let existing = try await existingShare(for: list) { return existing }
        guard list.isMine else { throw CKError(.permissionFailure) }
        await startAndWait()
        try await privateEngine?.sendChanges()
        let share = CKShare(recordZoneID: list.zoneID)
        share[CKShare.SystemFieldKey.title] = "\(list.name) \(list.emoji)"
        share.publicPermission = .none
        let result = try await container.privateCloudDatabase.modifyRecords(saving: [share], deleting: [])
        if case .failure(let error) = result.saveResults[share.recordID] { throw error }
        return share
    }

    func existingShare(for list: SharedList) async throws -> CKShare? {
        let database = list.isMine ? container.privateCloudDatabase : container.sharedCloudDatabase
        do {
            return try await database.record(for: Self.shareRecordID(list.zoneID)) as? CKShare
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    /// The people in a list, the owner first.
    func members(of share: CKShare) -> [SharedListMember] {
        let formatter = PersonNameComponentsFormatter()
        let me = share.currentUserParticipant
        return share.participants
            .filter { $0.acceptanceStatus != .removed }
            .map { participant in
                let email = participant.userIdentity.lookupInfo?.emailAddress
                    ?? participant.userIdentity.lookupInfo?.phoneNumber ?? ""
                let name = participant.userIdentity.nameComponents.map { formatter.string(from: $0) } ?? ""
                return SharedListMember(
                    id: participant.participantID,
                    name: name.isEmpty ? (email.isEmpty ? "Invited friend" : email) : name,
                    detail: name.isEmpty ? "" : email,
                    isOwner: participant.role == .owner,
                    isMe: participant == me,
                    isPending: participant.acceptanceStatus == .pending,
                    participant: participant)
            }
            .sorted { $0.isOwner && !$1.isOwner }
    }

    /// The owner takes someone out of their list.
    func remove(_ participant: CKShare.Participant, from share: CKShare) async throws -> CKShare {
        share.removeParticipant(participant)
        let result = try await container.privateCloudDatabase.modifyRecords(saving: [share], deleting: [])
        if case .failure(let error) = result.saveResults[share.recordID] { throw error }
        if case .success(let saved) = result.saveResults[share.recordID], let saved = saved as? CKShare {
            apply(saved)
            return saved
        }
        return share
    }

    /// The owner stops sharing: the list stays theirs, and leaves everyone else's My Day.
    func stopSharing(_ listID: String) async throws {
        guard let list = list(listID), list.isMine else { return }
        _ = try await container.privateCloudDatabase.modifyRecords(saving: [], deleting: [Self.shareRecordID(list.zoneID)])
        if let index = lists.firstIndex(where: { $0.id == listID }) {
            lists[index].memberCount = 1
            save()
        }
    }

    /// Someone opened an invitation link: they join the list, and it opens.
    func accept(_ metadata: CKShare.Metadata) async {
        do {
            _ = try await container.accept(metadata)
            let zoneID = metadata.share.recordID.zoneID
            await startAndWait()
            try? await sharedEngine?.fetchChanges()
            if let joined = lists.first(where: { $0.zoneID == zoneID }) {
                listToOpen = joined.id
            } else {
                listToOpen = "lists"
            }
        } catch {
            problem = "This shared list couldn't be opened. Please check you're signed in to iCloud and try the link again."
        }
    }

    // MARK: Syncing (called by the sync delegate)

    func handle(_ event: CKSyncEngine.Event, engine: CKSyncEngine) {
        let scope = engine.database.databaseScope
        switch event {
        case .stateUpdate(let update):
            Self.saveState(update.stateSerialization, scope)
        case .accountChange(let change):
            switch change.changeType {
            case .signIn:
                hasICloudAccount = true
            case .signOut, .switchAccounts:
                // Another person's lists must not stay on this iPhone.
                lists = []
                save()
                Self.saveState(nil, .private)
                Self.saveState(nil, .shared)
                hasICloudAccount = false
            @unknown default:
                break
            }
        case .fetchedDatabaseChanges(let changes):
            let gone = Set(changes.deletions.map(\.zoneID))
            if !gone.isEmpty {
                lists.removeAll { gone.contains($0.zoneID) }
                save()
            }
        case .fetchedRecordZoneChanges(let changes):
            for modification in changes.modifications {
                apply(modification.record, isMine: scope == .private)
            }
            for deletion in changes.deletions {
                let zoneID = deletion.recordID.zoneID
                guard let index = lists.firstIndex(where: { $0.zoneID == zoneID }) else { continue }
                if deletion.recordType == Self.itemType {
                    let itemID = String(deletion.recordID.recordName.dropFirst(Self.itemPrefix.count))
                    lists[index].items.removeAll { $0.id == itemID }
                } else if deletion.recordType == CKRecord.SystemType.share {
                    lists[index].memberCount = 1
                }
            }
            save()
        case .sentRecordZoneChanges(let sent):
            for record in sent.savedRecords {
                keepSystemFields(of: record)
            }
            var retry: [CKSyncEngine.PendingRecordZoneChange] = []
            var zonesToMake: [CKSyncEngine.PendingDatabaseChange] = []
            for failure in sent.failedRecordSaves {
                let recordID = failure.record.recordID
                switch failure.error.code {
                case .serverRecordChanged:
                    // Someone else changed it first: take theirs as the base, keep this change.
                    if let server = failure.error.serverRecord { keepSystemFields(of: server) }
                    retry.append(.saveRecord(recordID))
                case .zoneNotFound:
                    zonesToMake.append(.saveZone(CKRecordZone(zoneID: recordID.zoneID)))
                    clearSystemFields(of: recordID)
                    retry.append(.saveRecord(recordID))
                case .unknownItem:
                    clearSystemFields(of: recordID)
                    retry.append(.saveRecord(recordID))
                case .networkFailure, .networkUnavailable, .serviceUnavailable, .requestRateLimited, .zoneBusy:
                    break // The sync engine tries these again by itself.
                default:
                    problem = "Some changes to a shared list couldn't be saved to iCloud."
                }
            }
            if !zonesToMake.isEmpty, scope == .private { engine.state.add(pendingDatabaseChanges: zonesToMake) }
            if !retry.isEmpty { engine.state.add(pendingRecordZoneChanges: retry) }
            save()
        default:
            break
        }
    }

    /// The record to send for a pending change, built from the list on the iPhone.
    func record(for recordID: CKRecord.ID) -> CKRecord? {
        guard let list = lists.first(where: { $0.zoneID == recordID.zoneID }) else { return nil }
        if recordID.recordName == Self.listRecordName {
            let record = Self.record(type: Self.listType, id: recordID, systemFields: list.systemFields)
            record["name"] = list.name
            record["emoji"] = list.emoji
            record["createdAt"] = list.createdAt
            return record
        }
        let itemID = String(recordID.recordName.dropFirst(Self.itemPrefix.count))
        guard let item = list.items.first(where: { $0.id == itemID }) else { return nil }
        let record = Self.record(type: Self.itemType, id: recordID, systemFields: item.systemFields)
        record["title"] = item.title
        record["isDone"] = item.isDone
        record["isImportant"] = item.isImportant
        record["sortOrder"] = item.sortOrder
        record["addedBy"] = item.addedBy
        record["modifiedAt"] = item.modifiedAt
        return record
    }

    private func apply(_ record: CKRecord, isMine: Bool) {
        let zoneID = record.recordID.zoneID
        guard zoneID.zoneName.hasPrefix(Self.zonePrefix) else { return }
        let index: Int
        if let found = lists.firstIndex(where: { $0.zoneID == zoneID }) {
            index = found
        } else {
            lists.append(SharedList(zoneName: zoneID.zoneName, ownerName: zoneID.ownerName,
                                    name: "", emoji: "📝", isMine: isMine))
            index = lists.count - 1
        }
        if let share = record as? CKShare {
            apply(share)
            return
        }
        switch record.recordType {
        case Self.listType:
            lists[index].name = record["name"] as? String ?? lists[index].name
            lists[index].emoji = record["emoji"] as? String ?? lists[index].emoji
            lists[index].createdAt = record["createdAt"] as? Date ?? lists[index].createdAt
            lists[index].systemFields = Self.systemFields(of: record)
        case Self.itemType:
            let itemID = String(record.recordID.recordName.dropFirst(Self.itemPrefix.count))
            var item = lists[index].items.first { $0.id == itemID } ?? SharedItem(id: itemID, title: "")
            item.title = record["title"] as? String ?? item.title
            item.isDone = (record["isDone"] as? Bool) ?? item.isDone
            item.isImportant = (record["isImportant"] as? Bool) ?? item.isImportant
            item.sortOrder = record["sortOrder"] as? Double ?? item.sortOrder
            item.addedBy = record["addedBy"] as? String ?? item.addedBy
            item.modifiedAt = record["modifiedAt"] as? Date ?? item.modifiedAt
            item.systemFields = Self.systemFields(of: record)
            if let itemIndex = lists[index].items.firstIndex(where: { $0.id == itemID }) {
                lists[index].items[itemIndex] = item
            } else {
                lists[index].items.append(item)
            }
        default:
            break
        }
    }

    private func apply(_ share: CKShare) {
        guard let index = lists.firstIndex(where: { $0.zoneID == share.recordID.zoneID }) else { return }
        lists[index].memberCount = max(1, share.participants.filter { $0.acceptanceStatus == .accepted }.count)
        if let owner = share.participants.first(where: { $0.role == .owner }),
           let components = owner.userIdentity.nameComponents {
            lists[index].sharedBy = components.givenName ?? PersonNameComponentsFormatter().string(from: components)
        }
        save()
    }

    private func keepSystemFields(of record: CKRecord) {
        guard let index = lists.firstIndex(where: { $0.zoneID == record.recordID.zoneID }) else { return }
        if record.recordType == Self.listType {
            lists[index].systemFields = Self.systemFields(of: record)
        } else if record.recordType == Self.itemType {
            let itemID = String(record.recordID.recordName.dropFirst(Self.itemPrefix.count))
            if let itemIndex = lists[index].items.firstIndex(where: { $0.id == itemID }) {
                lists[index].items[itemIndex].systemFields = Self.systemFields(of: record)
            }
        }
    }

    private func clearSystemFields(of recordID: CKRecord.ID) {
        guard let index = lists.firstIndex(where: { $0.zoneID == recordID.zoneID }) else { return }
        if recordID.recordName == Self.listRecordName {
            lists[index].systemFields = nil
        } else {
            let itemID = String(recordID.recordName.dropFirst(Self.itemPrefix.count))
            if let itemIndex = lists[index].items.firstIndex(where: { $0.id == itemID }) {
                lists[index].items[itemIndex].systemFields = nil
            }
        }
    }

    // MARK: Records

    static func listRecordID(_ zoneID: CKRecordZone.ID) -> CKRecord.ID {
        CKRecord.ID(recordName: listRecordName, zoneID: zoneID)
    }

    static func itemRecordID(_ itemID: String, _ zoneID: CKRecordZone.ID) -> CKRecord.ID {
        CKRecord.ID(recordName: itemPrefix + itemID, zoneID: zoneID)
    }

    static func shareRecordID(_ zoneID: CKRecordZone.ID) -> CKRecord.ID {
        CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: zoneID)
    }

    private static func record(type: String, id: CKRecord.ID, systemFields: Data?) -> CKRecord {
        if let systemFields, let coder = try? NSKeyedUnarchiver(forReadingFrom: systemFields) {
            coder.requiresSecureCoding = true
            defer { coder.finishDecoding() }
            if let record = CKRecord(coder: coder) { return record }
        }
        return CKRecord(recordType: type, recordID: id)
    }

    private static func systemFields(of record: CKRecord) -> Data {
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        record.encodeSystemFields(with: coder)
        coder.finishEncoding()
        return coder.encodedData
    }

    /// The person's first name, from Settings (so others see who added what).
    private static var myFirstName: String {
        let name = UserDefaults.standard.string(forKey: Prefs.userName) ?? ""
        return name.split(separator: " ").first.map(String.init) ?? ""
    }

    // MARK: Saving on the iPhone

    private static var folder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("SharedLists", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private static var cacheURL: URL { folder.appendingPathComponent("lists.json") }

    private static func stateURL(_ scope: CKDatabase.Scope) -> URL {
        folder.appendingPathComponent(scope == .private ? "sync-private.json" : "sync-shared.json")
    }

    private static func loadCache() -> [SharedList] {
        guard let data = try? Data(contentsOf: cacheURL) else { return [] }
        return (try? JSONDecoder().decode([SharedList].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(lists) else { return }
        try? data.write(to: Self.cacheURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    private static func loadState(_ scope: CKDatabase.Scope) -> CKSyncEngine.State.Serialization? {
        guard let data = try? Data(contentsOf: stateURL(scope)) else { return nil }
        return try? JSONDecoder().decode(CKSyncEngine.State.Serialization.self, from: data)
    }

    private static func saveState(_ state: CKSyncEngine.State.Serialization?, _ scope: CKDatabase.Scope) {
        guard let state else {
            try? FileManager.default.removeItem(at: stateURL(scope))
            return
        }
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: stateURL(scope), options: .atomic)
    }

    #if DEBUG
    /// Screenshot runs: lists on the iPhone only, never sent to iCloud.
    func loadDemo() {
        let now = Date().timeIntervalSinceReferenceDate
        func items(_ titles: [(String, Bool, Bool)]) -> [SharedItem] {
            titles.enumerated().map { index, entry in
                SharedItem(title: entry.0, isDone: entry.1, isImportant: entry.2, sortOrder: now + Double(index))
            }
        }
        lists = [
            SharedList(zoneName: "List-demo-groceries", ownerName: CKCurrentUserDefaultName, name: "Groceries",
                       emoji: "🛒", items: items([("Tomatoes", false, false), ("Ginger", false, true),
                                                  ("Fresh flowers", false, false), ("Strawberries", true, false),
                                                  ("Milk and bread", true, false)]),
                       isMine: true, memberCount: 2),
            SharedList(zoneName: "List-demo-family", ownerName: "_demoOwner", name: "Family To-Dos", emoji: "🏡",
                       items: items([("Water the plants", false, false), ("Book the vet", false, true),
                                     ("Pick up the parcel", true, false)]),
                       isMine: false, sharedBy: "Joseph", memberCount: 3),
        ]
    }
    #endif
}

/// Hands the sync engines' work to the store on the main thread.
final class SharedListSyncDelegate: CKSyncEngineDelegate, @unchecked Sendable {
    private weak var store: SharedListStore?

    init(store: SharedListStore) {
        self.store = store
    }

    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        await store?.handle(event, engine: syncEngine)
    }

    func nextRecordZoneChangeBatch(_ context: CKSyncEngine.SendChangesContext,
                                   syncEngine: CKSyncEngine) async -> CKSyncEngine.RecordZoneChangeBatch? {
        let scope = context.options.scope
        let pending = syncEngine.state.pendingRecordZoneChanges.filter { scope.contains($0) }
        guard !pending.isEmpty else { return nil }
        return await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: pending) { [weak self] recordID in
            await self?.store?.record(for: recordID)
        }
    }

    /// The private database also holds SwiftData's own zone (the to-dos and journal): the
    /// lists' engine never downloads it.
    func nextFetchChangesOptions(_ context: CKSyncEngine.FetchChangesContext,
                                 syncEngine: CKSyncEngine) async -> CKSyncEngine.FetchChangesOptions {
        guard syncEngine.database.databaseScope == .private else { return context.options }
        return CKSyncEngine.FetchChangesOptions(scope: .allExcluding([SharedListStore.swiftDataZone]),
                                               operationGroup: context.options.operationGroup)
    }
}

/// A to-do category shared from To-Dos (👤+): which Shared List it became, so sharing it again
/// opens the same list.
struct SharedListLink: Identifiable {
    let id: String

    static func list(for choice: CategoryChoice) -> String? {
        links[choice.key]
    }

    static func remember(_ listID: String, for choice: CategoryChoice) {
        var all = links
        all[choice.key] = listID
        UserDefaults.standard.set(all, forKey: Prefs.sharedCategoryLists)
        // A new list: nothing of the category has gone into it yet.
        var sent = sentByCategory
        sent[choice.key] = []
        UserDefaults.standard.set(sent, forKey: Prefs.sharedCategoryTasks)
    }

    /// The to-dos (by id) already put into the category's list.
    static func sentTasks(for choice: CategoryChoice) -> Set<String> {
        Set(sentByCategory[choice.key] ?? [])
    }

    static func noteSent(_ taskIDs: [String], for choice: CategoryChoice) {
        var sent = sentByCategory
        sent[choice.key] = Array(Set(sent[choice.key] ?? []).union(taskIDs))
        UserDefaults.standard.set(sent, forKey: Prefs.sharedCategoryTasks)
    }

    private static var sentByCategory: [String: [String]] {
        UserDefaults.standard.dictionary(forKey: Prefs.sharedCategoryTasks) as? [String: [String]] ?? [:]
    }

    private static var links: [String: String] {
        UserDefaults.standard.dictionary(forKey: Prefs.sharedCategoryLists) as? [String: String] ?? [:]
    }
}
