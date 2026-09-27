import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(Router.self) private var router
    @Environment(AppState.self) private var appState
    @AppStorage(Prefs.userName) private var userName = ""
    @AppStorage(Prefs.carryOver) private var carryOver = true
    @AppStorage(Prefs.showCompleted) private var showCompleted = true
    @AppStorage(Prefs.haptics) private var haptics = true
    @AppStorage(Prefs.journalLock) private var journalLock = false
    @State private var lockMessage: String?
    @State private var confirmClearDone = false
    @State private var confirmEraseAll = false

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 10) {
                    HeroBanner(height: 150)
                    Text("My Day")
                        .font(.rounded(.title, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                    Text("To-Do & Journal 💖")
                        .font(.rounded(.subheadline, weight: .semibold))
                        .foregroundStyle(Palette.hotPink)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .listRowBackground(Color.clear)

            Section("About you") {
                TextField("Your name", text: $userName)
                    .textContentType(.givenName)
                    .submitLabel(.done)
            }

            Section("Reminders") {
                NavigationLink {
                    RemindersView()
                } label: {
                    Label("Daily reminders", systemImage: "bell.badge.fill")
                }
            }

            Section("To-Dos") {
                Toggle(isOn: $carryOver) {
                    Label("Move unfinished items to today", systemImage: "arrow.uturn.forward.circle.fill")
                }
                Toggle(isOn: $showCompleted) {
                    Label("Show finished to-dos", systemImage: "checkmark.circle.fill")
                }
                Toggle(isOn: $haptics) {
                    Label("Gentle haptics", systemImage: "hand.tap.fill")
                }
            }

            Section {
                Toggle(isOn: lockBinding) {
                    Label("Lock with \(JournalLock.methodName)", systemImage: JournalLock.symbolName)
                }
            } header: {
                Text("Journal")
            } footer: {
                Text("Your journal asks for \(JournalLock.methodName) each time you come back to the app.")
            }

            Section("Your data") {
                Button {
                    confirmClearDone = true
                } label: {
                    Label("Clear finished items", systemImage: "checkmark.circle.badge.xmark")
                }
                Button(role: .destructive) {
                    confirmEraseAll = true
                } label: {
                    Label("Erase everything", systemImage: "trash")
                        .foregroundStyle(Color.red)
                }
            }

            Section {
                LabeledContent("Version", value: version)
                LabeledContent("Made with", value: "💖 for beautiful days")
            }
        }
        .font(.rounded(.body))
        .scrollContentBackground(.hidden)
        .tabBarSafeArea()
        .background(DreamyBackground(theme: .garden))
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Journal lock", isPresented: lockAlertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(lockMessage ?? "")
        }
        .confirmationDialog("Clear finished to-dos and priorities?", isPresented: $confirmClearDone, titleVisibility: .visible) {
            Button("Clear finished items", role: .destructive, action: clearFinished)
        }
        .confirmationDialog("Erase all to-dos, priorities and journal pages?", isPresented: $confirmEraseAll,
                            titleVisibility: .visible) {
            Button("Erase everything", role: .destructive, action: eraseAll)
        } message: {
            Text("This can't be undone.")
        }
    }

    // MARK: Journal lock

    private var lockBinding: Binding<Bool> {
        Binding(
            get: { journalLock },
            set: { newValue in
                guard JournalLock.canAuthenticate else {
                    lockMessage = "Please set up a passcode, Face ID or Touch ID on your iPhone first."
                    return
                }
                Task {
                    let reason = newValue ? "Lock your journal" : "Turn off the journal lock"
                    if await JournalLock.authenticate(reason: reason) {
                        journalLock = newValue
                        appState.isJournalUnlocked = true
                    }
                }
            }
        )
    }

    private var lockAlertBinding: Binding<Bool> {
        Binding(get: { lockMessage != nil }, set: { if !$0 { lockMessage = nil } })
    }

    // MARK: Data

    private func clearFinished() {
        router.homePath = NavigationPath()
        router.calendarPath = NavigationPath()
        let finished = (try? context.fetch(FetchDescriptor<TaskItem>(predicate: #Predicate { $0.isCompleted == true }))) ?? []
        for task in finished {
            TaskActions.delete(task, in: context)
        }
        let finishedPriorities = (try? context.fetch(
            FetchDescriptor<Priority>(predicate: #Predicate { $0.isCompleted == true }))) ?? []
        for priority in finishedPriorities {
            context.delete(priority)
        }
        Haptics.success()
    }

    private func eraseAll() {
        // Leave any open page first, so nothing on screen shows a deleted item.
        router.homePath = NavigationPath()
        router.calendarPath = NavigationPath()

        let allTasks = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        for task in allTasks {
            TaskActions.delete(task, in: context)
        }
        let allPriorities = (try? context.fetch(FetchDescriptor<Priority>())) ?? []
        for priority in allPriorities {
            context.delete(priority)
        }
        let allEntries = (try? context.fetch(FetchDescriptor<JournalEntry>())) ?? []
        for entry in allEntries {
            context.delete(entry)
        }
        try? context.save()
        Haptics.success()
    }
}
