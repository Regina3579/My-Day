import SwiftUI
import SwiftData

// MARK: - The badges

/// The 40 badges from the two Achievements designs, in their order. Each picture is the design's
/// own (enlarged 4× with Real-ESRGAN, its label taken off): the words are drawn here.
enum Achievement: String, CaseIterable, Identifiable, Codable {
    case taskStarter, firstDay, streak7, streak30
    case risingStar, streakQueen, healthyYou, sweetDreams
    case shoppingSpree, beautyLover, homeHero, moneyWise
    case onTheMove, foodieFun, cleaningStar, entertainmentPro
    case positiveVibes, meTime, smartPlanner, focusChampion
    case firstGoal, goalMaster, consistencyQueen, ourHero
    case selfCareChamp, waterHero, productiveDay, learningBuddy
    case travelExplorer, petLover, socialButterfly, eventPlanner
    case creativeSoul, projectPro, appointmentKeeper, playingSafe
    case whatAWeek, whatAYear, nightOwl, earlyBird

    var id: String { rawValue }

    /// "Achievements/TaskStarter" and so on.
    var art: String { "Achievements/" + rawValue.prefix(1).uppercased() + rawValue.dropFirst() }

    /// The badge's name, as on its label.
    var title: String {
        switch self {
        case .taskStarter: "Task Starter"
        case .firstDay: "First Day"
        case .streak7: "7 Day Streak"
        case .streak30: "30 Day Streak"
        case .risingStar: "Rising Star"
        case .streakQueen: "Streak Queen"
        case .healthyYou: "Healthy You"
        case .sweetDreams: "Sweet Dreams"
        case .shoppingSpree: "Shopping Spree"
        case .beautyLover: "Beauty Lover"
        case .homeHero: "Home Hero"
        case .moneyWise: "Money Wise"
        case .onTheMove: "On the Move"
        case .foodieFun: "Foodie Fun"
        case .cleaningStar: "Cleaning Star"
        case .entertainmentPro: "Entertainment Pro"
        case .positiveVibes: "Positive Vibes"
        case .meTime: "Me Time"
        case .smartPlanner: "Smart Planner"
        case .focusChampion: "Focus Champion"
        case .firstGoal: "First Goal"
        case .goalMaster: "Goal Master"
        case .consistencyQueen: "Consistency Queen"
        case .ourHero: "Our Hero"
        case .selfCareChamp: "Self-Care Champ"
        case .waterHero: "Water Hero"
        case .productiveDay: "Productive Day"
        case .learningBuddy: "Learning Buddy"
        case .travelExplorer: "Travel Explorer"
        case .petLover: "Pet Lover"
        case .socialButterfly: "Social Butterfly"
        case .eventPlanner: "Event Planner"
        case .creativeSoul: "Creative Soul"
        case .projectPro: "Project Pro"
        case .appointmentKeeper: "Appointment Keeper"
        case .playingSafe: "Playing Safe"
        case .whatAWeek: "What a Week"
        case .whatAYear: "What a Year"
        case .nightOwl: "Night Owl"
        case .earlyBird: "Early Bird"
        }
    }

    /// The line under the name, as on its label.
    var detail: String {
        switch self {
        case .taskStarter: "Created your first task!"
        case .firstDay: "Welcome! Your journey begins!"
        case .streak7: "Used the app for 7 days in a row!"
        case .streak30: "You're so consistent!"
        case .risingStar: "Completed 10 goals!"
        case .streakQueen: "30 days and counting!"
        case .healthyYou: "Completed 10 fitness goals!"
        case .sweetDreams: "Slept early 5 days in a row!"
        case .shoppingSpree: "Added 10 items to your list!"
        case .beautyLover: "Completed 5 beauty tasks!"
        case .homeHero: "Completed 10 home tasks!"
        case .moneyWise: "Completed 5 finance goals!"
        case .onTheMove: "Completed 5 car/transport tasks!"
        case .foodieFun: "Completed 10 cooking tasks!"
        case .cleaningStar: "Completed 10 cleaning tasks!"
        case .entertainmentPro: "Completed 10 entertainment tasks!"
        case .positiveVibes: "Logged 10 happy days!"
        case .meTime: "Took time for yourself!"
        case .smartPlanner: "Planned 20 tasks ahead!"
        case .focusChampion: "Completed 25 tasks without delay!"
        case .firstGoal: "Completed your first goal!"
        case .goalMaster: "Completed 5 goals in a day!"
        case .consistencyQueen: "Used the app for 30 days!"
        case .ourHero: "Completed 100 tasks total!"
        case .selfCareChamp: "Completed 10 self-care goals!"
        case .waterHero: "Drank water 7 days in a row!"
        case .productiveDay: "Completed 8 tasks today!"
        case .learningBuddy: "Completed 5 learning goals!"
        case .travelExplorer: "Planned a trip!"
        case .petLover: "Completed 5 pet tasks!"
        case .socialButterfly: "Spent time with friends!"
        case .eventPlanner: "Created 5 events!"
        case .creativeSoul: "Completed 5 hobby tasks!"
        case .projectPro: "Completed 10 project tasks!"
        case .appointmentKeeper: "Attended 10 appointments!"
        case .playingSafe: "Completed 10 important tasks!"
        case .whatAWeek: "Completed 50 tasks this week!"
        case .whatAYear: "Completed 200 tasks this year!"
        case .nightOwl: "Completed evening tasks 5 days!"
        case .earlyBird: "Completed morning tasks 5 days!"
        }
    }

    /// The pop-up's big words: the streaks name themselves ("7 Day Streak!"), the rest say
    /// "Congratulations!", as in the two pop-up designs.
    var headline: String {
        switch self {
        case .streak7, .streak30: title + "!"
        default: "Congratulations!"
        }
    }

    /// The line under the headline.
    var subtitle: String {
        switch self {
        case .taskStarter: "You've created your first task!"
        case .firstDay: "Welcome to My Day! Your journey begins! 🌸"
        case .streak7: "You've used the app for 7 days in a row! 🎉"
        case .streak30: "You've used the app for 30 days in a row! 🎉"
        case .risingStar: "You've completed 10 goals!"
        case .streakQueen: "You've written in your journal 30 days in a row!"
        case .healthyYou: "You've completed 10 fitness goals!"
        case .sweetDreams: "You've slept early 5 days in a row!"
        case .shoppingSpree: "You've added 10 items to your list!"
        case .beautyLover: "You've completed 5 beauty tasks!"
        case .homeHero: "You've completed 10 home tasks!"
        case .moneyWise: "You've completed 5 finance goals!"
        case .onTheMove: "You've completed 5 car/transport tasks!"
        case .foodieFun: "You've completed 10 cooking tasks!"
        case .cleaningStar: "You've completed 10 cleaning tasks!"
        case .entertainmentPro: "You've completed 10 entertainment tasks!"
        case .positiveVibes: "You've logged 10 happy days!"
        case .meTime: "You took time for yourself!"
        case .smartPlanner: "You've planned 20 tasks ahead!"
        case .focusChampion: "You've completed 25 tasks without delay!"
        case .firstGoal: "You've completed your first goal!"
        case .goalMaster: "You've completed 5 goals today!"
        case .consistencyQueen: "You've used the app for 30 days!"
        case .ourHero: "You've completed 100 tasks!"
        case .selfCareChamp: "You've completed 10 self-care goals!"
        case .waterHero: "You drank water 7 days in a row!"
        case .productiveDay: "You've completed 8 tasks today!"
        case .learningBuddy: "You've completed 5 learning goals!"
        case .travelExplorer: "You've planned a trip! ✈️"
        case .petLover: "You've completed 5 pet tasks!"
        case .socialButterfly: "You spent time with friends!"
        case .eventPlanner: "You've created 5 events!"
        case .creativeSoul: "You've completed 5 hobby tasks!"
        case .projectPro: "You've completed 10 project tasks!"
        case .appointmentKeeper: "You've attended 10 appointments!"
        case .playingSafe: "You've completed 10 important tasks!"
        case .whatAWeek: "You've completed 50 tasks this week!"
        case .whatAYear: "You've completed 200 tasks this year!"
        case .nightOwl: "You've completed evening tasks on 5 days!"
        case .earlyBird: "You've completed morning tasks on 5 days!"
        }
    }

    /// The name in the pop-up's inner card ("Consistent Cutie" for the 7-day streak, as in its
    /// design; the badge's own name otherwise).
    var cardTitle: String {
        switch self {
        case .streak7: "Consistent Cutie"
        case .streak30: "Unstoppable Sweetie"
        default: title
        }
    }

    /// The cheer in the pop-up's inner card.
    var cheer: String {
        switch self {
        case .streak7: "You showed up for your well-being for 7 days! Keep going, you're doing amazing! 💕"
        case .streak30: "A whole month of showing up for yourself! Keep shining, you're incredible! 💕"
        case .goalMaster: "Amazing! You completed 5 goals in a day. You're doing great! 💕"
        case .firstDay: "This is the start of something lovely. One little step at a time! 💕"
        case .taskStarter: "Every big dream starts with one little task. You've got this! 💕"
        case .ourHero, .whatAYear, .whatAWeek, .productiveDay:
            "Look at you go! All that hard work is paying off. You're amazing! 💕"
        case .meTime, .selfCareChamp, .sweetDreams, .waterHero, .healthyYou:
            "Taking care of you is the best thing you can do. So proud of you! 💕"
        case .streakQueen, .consistencyQueen:
            "Day after day, you keep showing up. You're a true queen! 👑💕"
        default: "Amazing! You're doing great. Keep it up! 💕"
        }
    }

    /// What "Share Good News" sends.
    var shareText: String {
        "I just earned the “\(title)” badge in My Day! \(detail) 💖"
    }
}

// MARK: - Earning them

/// Keeps the badges earned (with when), the days My Day was used, and the badges waiting to pop
/// up. The rules are checked whenever the to-dos or journal pages change, and when the app opens.
@MainActor @Observable
final class AchievementCenter {
    static let shared = AchievementCenter()

    /// Earned badges and when.
    private(set) var earned: [Achievement: Date]
    /// The badge whose pop-up is on screen.
    private(set) var showing: Achievement?
    /// Newly earned badges waiting for their pop-up, one after another.
    private var waiting: [Achievement] = []
    /// A sheet or the menu is open: pop-ups wait until it closes.
    @ObservationIgnored var isScreenBusy: @MainActor () -> Bool = { false }

    @ObservationIgnored private let defaults = UserDefaults.standard

    private init() {
        let stored = UserDefaults.standard.dictionary(forKey: Prefs.achievementsEarned) as? [String: Double] ?? [:]
        earned = Dictionary(uniqueKeysWithValues: stored.compactMap { key, seconds in
            Achievement(rawValue: key).map { ($0, Date(timeIntervalSince1970: seconds)) }
        })
    }

    var earnedCount: Int { earned.count }

    func isEarned(_ achievement: Achievement) -> Bool { earned[achievement] != nil }

    // MARK: Days used

    /// Notes today as a day My Day was used (for the streaks and Consistency Queen).
    func noteUse(on day: Date = .now) {
        var days = Set(defaults.stringArray(forKey: Prefs.achievementDays) ?? [])
        let key = Self.dayKey(day)
        guard !days.contains(key) else { return }
        days.insert(key)
        // A little over a year is plenty for every rule.
        let kept = days.sorted().suffix(400)
        defaults.set(Array(kept), forKey: Prefs.achievementDays)
    }

    private var usedDays: Set<Date> {
        let formatter = Self.dayFormatter
        return Set((defaults.stringArray(forKey: Prefs.achievementDays) ?? []).compactMap(formatter.date(from:)))
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static func dayKey(_ date: Date) -> String { dayFormatter.string(from: date) }

    // MARK: Checking

    /// Checks every rule against the to-dos and journal pages, and pops up the badges just earned.
    /// The very first check (a new install, or the first version with badges) pops up only First
    /// Day: badges already deserved by then are given quietly, so they don't flood the screen.
    func check(tasks: [TaskItem], pages: [JournalEntry]) {
        #if DEBUG
        guard !DebugLaunchRoute.isScreenshotRun else { return }
        #endif
        noteUse()
        let met = AchievementRules(tasks: tasks, pages: pages, usedDays: usedDays).met
        let new = Achievement.allCases.filter { met.contains($0) && earned[$0] == nil }
        guard !new.isEmpty else { return }
        let isFirstCheck = !defaults.bool(forKey: Prefs.achievementsStarted)
        defaults.set(true, forKey: Prefs.achievementsStarted)
        for achievement in new { earned[achievement] = .now }
        save()
        let announced = isFirstCheck ? new.filter { $0 == .firstDay } : new
        waiting.append(contentsOf: announced.filter { !waiting.contains($0) && $0 != showing })
        showNext()
    }

    /// Shows the next waiting pop-up, when nothing else is in the way.
    func showNext() {
        guard showing == nil, !waiting.isEmpty, !isScreenBusy() else { return }
        let next = waiting.removeFirst()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { showing = next }
        Haptics.success()
    }

    /// Closes the pop-up; the next one (if any) follows a moment later.
    func close() {
        withAnimation(.easeOut(duration: 0.25)) { showing = nil }
        guard !waiting.isEmpty else { return }
        Task {
            try? await Task.sleep(for: .seconds(0.7))
            showNext()
        }
    }

    private func save() {
        defaults.set(Dictionary(uniqueKeysWithValues: earned.map { ($0.key.rawValue, $0.value.timeIntervalSince1970) }),
                     forKey: Prefs.achievementsEarned)
    }

    #if DEBUG
    /// Screenshot runs: badges earned without pop-ups, or one pop-up on screen.
    func preview(earned demo: [Achievement], showing badge: Achievement? = nil) {
        earned = Dictionary(uniqueKeysWithValues: demo.map { ($0, Date.now) })
        showing = badge
    }
    #endif
}

/// The rules, as each badge's label says. A to-do counts for a kind (home, cleaning, pets…) by
/// its category's picture or by its own words ("Clean the kitchen" is a cleaning task), and a
/// journal page's ticked goals and "What I was up to" count too.
struct AchievementRules {
    let met: Set<Achievement>

    init(tasks: [TaskItem], pages: [JournalEntry], usedDays: Set<Date>) {
        let calendar = Calendar.current
        let done = tasks.filter(\.isCompleted)
        let pages = pages.filter { !$0.isInTrash }
        var met = Set<Achievement>()
        func award(_ achievement: Achievement, _ condition: Bool) {
            if condition { met.insert(achievement) }
        }

        // Kinds of to-dos.
        func kinds(_ task: TaskItem) -> Set<String> {
            var kinds = Set<String>()
            if let custom = task.customCategory {
                if let art = CategoryArt.match(custom.name) { kinds.insert(art) }
            } else {
                kinds.insert(task.category.rawValue.capitalized)
            }
            if let art = CategoryArt.match(task.title) { kinds.insert(art) }
            return kinds
        }
        func count(_ list: [TaskItem], _ wanted: Set<String>) -> Int {
            list.filter { !kinds($0).isDisjoint(with: wanted) }.count
        }

        // Journal goals and activities, per page.
        func ticks(_ page: JournalEntry) -> [String] { (page.goals + page.activities).map { $0.lowercased() } }
        func pageCount(_ words: [String]) -> Int {
            pages.reduce(0) { total, page in
                total + page.goals.filter { goal in words.contains { goal.lowercased().contains($0) } }.count
            }
        }
        func days(where test: (JournalEntry) -> Bool) -> Set<Date> {
            Set(pages.filter(test).map { calendar.startOfDay(for: $0.date) })
        }

        // Getting started.
        award(.taskStarter, !tasks.isEmpty)
        award(.firstDay, !usedDays.isEmpty)
        let useRun = Self.longestRun(usedDays)
        award(.streak7, useRun >= 7)
        award(.streak30, useRun >= 30)
        award(.consistencyQueen, usedDays.count >= 30)
        award(.streakQueen, Self.longestRun(days { _ in true }) >= 30)

        // Goals ticked on journal pages.
        let goalsTicked = pages.reduce(0) { $0 + $1.goals.count }
        award(.firstGoal, goalsTicked >= 1)
        award(.risingStar, goalsTicked >= 10)
        award(.goalMaster, pages.contains { $0.goals.count >= 5 })
        award(.healthyYou, pageCount(["exercise", "gym", "walk", "steps", "run", "yoga", "workout"])
              + count(done, ["Fitness"]) >= 10)
        award(.selfCareChamp, pageCount(["meditat", "mindful", "grateful", "skincare", "self-care", "pray"])
              + count(done, ["SelfCare", "SelfCareLotus", "Mindfulness", "Wellness"]) >= 10)
        award(.learningBuddy, pageCount(["read", "learn", "study", "language"])
              + count(done, ["Learning", "Study"]) >= 5)
        award(.moneyWise, pageCount(["save money", "budget"]) + count(done, ["Finance"]) >= 5)
        award(.sweetDreams, Self.longestRun(days { ticks($0).contains("sleep early") }) >= 5)
        award(.waterHero, Self.longestRun(days { $0.goals.contains { $0.lowercased() == "drink water" } }) >= 7)
        award(.positiveVibes, pages.filter { Self.happyMoods.contains($0.mood) }.count >= 10)
        award(.meTime, pages.contains { page in
            ticks(page).contains { ["relax", "self-care", "meditate / mindfulness", "skincare", "yoga"].contains($0) }
        } || count(done, ["SelfCare", "SelfCareLotus", "Mindfulness"]) >= 1)
        award(.socialButterfly, pages.contains { $0.activities.contains { $0.lowercased() == "friends" } }
              || count(done, ["Friends"]) >= 1)

        // Kinds of to-dos.
        award(.shoppingSpree, count(tasks, ["Shopping"]) >= 10)
        award(.beautyLover, count(done, ["Beauty"]) >= 5)
        award(.homeHero, count(done, ["Home"]) >= 10)
        award(.onTheMove, count(done, ["CarTransport"]) >= 5)
        award(.foodieFun, count(done, ["FoodCooking", "Food"]) >= 10)
        award(.cleaningStar, count(done, ["Cleaning"]) >= 10)
        award(.entertainmentPro, count(done, ["Entertainment"]) >= 10)
        award(.petLover, count(done, ["Pets"]) >= 5)
        award(.creativeSoul, count(done, ["Hobbies", "Creativity"]) >= 5)
        award(.projectPro, count(done, ["Projects"]) >= 10)
        award(.appointmentKeeper, count(done, ["Appointments"]) >= 10)
        award(.eventPlanner, count(tasks, ["Events"]) >= 5)
        award(.travelExplorer, count(tasks, ["Travel"]) >= 1)

        // How and when to-dos are done.
        award(.ourHero, done.count >= 100)
        award(.playingSafe, done.filter(\.isImportant).count >= 10)
        award(.smartPlanner, tasks.filter { $0.date > calendar.startOfDay(for: $0.createdAt) }.count >= 20)
        let finished = done.compactMap { task in task.completedAt.map { (task, $0) } }
        award(.focusChampion, finished.filter { calendar.startOfDay(for: $0.1) <= $0.0.date }.count >= 25)
        let perDay = Dictionary(grouping: finished) { calendar.startOfDay(for: $0.1) }
        award(.productiveDay, perDay.values.contains { $0.count >= 8 })
        let perWeek = Dictionary(grouping: finished) {
            calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: $0.1)
        }
        award(.whatAWeek, perWeek.values.contains { $0.count >= 50 })
        let perYear = Dictionary(grouping: finished) { calendar.component(.year, from: $0.1) }
        award(.whatAYear, perYear.values.contains { $0.count >= 200 })
        let evenings = Set(finished.filter { calendar.component(.hour, from: $0.1) >= 18 }
            .map { calendar.startOfDay(for: $0.1) })
        award(.nightOwl, evenings.count >= 5)
        let mornings = Set(finished.filter { calendar.component(.hour, from: $0.1) < 9 }
            .map { calendar.startOfDay(for: $0.1) })
        award(.earlyBird, mornings.count >= 5)

        self.met = met
    }

    static let happyMoods: Set<Mood> = [
        .happy, .loved, .excited, .amazing, .grateful, .proud, .blissful, .content, .playful, .peaceful,
        .motivated, .confident, .hopeful, .energetic, .relaxed, .calm,
    ]

    /// The most days in a row among `days` (each a start of day).
    static func longestRun(_ days: Set<Date>) -> Int {
        let calendar = Calendar.current
        var best = 0
        var run = 0
        var previous: Date?
        for day in days.sorted() {
            if let previous, calendar.date(byAdding: .day, value: 1, to: previous) == day {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            previous = day
        }
        return best
    }
}

/// Watches the to-dos and journal pages (kept out of the root view, so their changes redraw
/// only this) and checks the badges when they change.
struct AchievementWatcher: View {
    @Query private var tasks: [TaskItem]
    @Query(filter: #Predicate<JournalEntry> { $0.deletedAt == nil }) private var pages: [JournalEntry]

    /// Changes whenever something a rule looks at changes.
    private var signature: String {
        let done = tasks.filter(\.isCompleted).count
        let ticks = pages.reduce(0) { $0 + $1.goals.count + $1.activities.count }
        return "\(tasks.count)-\(done)-\(pages.count)-\(ticks)"
    }

    var body: some View {
        Color.clear
            .task(id: signature) {
                // After the tick's own little celebration.
                try? await Task.sleep(for: .seconds(0.9))
                guard !Task.isCancelled else { return }
                AchievementCenter.shared.check(tasks: tasks, pages: pages)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - The pop-up

/// "7 Day Streak!" / "Congratulations!": the badge in a gold ring with a pink ribbon and gold
/// heart, the headline, a line, the badge's name and a cheer in a soft card, See All
/// Achievements, Share Good News and ✕, with confetti, as in the two pop-up designs.
struct AchievementPopup: View {
    let achievement: Achievement
    let onSeeAll: () -> Void
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private static let pink = Color(hex: 0xD8126F)
    private static let plum = Color(hex: 0x9A2DA6)

    var body: some View {
        ZStack {
            Color(hex: 0x5A1036).opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
                .accessibilityLabel("Close")
                .accessibilityAddTraits(.isButton)

            card
                .padding(.horizontal, 18)
                .scaleEffect(appeared ? 1 : 0.85)
                .opacity(appeared ? 1 : 0)

            if !reduceMotion {
                ConfettiCelebration()
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) { appeared = true }
        }
    }

    private var card: some View {
        VStack(spacing: 0) {
            badge
                .padding(.top, 22)
            Text(achievement.headline)
                .font(.rounded(size: 34, weight: .heavy))
                .foregroundStyle(Self.pink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.top, 14)
                .accessibilityAddTraits(.isHeader)
            Text(achievement.subtitle)
                .font(.rounded(size: 18, weight: .medium))
                .foregroundStyle(Self.plum)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 22)
                .padding(.top, 6)
            innerCard
                .padding(.top, 16)
            buttons
                .padding(.top, 16)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 20)
        .frame(maxWidth: 420)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0xFDEAF3), Color(hex: 0xFCE3EF)],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(sparkles)
                .shadow(color: Color(hex: 0xC2185B).opacity(0.25), radius: 24, x: 0, y: 10)
        )
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Color(hex: 0x8E2C8F))
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color.white.opacity(0.85)))
                    .shadow(color: Color(hex: 0xE58AAE).opacity(0.2), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(PressScaleStyle())
            .padding(14)
            .accessibilityLabel("Close")
        }
    }

    /// The badge's picture inside the gold ring, with the pink ribbon and gold heart over its foot.
    private var badge: some View {
        let ring: CGFloat = 196
        return ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0xFFE3F0), Color(hex: 0xFBB6D4)],
                                     center: .center, startRadius: 10, endRadius: ring / 2))
            Image(achievement.art)
                .resizable()
                .scaledToFit()
                .frame(width: ring * 0.98)
                .frame(width: ring, height: ring, alignment: .top)
                .clipShape(Circle())
            Circle()
                .strokeBorder(LinearGradient(colors: [Color(hex: 0xFFE7A3), Color(hex: 0xF4C155), Color(hex: 0xFFDE8A)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing),
                              lineWidth: 9)
                .shadow(color: Color(hex: 0xE5A93C).opacity(0.35), radius: 4, x: 0, y: 2)
        }
        .frame(width: ring, height: ring)
        .overlay(alignment: .top) {
            // From the design: 0.95 of the ring wide, its top 0.61 of the radius below the centre.
            Image("AchievementRibbon")
                .resizable()
                .scaledToFit()
                .frame(width: ring * 0.947)
                .offset(x: -ring * 0.004, y: ring / 2 + ring / 2 * 0.611)
        }
        .padding(.bottom, ring * 0.08)
        .accessibilityElement()
        .accessibilityLabel(achievement.title + " badge")
    }

    private var innerCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                heart
                Text(achievement.cardTitle)
                    .font(.rounded(size: 25, weight: .heavy))
                    .foregroundStyle(Self.pink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                heart
            }
            Text(achievement.cheer)
                .font(.rounded(size: 17, weight: .medium))
                .foregroundStyle(Self.plum)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.6))
                .shadow(color: Color(hex: 0xE58AAE).opacity(0.15), radius: 8, x: 0, y: 3)
        )
    }

    private var heart: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFF7DB8), Color(hex: 0xF0287F)],
                                            startPoint: .top, endPoint: .bottom))
            .accessibilityHidden(true)
    }

    private var buttons: some View {
        VStack(spacing: 12) {
            Button(action: onSeeAll) {
                Text("See All Achievements")
                    .font(.rounded(size: 20, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(
                        Capsule().fill(LinearGradient(colors: [Color(hex: 0xFF5FA8), Color(hex: 0xEC2A80)],
                                                      startPoint: .top, endPoint: .bottom))
                    )
                    .shadow(color: Color(hex: 0xEC2A80).opacity(0.35), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PressScaleStyle(scale: 0.97))

            ShareLink(item: achievement.shareText) {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Share Good News")
                        .font(.rounded(size: 19, weight: .bold))
                    Image(systemName: "sparkles")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(hex: 0xF6C343))
                }
                .foregroundStyle(Self.pink)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(Capsule().fill(Color.white.opacity(0.75)))
                .shadow(color: Color(hex: 0xE58AAE).opacity(0.15), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(PressScaleStyle(scale: 0.97))
        }
    }

    /// The little hearts, stars and sparkles scattered on the card.
    private var sparkles: some View {
        GeometryReader { proxy in
            ForEach(Self.scatter.indices, id: \.self) { index in
                let item = Self.scatter[index]
                Image(systemName: item.symbol)
                    .font(.system(size: item.size, weight: .bold))
                    .foregroundStyle(item.color)
                    .rotationEffect(.degrees(item.angle))
                    .position(x: proxy.size.width * item.x, y: proxy.size.height * item.y)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private static let scatter: [(symbol: String, x: CGFloat, y: CGFloat, size: CGFloat, color: Color, angle: Double)] = [
        ("heart.fill", 0.15, 0.17, 26, Color(hex: 0xFF6FAE), -12),
        ("star.fill", 0.12, 0.26, 24, Color(hex: 0xFFC83D), -8),
        ("heart.fill", 0.12, 0.36, 30, Color(hex: 0xF7A6E0), 8),
        ("heart.fill", 0.74, 0.13, 24, Color(hex: 0xFF6FAE), 14),
        ("star.fill", 0.87, 0.32, 28, Color(hex: 0xFFC83D), 10),
        ("heart.fill", 0.85, 0.42, 26, Color(hex: 0xFF8CC6), -10),
        ("sparkle", 0.07, 0.56, 14, Color(hex: 0xFFC83D), 0),
        ("sparkle", 0.92, 0.47, 14, Color(hex: 0xFFC83D), 0),
        ("capsule.fill", 0.08, 0.1, 10, Color(hex: 0x7FB2FF), 40),
        ("capsule.fill", 0.7, 0.08, 10, Color(hex: 0x6FD3F2), -30),
        ("capsule.fill", 0.93, 0.2, 10, Color(hex: 0xB58CFF), 60),
        ("circle.fill", 0.52, 0.06, 8, Color(hex: 0x4FB7F0), 0),
        ("circle.fill", 0.82, 0.37, 7, Color(hex: 0x8C7CF0), 0),
    ]
}

// MARK: - All the badges

/// Achievements, from the side menu and the pop-up's See All Achievements: every badge, earned
/// ones bright and the rest dimmed with a little lock until they are earned.
struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss
    private let center = AchievementCenter.shared

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                progress
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(Achievement.allCases) { achievement in
                        AchievementCell(achievement: achievement, isEarned: center.isEarned(achievement))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .background(
            LinearGradient(colors: [Color(hex: 0xFFF1F7), Color(hex: 0xFDE6F1)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
                    .fontWeight(.bold)
            }
        }
    }

    private var progress: some View {
        let total = Achievement.allCases.count
        return VStack(spacing: 8) {
            Text("\(center.earnedCount) of \(total) earned")
                .font(.rounded(size: 22, weight: .heavy))
                .foregroundStyle(Color(hex: 0xD8126F))
            ProgressView(value: Double(center.earnedCount), total: Double(total))
                .tint(Color(hex: 0xF0287F))
                .scaleEffect(x: 1, y: 1.6)
            Text("Keep going! Each badge lights up when you earn it. 💖")
                .font(.rounded(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: 0x9A2DA6))
                .multilineTextAlignment(.center)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.white.opacity(0.75)))
    }
}

/// One badge: its picture and a label pill with its name and line.
struct AchievementCell: View {
    let achievement: Achievement
    let isEarned: Bool

    var body: some View {
        VStack(spacing: -10) {
            Image(achievement.art)
                .resizable()
                .scaledToFit()
                .grayscale(isEarned ? 0 : 0.85)
                .opacity(isEarned ? 1 : 0.45)
                .overlay(alignment: .topTrailing) {
                    if !isEarned {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color(hex: 0xB79AC8)))
                            .offset(x: -2, y: 4)
                    }
                }
            VStack(spacing: 2) {
                Text(achievement.title)
                    .font(.rounded(size: 13, weight: .heavy))
                    .foregroundStyle(isEarned ? Color(hex: 0xC2126B) : Color(hex: 0x9E8AA8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(achievement.detail)
                    .font(.rounded(size: 11, weight: .medium))
                    .foregroundStyle(isEarned ? Color(hex: 0x7A3A8C) : Color(hex: 0xA898B0))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 62)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(isEarned ? 0.9 : 0.6))
                    .shadow(color: Color(hex: 0xE58AAE).opacity(isEarned ? 0.2 : 0.08), radius: 5, x: 0, y: 2)
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(achievement.title). \(achievement.detail) \(isEarned ? "Earned" : "Not earned yet")")
    }
}
