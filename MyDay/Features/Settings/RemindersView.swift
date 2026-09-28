import SwiftUI
import SwiftData
import UserNotifications

/// Morning and evening nudges, plus the list of upcoming to-do reminders.
struct RemindersView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage(Prefs.morningOn) private var morningOn = false
    @AppStorage(Prefs.morningTime) private var morningTime = 8.0 * 3600
    @AppStorage(Prefs.eveningOn) private var eveningOn = false
    @AppStorage(Prefs.eveningTime) private var eveningTime = 21.0 * 3600
    @Query(filter: #Predicate<TaskItem> { $0.isCompleted == false && $0.reminderEnabled == true })
    private var remindedTasks: [TaskItem]
    @State private var status: UNAuthorizationStatus = .notDetermined
    var showsDoneButton = false

    private var upcoming: [TaskItem] {
        let now = Date()
        return remindedTasks
            .filter { ($0.reminderDate ?? .distantPast) > now }
            .sorted { ($0.reminderDate ?? .distantFuture) < ($1.reminderDate ?? .distantFuture) }
    }

    var body: some View {
        Form {
            if status == .denied {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notifications are turned off", systemImage: "bell.slash.fill")
                            .font(.rounded(.headline, weight: .bold))
                            .foregroundStyle(Palette.hotPink)
                        Text("Turn them on in the Settings app so My Day can remind you.")
                            .font(.rounded(.subheadline))
                            .foregroundStyle(Palette.inkSoft)
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                openURL(url)
                            }
                        }
                        .fontWeight(.bold)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                Toggle(isOn: $morningOn.animation()) {
                    Label("Plan my day", systemImage: "sun.max.fill")
                }
                if morningOn {
                    DatePicker("Time", selection: timeBinding($morningTime), displayedComponents: .hourAndMinute)
                }
            } header: {
                Text("Morning")
            } footer: {
                Text("A cheerful nudge to plan your to-dos and choose today's priority.")
            }

            Section {
                Toggle(isOn: $eveningOn.animation()) {
                    Label("Write in my journal", systemImage: "moon.stars.fill")
                }
                if eveningOn {
                    DatePicker("Time", selection: timeBinding($eveningTime), displayedComponents: .hourAndMinute)
                }
            } header: {
                Text("Evening")
            } footer: {
                Text("A soft reminder to capture the day's thoughts and beautiful moments.")
            }

            Section("Upcoming to-do reminders") {
                if upcoming.isEmpty {
                    Text("No upcoming reminders. Add one from any to-do. 🔔")
                        .font(.rounded(.subheadline))
                        .foregroundStyle(Palette.inkSoft)
                } else {
                    ForEach(upcoming) { task in
                        HStack(spacing: 10) {
                            Image(systemName: task.choice.symbol)
                                .foregroundStyle(task.choice.color)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(.rounded(.body, weight: .semibold))
                                    .foregroundStyle(Palette.ink)
                                if let when = task.reminderDate {
                                    Text(when.formatted(.dateTime.weekday(.wide).hour().minute()))
                                        .font(.rounded(.caption, weight: .semibold))
                                        .foregroundStyle(Palette.hotPink)
                                }
                            }
                            Spacer()
                            if task.repeatOption != .never {
                                Image(systemName: "repeat")
                                    .foregroundStyle(Palette.inkSoft)
                                    .accessibilityLabel(task.repeatOption.label)
                            }
                        }
                        .swipeActions {
                            Button("Remove", role: .destructive) {
                                task.reminderEnabled = false
                                ReminderCenter.sync(task)
                            }
                        }
                    }
                }
            }
        }
        .font(.rounded(.body))
        .scrollContentBackground(.hidden)
        .tabBarSafeArea()
        .background(DreamyBackground(theme: .garden))
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsDoneButton {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
        .task { await refreshStatus() }
        .onChange(of: morningOn) { _, isOn in reminderSwitched(isOn) }
        .onChange(of: eveningOn) { _, isOn in reminderSwitched(isOn) }
        .onChange(of: morningTime) { _, _ in syncDaily() }
        .onChange(of: eveningTime) { _, _ in syncDaily() }
    }

    private func timeBinding(_ seconds: Binding<Double>) -> Binding<Date> {
        Binding(
            get: {
                let minutes = Int(seconds.wrappedValue) / 60
                return Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60,
                                             second: 0, of: .now) ?? .now
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                seconds.wrappedValue = Double((parts.hour ?? 0) * 3600 + (parts.minute ?? 0) * 60)
            }
        )
    }

    /// Switching a reminder on is the moment we ask for notification permission.
    private func reminderSwitched(_ isOn: Bool) {
        guard isOn else {
            syncDaily()
            return
        }
        Task {
            _ = await ReminderCenter.requestPermission()
            await refreshStatus()
            syncDaily()
        }
    }

    private func syncDaily() {
        ReminderCenter.scheduleDaily(.morning, enabled: morningOn, secondsFromMidnight: morningTime)
        ReminderCenter.scheduleDaily(.evening, enabled: eveningOn, secondsFromMidnight: eveningTime)
    }

    private func refreshStatus() async {
        status = await ReminderCenter.authorizationStatus()
    }
}
