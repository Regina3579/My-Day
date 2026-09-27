import Foundation

/// Turns a spoken sentence such as "Remind me to call the doctor tomorrow at 5 PM"
/// into a draft to-do. It never saves anything: the result is shown for the
/// person to confirm, with every guess pointed out.
enum VoiceTaskParser {
    struct Result {
        var draft: TaskDraft
        /// A category word was heard (otherwise Personal is only a default).
        var heardCategory = false
        /// Things the person should double-check, in plain words.
        var notes: [String] = []
    }

    /// - Parameters:
    ///   - defaultDay: The day to use when no day is mentioned (the list being viewed).
    ///   - today: What "today" and "tomorrow" count from.
    static func parse(_ transcript: String, defaultDay: Date? = nil, today: Date = .now, now: Date = .now) -> Result {
        let spoken = transcript.trimmed
        var text = " " + spoken + " "
        var result = Result(draft: TaskDraft(day: today))

        // "Remind me to …"
        let wantsReminder = take(#"\b(?:please\s+)?(?:set\s+(?:a\s+)?reminder\s+(?:to|for)|remind\s+me\s+(?:to|about)|remind\s+me|reminder\s+to)\b"#,
                                 from: &text) != nil

        // Clock time.
        var time: DateComponents?
        var timeIsGuess = false
        if let match = take(#"\b(?:at|by|around|before)?\s*(\d{1,2}|"# + numberWords + #")(?:[:.](\d{2}))?\s*([ap])\.?\s?m\b\.?"#, from: &text) {
            let hour = hourValue(match[1])
            let minute = Int(match[2] ?? "") ?? 0
            if let hour, (1...12).contains(hour), (0...59).contains(minute) {
                let isPM = match[3]?.lowercased() == "p"
                time = DateComponents(hour: hour % 12 + (isPM ? 12 : 0), minute: minute)
            }
        } else if let match = take(#"\b(?:at|by|around|before)?\s*(\d{1,2}):(\d{2})\b"#, from: &text) {
            if let hour = Int(match[1] ?? ""), let minute = Int(match[2] ?? ""), (0...23).contains(hour), (0...59).contains(minute) {
                timeIsGuess = (1...11).contains(hour)
                time = DateComponents(hour: timeIsGuess ? afternoonGuess(hour) : hour, minute: minute)
            }
        } else if let match = take(#"\b(?:at|by|around|before)\s+(\d{1,2}|"# + numberWords + #")(?:\s*o[’']?\s?clock)?\b"#, from: &text) {
            if let hour = hourValue(match[1]), (1...12).contains(hour) {
                time = DateComponents(hour: afternoonGuess(hour), minute: 0)
                timeIsGuess = true
            }
        } else if take(#"\b(?:at\s+)?noon\b"#, from: &text) != nil {
            time = DateComponents(hour: 12, minute: 0)
        }

        // Repeat.
        var repeatOption = RepeatOption.never
        if let match = take(#"\b(?:every\s+(day|weekday|week|month)|(daily|weekly|monthly)|on\s+weekdays)\b"#, from: &text) {
            switch (match[1] ?? match[2] ?? "weekday").lowercased() {
            case "day", "daily": repeatOption = .daily
            case "week", "weekly": repeatOption = .weekly
            case "month", "monthly": repeatOption = .monthly
            default: repeatOption = .weekdays
            }
        }

        // Day.
        var day: Date?
        var partOfDay: Int?
        if take(#"\b(?:the\s+)?day\s+after\s+tomorrow\b"#, from: &text) != nil {
            day = today.adding(days: 2)
        } else if let match = take(#"\b(?:by\s+|for\s+)?tomorrow(?:\s+(morning|afternoon|evening|night))?\b"#, from: &text) {
            day = today.adding(days: 1)
            partOfDay = match[1].flatMap(hour(forPartOfDay:))
        } else if let match = take(#"\b(?:by\s+|for\s+)?(?:today|(tonight)|this\s+(morning|afternoon|evening))\b"#, from: &text) {
            day = today.startOfDay
            partOfDay = match[1] != nil ? 20 : match[2].flatMap(hour(forPartOfDay:))
        } else if let match = take(#"\b(?:on\s+|by\s+|this\s+|next\s+)?(monday|tuesday|wednesday|thursday|friday|saturday|sunday)s?\b"#, from: &text),
                  let name = match[1] {
            day = nextDate(weekday: name, after: today)
        } else if let found = detectedDate(in: &text, today: today) {
            day = found.day
            if time == nil, let clock = found.time {
                time = clock
            }
            result.notes.append("Please check the date.")
        }

        if time == nil, let partOfDay {
            time = DateComponents(hour: partOfDay, minute: 0)
            timeIsGuess = true
        }

        var draft = TaskDraft(day: day ?? defaultDay ?? today)
        draft.repeatOption = repeatOption
        if let time, let clock = Calendar.current.date(bySettingHour: time.hour ?? 9, minute: time.minute ?? 0,
                                                       second: 0, of: draft.day) {
            draft.time = clock
            if timeIsGuess {
                result.notes.append("I guessed \(clock.formatted(date: .omitted, time: .shortened)) — change it if needed.")
            }
        }

        if wantsReminder {
            if let clock = draft.time, clock > now {
                draft.reminderEnabled = true
                draft.reminderDate = clock
            } else if draft.time != nil {
                result.notes.append("That time has already passed, so the reminder is off.")
            } else {
                result.notes.append("Add a time to get a reminder.")
            }
        }

        // Category, from the words that are left.
        stripCategoryPhrase(from: &text)
        let heard = category(in: text)
        draft.category = heard ?? .personal
        result.heardCategory = heard != nil

        let title = cleanTitle(text)
        draft.title = title.isEmpty ? capitalizedFirst(spoken) : title
        result.draft = draft
        return result
    }

    // MARK: Matching

    private static let numberWords = "one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve"

    /// Removes the first match of `pattern` from `text` and returns its capture groups (index 0 is the whole match).
    private static func take(_ pattern: String, from text: inout String) -> [String?]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let whole = Range(match.range, in: text)
        else { return nil }
        let groups: [String?] = (0..<match.numberOfRanges).map { index in
            Range(match.range(at: index), in: text).map { String(text[$0]) }
        }
        text.replaceSubrange(whole, with: " ")
        return groups
    }

    private static func hourValue(_ word: String?) -> Int? {
        guard let word = word?.lowercased() else { return nil }
        if let number = Int(word) { return number }
        let words = numberWords.components(separatedBy: "|")
        return words.firstIndex(of: word).map { $0 + 1 }
    }

    /// "At 5" most likely means 5 PM; "at 9" most likely means 9 AM.
    private static func afternoonGuess(_ hour: Int) -> Int {
        (1...6).contains(hour) ? hour + 12 : hour
    }

    private static func hour(forPartOfDay word: String) -> Int? {
        switch word.lowercased() {
        case "morning": 9
        case "afternoon": 14
        case "evening": 18
        case "night": 20
        default: nil
        }
    }

    private static func nextDate(weekday name: String, after today: Date) -> Date {
        let names = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        guard let target = names.firstIndex(of: name.lowercased()) else { return today.startOfDay }
        let current = Calendar.current.component(.weekday, from: today) - 1
        let ahead = (target - current + 7) % 7
        return today.adding(days: ahead == 0 ? 7 : ahead)
    }

    /// Other ways of saying a date ("on June 3rd"), found with `NSDataDetector`.
    private static func detectedDate(in text: inout String, today: Date) -> (day: Date, time: DateComponents?)? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue),
              let match = detector.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let date = match.date, date >= today.startOfDay,
              let range = Range(match.range, in: text)
        else { return nil }
        let phrase = text[range].lowercased()
        let hasClock = phrase.range(of: #"\d\s*(:|a\.?m|p\.?m)|noon"#, options: .regularExpression) != nil
        text.replaceSubrange(range, with: " ")
        let time = hasClock ? Calendar.current.dateComponents([.hour, .minute], from: date) : nil
        return (date.startOfDay, time)
    }

    // MARK: Category

    private static let keywords: [(TaskCategory, Set<String>)] = [
        (.health, ["doctor", "dentist", "gym", "workout", "exercise", "run", "running", "jog", "yoga", "medicine",
                   "medication", "pills", "vitamins", "water", "walk", "hospital", "therapy", "therapist", "meditate",
                   "meditation", "checkup", "pharmacy", "sleep", "stretch", "stretching", "clinic", "health",
                   "healthy", "physio", "swim", "swimming"]),
        (.work, ["work", "meeting", "meetings", "email", "emails", "office", "boss", "client", "clients", "project",
                 "report", "presentation", "deadline", "colleague", "colleagues", "team", "slides", "invoice",
                 "interview", "manager", "proposal", "standup", "spreadsheet", "contract"]),
        (.learning, ["study", "studying", "homework", "read", "reading", "book", "books", "class", "course",
                     "lesson", "lessons", "learn", "learning", "practice", "exam", "exams", "test", "revise",
                     "revision", "school", "lecture", "assignment", "essay", "chapter", "tutorial", "language"]),
        (.shopping, ["buy", "shop", "shopping", "groceries", "grocery", "store", "supermarket", "order", "milk",
                     "bread", "eggs", "market", "mall", "purchase", "gift", "gifts", "fruit", "vegetables"]),
        (.personal, ["mom", "mum", "dad", "mother", "father", "sister", "brother", "family", "friend", "friends",
                     "birthday", "anniversary", "clean", "cleaning", "laundry", "dishes", "bills", "bank",
                     "haircut", "personal", "party", "pet", "dog", "cat", "home", "house"])
    ]

    /// The category with the most matching words; ties go to the earlier category in the list.
    private static func category(in text: String) -> TaskCategory? {
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }
        var best: (category: TaskCategory, hits: Int)?
        for (category, list) in keywords {
            let hits = words.filter { list.contains($0) }.count
            if hits > 0, hits > (best?.hits ?? 0) {
                best = (category, hits)
            }
        }
        return best?.category
    }

    /// "… for work", "… in my shopping list": the category is kept, the words are dropped from the title.
    private static func stripCategoryPhrase(from text: inout String) {
        _ = take(#"\b(?:in|on|to|for|under)\s+(?:the\s+|my\s+)?(?:personal|work|health|learning|shopping)\s+(?:category|list|tasks?)\b"#,
                 from: &text)
    }

    // MARK: Title

    private static func cleanTitle(_ text: String) -> String {
        var title = text
        let filler = #"^\s*(?:(?:hey|ok|okay|so|um|uh|please)[,\s]+)*(?:add\s+(?:a\s+)?(?:new\s+)?(?:task|to-?do)\s*(?:to|for|called|:)?|i\s+(?:need|have|want|got)\s+to|i\s+must|i\s+should|don[’']?t\s+forget\s+to|need\s+to|have\s+to|remember\s+to|to)\s+"#
        _ = take(filler, from: &title)
        // Words left hanging at the end, like "… at" or "… on the".
        while take(#"\s(?:at|on|by|for|this|next|every|the|and|in|to)\s*[.,!?]*\s*$"#, from: &title) != nil {}
        title = title
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: CharacterSet(charactersIn: " .,;:!?-"))
        return capitalizedFirst(title)
    }

    private static func capitalizedFirst(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }
}
