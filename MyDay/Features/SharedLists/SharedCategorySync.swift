import SwiftData
import SwiftUI

/// Keeps a to-do category shared from To-Dos (👤+) and its Shared List the same, both ways. A
/// to-do added, renamed, ticked or deleted here changes the list for everyone in it, through
/// iCloud; an item someone in the list ticks, renames or adds changes the to-dos here.
///
/// Each to-do is paired with its item, with the title and tick both had when last matched, so
/// a difference tells which side changed. An item deleted from the list stays deleted (its
/// to-do stays here).
@MainActor
enum SharedCategorySync {
    struct Pair: Codable {
        var itemID: String
        var title: String
        var isDone: Bool
    }

    /// Lines the shared categories and their lists up. `tasks` is every to-do.
    static func sync(tasks: [TaskItem], customs: [CustomCategory], in context: ModelContext, today: Date) {
        let links = SharedListLink.all
        guard !links.isEmpty else { return }
        let store = SharedListStore.shared
        var allPairs = loadPairs()
        for (key, listID) in links {
            guard let list = store.list(listID), list.isMine else { continue }
            let start = SharedListLink.start(for: key, today: today)
            let mine = tasks.filter { $0.choice.key == key && $0.date >= start && $0.modelContext != nil }
            var pairs = allPairs[listID] ?? [:]
            let items = Dictionary(list.items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            let taskIDs = Set(mine.map(\.id.uuidString))

            // Deleted here (or moved to another category): gone from the list too.
            for (taskID, pair) in pairs where !taskIDs.contains(taskID) {
                if items[pair.itemID] != nil { store.deleteItem(pair.itemID, from: listID) }
                pairs[taskID] = nil
            }

            var claimed = Set(pairs.values.map(\.itemID))
            for task in mine {
                let taskID = task.id.uuidString
                if var pair = pairs[taskID] {
                    // Deleted from the list by someone: it stays deleted there.
                    guard let item = items[pair.itemID] else { continue }
                    if task.title != pair.title || task.isCompleted != pair.isDone {
                        // Changed here: the list follows.
                        if item.title != task.title || item.isDone != task.isCompleted {
                            let title = task.title, isDone = task.isCompleted
                            store.update(pair.itemID, in: listID) { item in
                                item.title = title
                                item.isDone = isDone
                            }
                        }
                    } else if item.title != pair.title || item.isDone != pair.isDone {
                        // Changed in the list: the to-do follows.
                        if !item.title.trimmed.isEmpty { task.title = item.title }
                        if task.isCompleted != item.isDone {
                            task.isCompleted = item.isDone
                            task.completedAt = item.isDone ? .now : nil
                        }
                    }
                    pair.title = task.title
                    pair.isDone = task.isCompleted
                    pairs[taskID] = pair
                } else {
                    // New here, or already in the list by the same name (from when it was shared).
                    let match = list.sortedItems.first {
                        !claimed.contains($0.id) && $0.title.lowercased() == task.title.lowercased()
                    }
                    var itemID = match?.id
                    if let match, match.isDone != task.isCompleted {
                        let isDone = task.isCompleted
                        store.update(match.id, in: listID) { $0.isDone = isDone }
                    }
                    if itemID == nil {
                        itemID = store.addItem(task.title, to: listID, isDone: task.isCompleted)
                    }
                    guard let itemID else { continue }
                    claimed.insert(itemID)
                    pairs[taskID] = Pair(itemID: itemID, title: task.title, isDone: task.isCompleted)
                }
            }

            // Added in the list by someone: a to-do here, today, in the category.
            if let choice = choice(for: key, customs: customs) {
                for item in list.sortedItems where !claimed.contains(item.id) && !item.isDone {
                    let task = TaskItem(title: item.title, date: today)
                    task.choice = choice
                    context.insert(task)
                    claimed.insert(item.id)
                    pairs[task.id.uuidString] = Pair(itemID: item.id, title: item.title, isDone: false)
                }
            }
            allPairs[listID] = pairs
        }
        savePairs(allPairs)
    }

    private static func choice(for key: String, customs: [CustomCategory]) -> CategoryChoice? {
        if let builtIn = TaskCategory(rawValue: key) { return .builtIn(builtIn) }
        return customs.first { CategoryChoice.custom($0).key == key }.map(CategoryChoice.custom)
    }

    private static func loadPairs() -> [String: [String: Pair]] {
        guard let data = UserDefaults.standard.data(forKey: Prefs.sharedCategoryPairs) else { return [:] }
        return (try? JSONDecoder().decode([String: [String: Pair]].self, from: data)) ?? [:]
    }

    private static func savePairs(_ pairs: [String: [String: Pair]]) {
        UserDefaults.standard.set(try? JSONEncoder().encode(pairs), forKey: Prefs.sharedCategoryPairs)
    }
}

/// Runs `SharedCategorySync` whenever a shared category's to-dos or its list change (kept out
/// of the root view, so these changes redraw only this).
struct SharedCategoryWatcher: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Query private var tasks: [TaskItem]
    @Query private var customs: [CustomCategory]

    /// Changes whenever something the sync looks at changes.
    private var signature: Int {
        // Read first, so a new list or to-do always looks again (a category may just have been shared).
        let lists = SharedListStore.shared.lists
        let links = SharedListLink.all
        guard !links.isEmpty else {
            _ = tasks.count
            return 0
        }
        var hasher = Hasher()
        hasher.combine(lists.count)
        hasher.combine(appState.today)
        for task in tasks where links[task.choice.key] != nil {
            hasher.combine(task.id)
            hasher.combine(task.title)
            hasher.combine(task.isCompleted)
            hasher.combine(task.date)
        }
        for listID in links.values.sorted() {
            hasher.combine(listID)
            for item in SharedListStore.shared.list(listID)?.items ?? [] {
                hasher.combine(item.id)
                hasher.combine(item.title)
                hasher.combine(item.isDone)
            }
        }
        return hasher.finalize()
    }

    var body: some View {
        Color.clear
            .task(id: signature) {
                guard signature != 0 else { return }
                // Lets a burst of typing or ticking settle first.
                try? await Task.sleep(for: .seconds(0.6))
                guard !Task.isCancelled else { return }
                SharedCategorySync.sync(tasks: tasks, customs: customs, in: context, today: appState.today)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
