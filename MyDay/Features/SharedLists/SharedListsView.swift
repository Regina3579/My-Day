import CloudKit
import CoreTransferable
import SwiftData
import SwiftUI

// MARK: - All the lists

/// Shared Lists, from the side menu: lists made together with family and friends (Groceries,
/// Family To-Dos…). The person's own lists come first, then the ones shared with them.
struct SharedListsView: View {
    @Environment(Router.self) private var router
    @Environment(MyDayPro.self) private var pro
    @Environment(\.hostTab) private var hostTab
    @State private var isMaking = false
    @State private var proOffer: ProFeature?

    private let store = SharedListStore.shared

    private var mine: [SharedList] { store.lists.filter(\.isMine).sorted { $0.createdAt < $1.createdAt } }
    private var shared: [SharedList] { store.lists.filter { !$0.isMine }.sorted { $0.createdAt < $1.createdAt } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                intro
                if store.hasICloudAccount == false {
                    SharedListNote(symbol: "icloud.slash",
                                   text: "Sign in to iCloud in the Settings app to share lists. Your lists stay on this iPhone until then.")
                }
                if let problem = store.problem {
                    SharedListNote(symbol: "exclamationmark.triangle", text: problem)
                        .onTapGesture { store.problem = nil }
                }
                if store.lists.isEmpty {
                    emptyState
                } else {
                    if !mine.isEmpty { section("My Lists", mine) }
                    if !shared.isEmpty { section("Shared with Me", shared) }
                }
                Button(action: makeList) {
                    Label("New Shared List", systemImage: "plus")
                }
                .buttonStyle(PillButtonStyle())
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .refreshable { await store.refresh() }
        .background(SharedListBackground())
        .navigationTitle("Shared Lists")
        .navigationBarTitleDisplayMode(.inline)
        .tabBarSafeArea()
        .sheet(isPresented: $isMaking) {
            NewSharedListSheet { list in
                router.push(.sharedList(list.id), in: hostTab)
            }
        }
        .proOffer($proOffer)
        .task { await store.refresh() }
    }

    private var intro: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("💞")
                .font(.system(size: 40))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("Lists made together")
                    .font(.rounded(.title3, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                Text("Share groceries, chores or a trip with family and friends. Everyone sees every tick, right away.")
                    .font(.rounded(.subheadline, weight: .medium))
                    .foregroundStyle(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.white.opacity(0.8)))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("🛒 🏡 ✈️")
                .font(.system(size: 34))
            Text("No shared lists yet")
                .font(.rounded(.headline, weight: .bold))
                .foregroundStyle(Palette.ink)
            Text("Make one, then tap 👥 to invite people by message, email or link.")
                .font(.rounded(.subheadline, weight: .medium))
                .foregroundStyle(Palette.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }

    private func section(_ title: String, _ lists: [SharedList]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.rounded(.subheadline, weight: .heavy))
                .foregroundStyle(Palette.berry)
                .textCase(.uppercase)
            ForEach(lists) { list in
                Button {
                    router.push(.sharedList(list.id), in: hostTab)
                } label: {
                    SharedListCard(list: list)
                }
                .buttonStyle(PressScaleStyle(scale: 0.97))
            }
        }
    }

    private func makeList() {
        if store.canMakeList(isPro: pro.isActive) {
            isMaking = true
        } else {
            proOffer = .sharedLists
        }
    }
}

/// A list on Shared Lists: its emoji, name, how much is done, and who shares it.
struct SharedListCard: View {
    let list: SharedList

    var body: some View {
        HStack(spacing: 14) {
            EmojiArt(emoji: list.emoji, size: 30)
                .frame(width: 54, height: 54)
                .background(Circle().fill(Palette.blush))
            VStack(alignment: .leading, spacing: 4) {
                Text(list.name.isEmpty ? "Shared list" : list.name)
                    .font(.rounded(.headline, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                Text(summary)
                    .font(.rounded(.caption, weight: .semibold))
                    .foregroundStyle(Palette.inkSoft)
                ProgressView(value: Double(list.doneCount), total: Double(max(1, list.items.count)))
                    .tint(Palette.hotPink)
            }
            Spacer(minLength: 4)
            if list.memberCount > 1 {
                Label("\(list.memberCount)", systemImage: "person.2.fill")
                    .font(.rounded(.caption, weight: .bold))
                    .foregroundStyle(Palette.grape)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Palette.lilac))
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Palette.inkSoft.opacity(0.5))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.white))
        .shadow(color: Palette.hotPink.opacity(0.08), radius: 8, x: 0, y: 3)
        .accessibilityElement(children: .combine)
    }

    private var summary: String {
        let done = "\(list.doneCount) of \(list.items.count) done"
        return list.isMine || list.sharedBy.isEmpty ? done : "From \(list.sharedBy) · \(done)"
    }
}

// MARK: - One list

/// A shared list, like the Groceries list in the design: its name with its emoji, the people in
/// it (👥), each item with a circle to tick and a ☆, ticked items under Completed, and a field
/// to add more. Every change reaches everyone in the list through iCloud.
struct SharedListView: View {
    let listID: String

    @Environment(\.dismiss) private var dismiss
    @AppStorage(Prefs.showCompleted) private var showCompleted = true
    @State private var newItem = ""
    @State private var showsMembers = false
    @State private var isRenaming = false
    @State private var confirmRemove = false
    @FocusState private var addFocused: Bool

    private let store = SharedListStore.shared

    var body: some View {
        Group {
            if let list = store.list(listID) {
                content(list)
            } else {
                VStack(spacing: 10) {
                    Text("💌").font(.system(size: 44))
                    Text("This list isn't shared with you any more.")
                        .font(.rounded(.headline, weight: .bold))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                }
                .padding(30)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(SharedListBackground())
        .navigationBarTitleDisplayMode(.inline)
        .tabBarSafeArea()
        .task {
            #if DEBUG
            if DebugLaunchRoute.takeSharedListMembers() {
                try? await Task.sleep(for: .seconds(0.6))
                showsMembers = true
            }
            #endif
            await store.refresh()
        }
    }

    private func content(_ list: SharedList) -> some View {
        let open = list.sortedItems.filter { !$0.isDone }.sorted { $0.isImportant && !$1.isImportant }
        let done = list.sortedItems.filter(\.isDone)
        return List {
            Section {
                header(list)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 8, trailing: 20))
                ForEach(open) { item in
                    itemRow(item, in: list)
                }
                if open.isEmpty && !list.items.isEmpty {
                    Text("All done! 🎉")
                        .font(.rounded(.headline, weight: .bold))
                        .foregroundStyle(Palette.berry)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                if !done.isEmpty {
                    Button {
                        withAnimation(.snappy) { showCompleted.toggle() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: showCompleted ? "chevron.down" : "chevron.right")
                            Text("Completed \(done.count)")
                        }
                        .font(.rounded(.subheadline, weight: .bold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Palette.grape.gradient))
                    }
                    .buttonStyle(PressScaleStyle())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    if showCompleted {
                        ForEach(done) { item in
                            itemRow(item, in: list)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .refreshable { await store.refresh() }
        .safeAreaInset(edge: .bottom, spacing: 0) { addBar(list) }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showsMembers = true
                } label: {
                    Label("\(list.memberCount)", systemImage: "person.2")
                        .labelStyle(.titleAndIcon)
                }
                .accessibilityLabel("Share List, \(list.memberCount) \(list.memberCount == 1 ? "member" : "members")")
                Menu {
                    Button("Share List", systemImage: "person.badge.plus") { showsMembers = true }
                    if list.isMine {
                        Button("Rename List", systemImage: "pencil") { isRenaming = true }
                        Button("Delete List", systemImage: "trash", role: .destructive) { confirmRemove = true }
                    } else {
                        Button("Leave List", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                            confirmRemove = true
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("More")
            }
        }
        .sheet(isPresented: $showsMembers) {
            ShareListSheet(listID: list.id)
        }
        .sheet(isPresented: $isRenaming) {
            NewSharedListSheet(editing: list) { _ in }
        }
        .confirmationDialog(list.isMine ? "Delete “\(list.name)”?" : "Leave “\(list.name)”?",
                            isPresented: $confirmRemove, titleVisibility: .visible) {
            Button(list.isMine ? "Delete for Everyone" : "Leave List", role: .destructive) {
                store.removeList(list.id)
                dismiss()
            }
        } message: {
            Text(list.isMine
                 ? "The list goes from your My Day and from everyone you shared it with."
                 : "The list goes from your My Day. It stays for the others.")
        }
    }

    private func header(_ list: SharedList) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Text(list.name.isEmpty ? "Shared list" : list.name)
                    .font(.rounded(size: 34, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                EmojiArt(emoji: list.emoji, size: 34)
                    .accessibilityHidden(true)
            }
            Text(list.isMine ? "\(list.doneCount) of \(list.items.count) done"
                 : "Shared by \(list.sharedBy.isEmpty ? "a friend" : list.sharedBy) · \(list.doneCount) of \(list.items.count) done")
                .font(.rounded(.subheadline, weight: .semibold))
                .foregroundStyle(Palette.inkSoft)
        }
    }

    private func itemRow(_ item: SharedItem, in list: SharedList) -> some View {
        HStack(spacing: 14) {
            Button {
                withAnimation(.snappy) {
                    store.update(item.id, in: list.id) { $0.isDone.toggle() }
                }
                if !item.isDone { Haptics.success() } else { Haptics.tap() }
            } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(item.isDone ? Palette.hotPink : Palette.inkSoft.opacity(0.6))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isDone ? "Mark not done" : "Mark done")

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.rounded(.body, weight: .semibold))
                    .foregroundStyle(item.isDone ? Palette.inkSoft : Palette.ink)
                    .strikethrough(item.isDone, color: Palette.inkSoft)
                if !item.addedBy.isEmpty, list.memberCount > 1 {
                    Text("Added by \(item.addedBy)")
                        .font(.rounded(.caption2, weight: .medium))
                        .foregroundStyle(Palette.inkSoft.opacity(0.8))
                }
            }
            Spacer(minLength: 4)

            Button {
                store.update(item.id, in: list.id) { $0.isImportant.toggle() }
                Haptics.tap()
            } label: {
                Image(systemName: item.isImportant ? "star.fill" : "star")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(item.isImportant ? Palette.honey : Palette.inkSoft.opacity(0.5))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isImportant ? "Not important" : "Important")
        }
        .padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .swipeActions(edge: .trailing) {
            Button("Delete", systemImage: "trash", role: .destructive) {
                withAnimation { store.deleteItem(item.id, from: list.id) }
            }
        }
    }

    private func addBar(_ list: SharedList) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Palette.hotPink)
            TextField("Add an item", text: $newItem)
                .font(.rounded(.body, weight: .semibold))
                .focused($addFocused)
                .submitLabel(.done)
                .onSubmit { add(to: list) }
            if !newItem.trimmed.isEmpty {
                Button("Add") { add(to: list) }
                    .font(.rounded(.subheadline, weight: .bold))
                    .foregroundStyle(Palette.hotPink)
            }
        }
        .padding(.horizontal, 18)
        .frame(minHeight: 52)
        .background(Capsule().fill(Color.white))
        .overlay(Capsule().strokeBorder(Palette.bubblegum.opacity(addFocused ? 0.6 : 0.25), lineWidth: 1.5))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func add(to list: SharedList) {
        let title = newItem.trimmed
        guard !title.isEmpty else { return }
        withAnimation(.snappy) { store.addItem(title, to: list.id) }
        newItem = ""
        addFocused = true
        Haptics.tap()
    }
}

// MARK: - New list

/// New Shared List (or Rename): a name, an emoji, and, for a new list, a template to start from.
struct NewSharedListSheet: View {
    var editing: SharedList?
    let onDone: (SharedList) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\TaskTemplate.sortOrder), SortDescriptor(\TaskTemplate.createdAt)])
    private var templates: [TaskTemplate]
    @State private var name = ""
    @State private var emoji = "🛒"
    @State private var items: [String] = []
    @State private var templateName = ""
    @FocusState private var nameFocused: Bool

    private static let emojis = ["🛒", "🏡", "✈️", "🎁", "🍳", "🧹", "🐶", "💖", "🎉", "📚", "🌸", "🧺", "💊", "🎒", "🌱", "📝"]

    init(editing: SharedList? = nil, onDone: @escaping (SharedList) -> Void) {
        self.editing = editing
        self.onDone = onDone
        _name = State(initialValue: editing?.name ?? "")
        _emoji = State(initialValue: editing?.emoji ?? "🛒")
    }

    private var canSave: Bool { !name.trimmed.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        SheetLabel(text: "Name")
                        TextField("Groceries, Family To-Dos…", text: $name)
                            .font(.rounded(.title3, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                            .focused($nameFocused)
                            .submitLabel(.done)
                            .onSubmit { if canSave { save() } }
                            .padding(.horizontal, 16)
                            .frame(minHeight: 52)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white))
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        SheetLabel(text: "Emoji")
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 8), spacing: 6) {
                            ForEach(Self.emojis, id: \.self) { option in
                                Button {
                                    emoji = option
                                    Haptics.tap()
                                } label: {
                                    Text(option)
                                        .font(.system(size: 22))
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(option == emoji ? Palette.blush : Color.white.opacity(0.8)))
                                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(option == emoji ? Palette.hotPink : Color.clear, lineWidth: 2))
                                }
                                .buttonStyle(PressScaleStyle())
                                .accessibilityLabel(option)
                            }
                        }
                    }
                    if editing == nil && !templates.isEmpty {
                        templatePicker
                    }
                }
                .padding(20)
            }
            .navigationTitle(editing == nil ? "New Shared List" : "Rename List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editing == nil ? "Make" : "Save", action: save)
                        .fontWeight(.bold)
                        .disabled(!canSave)
                }
            }
            .task {
                await Opening.settle()
                nameFocused = true
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .presentationBackground(Color(hex: 0xFFF5F9))
    }

    /// Start from one of the person's templates: its name, emoji and to-dos.
    private var templatePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            SheetLabel(text: "Start from a template")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(templates, id: \.persistentModelID) { template in
                        let isOn = templateName == template.name
                        Button {
                            if isOn {
                                templateName = ""
                                items = []
                            } else {
                                templateName = template.name
                                name = template.name
                                emoji = template.emoji
                                items = template.items
                            }
                            Haptics.tap()
                        } label: {
                            HStack(spacing: 6) {
                                EmojiArt(emoji: template.emoji, size: 18)
                                Text(template.name)
                                    .font(.rounded(.subheadline, weight: .bold))
                                    .foregroundStyle(Palette.ink)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .frame(minHeight: 40)
                            .background(Capsule().fill(isOn ? Palette.blush : Color.white))
                            .overlay(Capsule().strokeBorder(isOn ? Palette.hotPink : Color.clear, lineWidth: 2))
                        }
                        .buttonStyle(PressScaleStyle())
                    }
                }
            }
            if !items.isEmpty {
                Text("\(items.count) items from “\(templateName)” will be on the list.")
                    .font(.rounded(.caption, weight: .semibold))
                    .foregroundStyle(Palette.inkSoft)
            }
        }
    }

    private func save() {
        guard canSave else { return }
        let store = SharedListStore.shared
        if let editing {
            store.rename(editing.id, name: name.trimmed, emoji: emoji)
            onDone(editing)
        } else {
            onDone(store.makeList(name: name.trimmed, emoji: emoji, items: items))
        }
        Haptics.success()
        dismiss()
    }
}

// MARK: - Share List

/// Share List, as in the design: the list's members (the owner marked Owner, others with ✕ for
/// the owner to take them out), Invite People (Messages, Mail, a link…) and the share button.
/// Whoever opens the invitation joins the list in their own My Day.
struct ShareListSheet: View {
    let listID: String

    @Environment(\.dismiss) private var dismiss
    @State private var share: CKShare?
    @State private var members: [SharedListMember] = []
    @State private var isLoading = true
    @State private var problem: String?
    @State private var confirmStop = false

    private let store = SharedListStore.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    Section {
                        if isLoading {
                            HStack {
                                ProgressView()
                                Text("Loading members…")
                                    .foregroundStyle(Palette.inkSoft)
                            }
                        } else {
                            ForEach(members) { member in
                                memberRow(member)
                            }
                        }
                    } header: {
                        Text("List members")
                            .font(.rounded(.subheadline, weight: .bold))
                            .foregroundStyle(Palette.ink)
                            .textCase(nil)
                    }
                    if let problem {
                        Text(problem)
                            .font(.rounded(.footnote, weight: .medium))
                            .foregroundStyle(Color(hex: 0xC2185B))
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)

                inviteArea
            }
            .background(Color(hex: 0xFFF5F9).ignoresSafeArea())
            .navigationTitle("Share List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
            .task { await load() }
            .confirmationDialog("Stop sharing this list?", isPresented: $confirmStop, titleVisibility: .visible) {
                Button("Stop Sharing", role: .destructive) {
                    Task {
                        try? await store.stopSharing(listID)
                        share = nil
                        await load()
                    }
                }
            } message: {
                Text("Everyone else loses the list. It stays in your My Day.")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    private var list: SharedList? { store.list(listID) }

    private func memberRow(_ member: SharedListMember) -> some View {
        HStack(spacing: 14) {
            Text(Self.initials(member.name))
                .font(.rounded(.subheadline, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Self.color(for: member.name).gradient))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(member.isMe ? "\(member.name) (You)" : member.name)
                    .font(.rounded(.body, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                if !member.detail.isEmpty {
                    Text(member.detail)
                        .font(.rounded(.caption, weight: .medium))
                        .foregroundStyle(Palette.inkSoft)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            if member.isOwner {
                Text("Owner")
                    .font(.rounded(.subheadline, weight: .medium))
                    .foregroundStyle(Palette.inkSoft)
            } else if member.isPending {
                Text("Invited")
                    .font(.rounded(.subheadline, weight: .medium))
                    .foregroundStyle(Palette.inkSoft)
            }
            if list?.isMine == true, !member.isOwner, let participant = member.participant {
                Button {
                    remove(participant)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.inkSoft)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(member.name)")
            }
        }
        .listRowBackground(Color.white)
    }

    @ViewBuilder
    private var inviteArea: some View {
        if let list {
            VStack(spacing: 14) {
                if list.isMine {
                    HStack(spacing: 12) {
                        if Self.canMakeInvitations {
                            ShareLink(item: SharedListInvite(listID: list.id, existing: share),
                                      preview: SharePreview("\(list.name) \(list.emoji)")) {
                                inviteLabel
                            }
                            ShareLink(item: SharedListInvite(listID: list.id, existing: share),
                                      preview: SharePreview("\(list.name) \(list.emoji)")) {
                                shareIconLabel
                            }
                            .accessibilityLabel("Share invitation link")
                        } else {
                            inviteLabel
                            shareIconLabel
                        }
                    }
                    Text("People you invite can see and edit this list. They need My Day and an iCloud account.")
                        .font(.rounded(.footnote, weight: .medium))
                        .foregroundStyle(Palette.inkSoft)
                        .multilineTextAlignment(.center)
                    if share != nil, members.count > 1 {
                        Button("Stop Sharing", role: .destructive) { confirmStop = true }
                            .font(.rounded(.subheadline, weight: .bold))
                    }
                } else {
                    Text("\(list.sharedBy.isEmpty ? "The owner" : list.sharedBy) shared this list with you. Only the owner can invite people.")
                        .font(.rounded(.footnote, weight: .medium))
                        .foregroundStyle(Palette.inkSoft)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }

    /// The invitation link needs iCloud (CloudKit): screenshot runs, built without the
    /// iCloud entitlement, show the buttons only.
    private static var canMakeInvitations: Bool {
        #if DEBUG
        return !DebugLaunchRoute.isScreenshotRun
        #else
        return true
        #endif
    }

    private var inviteLabel: some View {
        Text("Invite People")
            .font(.rounded(.headline, weight: .bold))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0xFF5FA8), Palette.hotPink],
                                     startPoint: .top, endPoint: .bottom)))
    }

    private var shareIconLabel: some View {
        Image(systemName: "square.and.arrow.up")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(Palette.hotPink)
            .frame(width: 54, height: 54)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white))
    }

    private func load() async {
        defer { isLoading = false }
        #if DEBUG
        if DebugLaunchRoute.isScreenshotRun {
            members = [
                SharedListMember(id: "1", name: "Reggie", detail: "reggie@icloud.com", isOwner: true, isMe: true,
                                 isPending: false, participant: nil),
                SharedListMember(id: "2", name: "Joseph", detail: "", isOwner: false, isMe: false,
                                 isPending: false, participant: nil),
            ]
            return
        }
        #endif
        guard let list else { return }
        do {
            share = try await store.existingShare(for: list)
            if let share {
                members = store.members(of: share)
            } else {
                members = [SharedListMember(id: "me", name: Self.myName, detail: "", isOwner: true, isMe: true,
                                            isPending: false, participant: nil)]
            }
            problem = nil
        } catch {
            problem = "Couldn't reach iCloud. Check your connection and that you're signed in to iCloud."
            members = [SharedListMember(id: "me", name: Self.myName, detail: "", isOwner: list.isMine, isMe: true,
                                        isPending: false, participant: nil)]
        }
    }

    private func remove(_ participant: CKShare.Participant) {
        guard let share else { return }
        Task {
            do {
                let saved = try await store.remove(participant, from: share)
                self.share = saved
                members = store.members(of: saved)
                Haptics.tap()
            } catch {
                problem = "Couldn't remove them just now. Please try again."
            }
        }
    }

    private static var myName: String {
        let name = UserDefaults.standard.string(forKey: Prefs.userName) ?? ""
        return name.isEmpty ? "You" : name
    }

    static func initials(_ name: String) -> String {
        let words = name.split { $0 == " " || $0 == "@" || $0 == "." }.prefix(2)
        let letters = words.compactMap(\.first).map { String($0).uppercased() }.joined()
        return letters.isEmpty ? "♥︎" : letters
    }

    static func color(for name: String) -> Color {
        let colors = [Color(hex: 0x1F8A8A), Color(hex: 0x8E2C6B), Palette.grape, Palette.hotPink, Color(hex: 0x3D7BD9)]
        let sum = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return colors[sum % colors.count]
    }
}

/// What Invite People shares: CloudKit's invitation to the list (made the first time).
struct SharedListInvite: Transferable, @unchecked Sendable {
    let listID: String
    let existing: CKShare?

    static var transferRepresentation: some TransferRepresentation {
        CKShareTransferRepresentation { invite in
            if let share = invite.existing {
                return .existing(share, container: SharedListCloud.container)
            }
            let listID = invite.listID
            return .prepareShare(container: SharedListCloud.container) {
                try await SharedListStore.shared.share(for: listID)
            }
        }
    }
}

// MARK: - Little pieces

/// A soft note on Shared Lists (no iCloud account, something went wrong).
struct SharedListNote: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(Palette.hotPink)
            Text(text)
                .font(.rounded(.footnote, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Palette.blush))
    }
}

/// The pages' soft pink background.
struct SharedListBackground: View {
    var body: some View {
        LinearGradient(colors: [Color(hex: 0xFFF4F8), Color(hex: 0xFDE7F1), Color(hex: 0xF3ECFF)],
                       startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}
