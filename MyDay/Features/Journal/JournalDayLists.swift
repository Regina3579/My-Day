import SwiftUI

// MARK: - The lists

/// "What have you been up to?" and "My Goals" on a journal page: each a list of things the person
/// can tick for the day, which they can add to, take from and put in their own order.
enum DayListKind: String, Identifiable {
    case activities, goals

    var id: String { rawValue }

    /// As in their designs.
    var defaults: [String] {
        switch self {
        case .activities:
            ["Family", "Friends", "Date", "Exercise", "Sport", "Sleep Early", "Eat Healthy", "Relax",
             "Movies", "Read", "Gaming", "Cleaning", "Shopping"]
        case .goals:
            ["Drink Water", "Eat Healthy", "Read Book", "Exercise / Gym", "Walk / Steps", "Sleep Early",
             "Meditate / Mindfulness", "Be Grateful", "Save Money", "Learn New Language"]
        }
    }

    /// Ready-made ideas shown in the editor, besides the ones already on the list.
    var suggestions: [String] {
        switch self {
        case .activities:
            defaults + ["Cooking", "Baking", "Gardening", "Running", "Yoga", "Swimming", "Music", "Dancing",
                        "Travel", "Coffee", "Pets", "Study", "Work", "Self-care", "Hiking", "Photography"]
        case .goals:
            defaults + ["No Overeating", "Reduce Screen Time", "Be Positive", "Try Something New", "Run",
                        "Yoga", "Journal Daily", "Skincare", "Pray", "Study", "Call Family"]
        }
    }

    private var key: String { self == .activities ? Prefs.journalActivities : Prefs.journalGoals }

    /// The list as the person has it (the design's list until they change it).
    var items: [String] {
        get {
            guard let saved = UserDefaults.standard.string(forKey: key) else { return defaults }
            return saved.isEmpty ? [] : saved.components(separatedBy: "\n")
        }
        nonmutating set {
            UserDefaults.standard.set(newValue.joined(separator: "\n"), forKey: key)
        }
    }
}

// MARK: - Pictures

/// The cute picture for a thing on the lists: the designs' own for theirs, and for anything the
/// person adds, the best match from a library kept ready here (the designs' pictures and the
/// sticker sheet's, read from the words in its name: "Gardening" gets the sprout, "Running" the
/// pink sneaker, "Coffee" the cup), or the emoji it was typed with. None of the library shows
/// until something is added that needs it.
enum DayItemArt: Equatable {
    case design(String)
    case sticker(String)
    case emoji(String)

    static func of(_ title: String) -> DayItemArt {
        if let exact = designs[title.lowercased()] { return .design(exact) }
        // An emoji typed with the name ("🎨 Painting") is its picture.
        if let emoji = title.first(where: { $0.unicodeScalars.first?.properties.isEmojiPresentation == true }) {
            return .emoji(String(emoji))
        }
        let words = title.lowercased().split { !$0.isLetter }.map(String.init)
        for (keys, art) in library {
            for key in keys {
                let matches = key.hasSuffix("*")
                    ? words.contains { $0.hasPrefix(String(key.dropLast())) }
                    : words.contains { $0 == key || $0 == key + "s" || $0 == key + "es" }
                if matches { return art }
            }
        }
        return .sticker("growth-04") // a gold star
    }

    /// The designs' pictures, by name.
    private static let designs: [String: String] = [
        "family": "ActFamily", "friends": "ActFriends", "date": "ActDate", "exercise": "ActExercise",
        "sport": "ActSport", "sleep early": "ActSleepEarly", "eat healthy": "ActEatHealthy", "relax": "ActRelax",
        "movies": "ActMovies", "read": "ActRead", "gaming": "ActGaming", "cleaning": "ActCleaning",
        "shopping": "ActShopping",
        "drink water": "GoalDrinkWater", "read book": "GoalReadBook", "exercise / gym": "GoalExercise",
        "walk / steps": "GoalWalk", "meditate / mindfulness": "GoalMeditate", "be grateful": "GoalGrateful",
        "save money": "GoalSaveMoney", "learn new language": "GoalLanguage",
    ]

    /// Words in a name, and the picture they call for (the more particular first).
    private static let library: [([String], DayItemArt)] = [
        (["garden*", "plant*", "seed*", "grow*", "sprout"], .sticker("growth-05")),
        (["flower*", "tulip*", "bloom*"], .sticker("nature-07")),
        (["tree*", "forest", "park", "nature"], .sticker("nature-13")),
        (["hik*", "mountain*", "climb*", "trek*"], .sticker("nature-14")),
        (["swim*", "beach", "sea", "ocean", "surf*", "pool"], .sticker("nature-15")),
        (["run", "running", "jog*", "marathon", "sneaker*", "walk*", "step*"], .design("GoalWalk")),
        (["sport*", "tennis", "football", "soccer", "basketball", "badminton", "cricket", "cycl*", "bike*"], .design("ActSport")),
        (["gym", "workout", "exercise*", "fitness", "lift*", "weight*"], .design("GoalExercise")),
        (["yoga", "stretch*", "pilates"], .sticker("selfcare-04")),
        (["meditat*", "mindful*", "breath*", "calm"], .design("GoalMeditate")),
        (["pray*", "church", "temple", "mosque", "worship", "bible", "quran", "candle*"], .sticker("selfcare-02")),
        (["bath", "spa", "skincare", "skin", "selfcare", "pamper*", "facial"], .sticker("selfcare-08")),
        (["tea"], .sticker("selfcare-03")),
        (["coffee", "latte", "cafe", "espresso"], .sticker("food-01")),
        (["bake", "baking", "cake*", "cupcake*", "dessert*", "sweet*"], .sticker("food-04")),
        (["cook*", "recipe*", "kitchen", "dinner", "lunch", "breakfast", "meal*", "salad*", "vegetable*",
          "veggie*", "fruit*", "healthy", "diet"], .design("GoalEatHealthy")),
        (["overeat*", "snack*", "junk"], .sticker("food-06")),
        (["water", "hydrat*", "drink*"], .design("GoalDrinkWater")),
        (["sleep*", "nap*", "bed*", "rest"], .design("GoalSleepEarly")),
        (["relax*", "chill*", "peace*", "lotus"], .design("ActRelax")),
        (["read*", "book*", "novel*", "library"], .design("GoalReadBook")),
        (["journal*", "diary", "write", "writing", "letter*", "poem*"], .sticker("occasions-09")),
        (["study*", "homework", "exam*", "class*", "school", "college", "learn*", "course*", "lesson*"], .sticker("growth-07")),
        (["language*", "arabic", "spanish", "french", "english", "german", "hindi", "tamil", "chinese",
          "japanese", "korean", "urdu"], .design("GoalLanguage")),
        (["work*", "office", "project*", "task*", "plan*", "meeting*"], .sticker("growth-08")),
        (["idea*", "creative", "create", "think*"], .sticker("growth-03")),
        (["goal*", "achieve*", "win*", "success"], .sticker("growth-09")),
        (["money", "save*", "saving*", "budget*", "spend*", "invest*"], .design("GoalSaveMoney")),
        (["grateful", "gratitude", "thank*", "positive", "smile*", "happy", "kind*"], .design("GoalGrateful")),
        (["screen*", "phone*", "social", "detox"], .sticker("growth-01")),
        (["new", "try*", "adventure*", "explore*"], .sticker("travel-07")),
        (["travel*", "trip*", "flight*", "fly*", "vacation*", "holiday*"], .sticker("travel-01")),
        (["photo*", "camera", "picture*"], .sticker("travel-04")),
        (["music", "song*", "sing*", "piano", "guitar", "violin", "danc*", "concert*", "playlist*"], .sticker("misc-07")),
        (["dog*", "puppy", "puppies", "pet*", "walkies"], .sticker("animals-02")),
        (["cat*", "kitten*", "kitty"], .sticker("animals-01")),
        (["bunny", "bunnies", "rabbit*"], .sticker("animals-03")),
        (["birthday*", "cake"], .sticker("occasions-01")),
        (["party", "parties", "celebrat*"], .sticker("occasions-04")),
        (["gift*", "present*"], .sticker("occasions-02")),
        (["christmas", "xmas"], .sticker("occasions-06")),
        (["family", "mom", "mum", "dad", "parent*", "home", "sister*", "brother*", "grandma", "grandpa", "kids", "baby"],
         .design("ActFamily")),
        (["friend*", "hangout*", "bestie*"], .design("ActFriends")),
        (["date", "love", "partner", "boyfriend", "girlfriend", "husband", "wife", "romance", "romantic"], .design("ActDate")),
        (["movie*", "film*", "netflix", "tv", "show*", "series", "cinema"], .design("ActMovies")),
        (["game*", "gaming", "play*", "console"], .design("ActGaming")),
        (["clean*", "tidy", "laundry", "wash*", "chore*", "declutter*"], .design("ActCleaning")),
        (["shop*", "mall", "grocer*", "market", "buy*"], .design("ActShopping")),
        (["morning", "sunrise", "sun"], .sticker("nature-01")),
        (["night", "evening", "star*", "moon"], .sticker("aesthetic-03")),
        (["rain*"], .sticker("weather-04")),
        (["snow*", "winter"], .sticker("weather-05")),
        (["art", "paint*", "draw*", "craft*", "sketch*", "butterfl*"], .sticker("aesthetic-06")),
    ]
}

/// A thing's picture in its soft round badge (the designs' own badges are part of their
/// pictures; the library's sit in a matching pastel circle).
struct DayItemIcon: View {
    let title: String
    var size: CGFloat = 58

    var body: some View {
        switch DayItemArt.of(title) {
        case .design(let name):
            Image("JournalUpTo/" + name)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        case .sticker(let id):
            badge {
                Image("Stickers/" + id)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.17)
            }
        case .emoji(let emoji):
            badge {
                Text(emoji)
                    .font(.system(size: size * 0.48))
            }
        }
    }

    private func badge(@ViewBuilder _ content: () -> some View) -> some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color.white, Color(hex: 0xFCE3EE)], center: .init(x: 0.45, y: 0.35),
                                     startRadius: 2, endRadius: size * 0.6))
            Circle().strokeBorder(Color.white.opacity(0.9), lineWidth: 1.5)
            content()
        }
        .frame(width: size, height: size)
    }
}

// MARK: - The cards

/// "What have you been up to?" (or "My Goals"), as in its design: the title in bold berry with a
/// glossy heart and a white **Edit** pill, then five across, each picture over its name; tap one
/// to tick it for the day (a pink ring and a little check). Activities end with a dashed
/// "Add / Edit" circle; goals have the target, "Set your goals and track what matters to you." and
/// a wide **Add More Goals** button.
struct DayListCard: View {
    let kind: DayListKind
    @Binding var chosen: Set<String>
    let onEdit: () -> Void
    /// The list (read again after editing).
    let items: [String]

    private static let berry = Color(hex: 0xA80B55)
    private static let navy = Color(hex: 0x2B1E6B)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4, alignment: .top), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            LazyVGrid(columns: columns, spacing: 10) {
                // Ticked ones that are no longer on the list still show on this day's page.
                ForEach(items + chosen.filter { !items.contains($0) }.sorted(), id: \.self) { title in
                    cell(title)
                }
                if kind == .activities {
                    addCell
                }
            }
            if kind == .goals {
                addGoalsButton
            }
        }
        .journalCard()
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            if kind == .goals {
                Image("JournalUpTo/GoalTarget")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(kind == .activities ? "What have you been up to?" : "My Goals")
                        .font(.rounded(size: 19, weight: .heavy))
                        .foregroundStyle(Self.berry)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .accessibilityAddTraits(.isHeader)
                    Image("JournalUpTo/UpToHeart")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .accessibilityHidden(true)
                }
                if kind == .goals {
                    Text("Set your goals and track what matters to you.")
                        .font(.rounded(size: 13, weight: .medium))
                        .foregroundStyle(Color(hex: 0xA77BBE))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 4)
            Button(action: onEdit) {
                HStack(spacing: 5) {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .heavy))
                    Text("Edit")
                        .font(.rounded(size: 15, weight: .heavy))
                }
                .foregroundStyle(Color(hex: 0xE8237A))
                .padding(.horizontal, 13)
                .frame(height: 34)
                .background(Capsule().fill(Color.white))
                .shadow(color: Color(hex: 0xE58AAE).opacity(0.22), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel(kind == .activities ? "Edit what you've been up to" : "Edit goals")
        }
    }

    private func cell(_ title: String) -> some View {
        let isOn = chosen.contains(title)
        return Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                if isOn { chosen.remove(title) } else { chosen.insert(title) }
            }
        } label: {
            VStack(spacing: 4) {
                DayItemIcon(title: title, size: 56)
                    .overlay {
                        Circle().strokeBorder(Color(hex: 0xF0569B), lineWidth: isOn ? 3 : 0)
                    }
                    .overlay(alignment: .topTrailing) {
                        if isOn {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(Color.white, Color(hex: 0xF0569B))
                                .offset(x: 3, y: -3)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .scaleEffect(isOn ? 1.04 : 1)
                Text(title)
                    .font(.rounded(size: 11.5, weight: isOn ? .heavy : .semibold))
                    .foregroundStyle(isOn ? Color(hex: 0xD6247A) : Self.navy)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleStyle(scale: 0.93))
        .accessibilityLabel(title)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    private var addCell: some View {
        Button(action: onEdit) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .strokeBorder(Color(hex: 0xF27BB1), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color(hex: 0xF0569B))
                }
                .frame(width: 56, height: 56)
                Text("Add / Edit")
                    .font(.rounded(size: 11.5, weight: .semibold))
                    .foregroundStyle(Self.navy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressScaleStyle(scale: 0.93))
        .accessibilityLabel("Add or edit")
    }

    private var addGoalsButton: some View {
        Button(action: onEdit) {
            HStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: 0xF7A3CA))
                Spacer(minLength: 0)
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Color.white)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color(hex: 0xF0418E)))
                Text("Add More Goals")
                    .font(.rounded(size: 16, weight: .heavy))
                    .foregroundStyle(Color(hex: 0xE8237A))
                Spacer(minLength: 0)
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: 0xF7A3CA))
            }
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(Capsule().fill(Color(hex: 0xFDF0F6)))
            .overlay(Capsule().strokeBorder(Color(hex: 0xF6C3D8), lineWidth: 1.5))
        }
        .buttonStyle(PressScaleStyle(scale: 0.97))
        .padding(.top, 4)
    }
}

// MARK: - Editing

/// Edit a list: drag to reorder, delete, and add new ones (typed, or from the ideas), each with
/// its cute picture shown as it is typed.
struct DayListEditor: View {
    let kind: DayListKind
    let onDone: () -> Void

    @State private var items: [String] = []
    @State private var newTitle = ""
    @FocusState private var typing: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        DayItemIcon(title: newTitle.trimmed.isEmpty ? "?" : newTitle.trimmed, size: 44)
                            .opacity(newTitle.trimmed.isEmpty ? 0.5 : 1)
                        TextField(kind == .activities ? "Add something you do" : "Add a goal", text: $newTitle)
                            .font(.rounded(.body, weight: .semibold))
                            .focused($typing)
                            .submitLabel(.done)
                            .onSubmit(add)
                        Button("Add", action: add)
                            .font(.rounded(.body, weight: .heavy))
                            .foregroundStyle(Color(hex: 0xE8237A))
                            .disabled(newTitle.trimmed.isEmpty)
                    }
                } footer: {
                    Text("Its picture is chosen from its name.")
                }
                let ideas = kind.suggestions.filter { !items.contains($0) }
                if !ideas.isEmpty {
                    Section("Ideas") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(ideas, id: \.self) { idea in
                                    Button {
                                        withAnimation { items.append(idea) }
                                        save()
                                    } label: {
                                        VStack(spacing: 4) {
                                            DayItemIcon(title: idea, size: 46)
                                            Text(idea)
                                                .font(.rounded(size: 11, weight: .semibold))
                                                .foregroundStyle(Color(hex: 0x2B1E6B))
                                                .lineLimit(2)
                                                .multilineTextAlignment(.center)
                                                .frame(width: 70)
                                        }
                                    }
                                    .buttonStyle(PressScaleStyle(scale: 0.93))
                                    .accessibilityLabel("Add \(idea)")
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                Section(kind == .activities ? "Your list" : "Your goals") {
                    ForEach(items, id: \.self) { title in
                        HStack(spacing: 12) {
                            DayItemIcon(title: title, size: 40)
                            Text(title)
                                .font(.rounded(.body, weight: .semibold))
                        }
                    }
                    .onDelete { offsets in
                        items.remove(atOffsets: offsets)
                        save()
                    }
                    .onMove { from, to in
                        items.move(fromOffsets: from, toOffset: to)
                        save()
                    }
                    if items != kind.defaults {
                        Button("Bring back the starting list") {
                            withAnimation { items = kind.defaults }
                            save()
                        }
                        .foregroundStyle(Color(hex: 0xE8237A))
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle(kind == .activities ? "What have you been up to?" : "My Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        add()
                        onDone()
                        dismiss()
                    }
                    .fontWeight(.heavy)
                }
            }
        }
        .tint(Color(hex: 0xE8237A))
        .onAppear { items = kind.items }
    }

    private func add() {
        let title = newTitle.trimmed
        guard !title.isEmpty else { return }
        if !items.contains(title) {
            withAnimation { items.append(title) }
            save()
        }
        newTitle = ""
    }

    private func save() {
        kind.items = items
    }
}

/// On a saved page: what the day held, or the goals met, as their little pictures in a row.
struct DayListRow: View {
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.rounded(.subheadline, weight: .heavy))
                .foregroundStyle(Color(hex: 0xA80B55))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(items, id: \.self) { item in
                        VStack(spacing: 3) {
                            DayItemIcon(title: item, size: 44)
                            Text(item)
                                .font(.rounded(size: 10.5, weight: .semibold))
                                .foregroundStyle(Color(hex: 0x2B1E6B))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .frame(width: 64)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(items.joined(separator: ", "))")
    }
}
