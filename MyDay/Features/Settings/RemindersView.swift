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
    /// More times for each, after the first ("64800,72000").
    @AppStorage(Prefs.morningExtraTimes) private var morningExtras = ""
    @AppStorage(Prefs.eveningExtraTimes) private var eveningExtras = ""
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
                    moreTimes($morningExtras, after: morningTime)
                }
            } header: {
                Text("Morning")
            }

            Section {
                Toggle(isOn: $eveningOn.animation()) {
                    Label("Write in my journal", systemImage: "moon.stars.fill")
                }
                if eveningOn {
                    DatePicker("Time", selection: timeBinding($eveningTime), displayedComponents: .hourAndMinute)
                    moreTimes($eveningExtras, after: eveningTime)
                }
            } header: {
                Text("Evening")
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
        .onChange(of: morningExtras) { _, _ in syncDaily() }
        .onChange(of: eveningExtras) { _, _ in syncDaily() }
    }

    // MARK: More times

    /// The reminder's other times ("Time 2", "Time 3"…, each with − to remove it), and
    /// "＋ Add another time" while there is room.
    @ViewBuilder
    private func moreTimes(_ stored: Binding<String>, after first: Double) -> some View {
        let times = Self.times(stored.wrappedValue)
        ForEach(times.indices, id: \.self) { index in
            HStack(spacing: 10) {
                Button {
                    var all = times
                    all.remove(at: index)
                    withAnimation { stored.wrappedValue = Self.text(all) }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.red.opacity(0.85))
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Remove time \(index + 2)")
                DatePicker("Time \(index + 2)", selection: Binding(
                    get: { Self.date(times[index]) },
                    set: { date in
                        var all = times
                        all[index] = Self.seconds(date)
                        stored.wrappedValue = Self.text(all)
                    }
                ), displayedComponents: .hourAndMinute)
            }
        }
        if times.count + 1 < ReminderCenter.maxDailyTimes {
            Button {
                // Two hours after the latest time, wrapping round midnight.
                let latest = ([first] + times).max() ?? first
                let next = (latest + 2 * 3600).truncatingRemainder(dividingBy: 24 * 3600)
                withAnimation { stored.wrappedValue = Self.text(times + [next]) }
                Haptics.tap()
            } label: {
                Label("Add another time", systemImage: "plus.circle.fill")
                    .font(.rounded(.body, weight: .semibold))
                    .foregroundStyle(Palette.hotPink)
            }
        }
    }

    private static func times(_ text: String) -> [Double] {
        text.split(separator: ",").compactMap { Double($0) }
    }

    private static func text(_ times: [Double]) -> String {
        times.map { String(Int($0)) }.joined(separator: ",")
    }

    private static func date(_ seconds: Double) -> Date {
        let minutes = Int(seconds) / 60
        return Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: .now) ?? .now
    }

    private static func seconds(_ date: Date) -> Double {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return Double((parts.hour ?? 0) * 3600 + (parts.minute ?? 0) * 60)
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
        ReminderCenter.scheduleDaily(.morning, enabled: morningOn, times: [morningTime] + Self.times(morningExtras))
        ReminderCenter.scheduleDaily(.evening, enabled: eveningOn, times: [eveningTime] + Self.times(eveningExtras))
    }

    private func refreshStatus() async {
        status = await ReminderCenter.authorizationStatus()
    }
}
