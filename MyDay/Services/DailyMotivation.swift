import Foundation

/// Daily Motivation: a short, positive message for the home screen.
///
/// The collection is stored in the app, so it works without internet access.
/// One quote is chosen per calendar day: it stays the same all day and changes
/// after midnight. Every quote appears once before any repeats.
enum DailyMotivation {
    enum Theme: String, CaseIterable {
        case happiness, productivity, gratitude, selfBelief, consistency, peacefulLiving, progress

        /// A small mark written after the quote, like a doodle at the end of a note.
        var emoji: String {
            switch self {
            case .happiness: "🌸"
            case .productivity: "⭐"
            case .gratitude: "💕"
            case .selfBelief: "✨"
            case .consistency: "🌱"
            case .peacefulLiving: "🌿"
            case .progress: "🌈"
            }
        }
    }

    /// A quote written as two short lines, so it fits the scene like a hand-written note.
    struct Quote: Hashable {
        let firstLine: String
        let secondLine: String
        let theme: Theme

        /// The whole quote as one sentence, for VoiceOver.
        var text: String { "\(firstLine) \(secondLine)" }
    }

    /// Today's quote (for `date`'s calendar day in the person's time zone).
    static func quote(for date: Date, calendar: Calendar = .current) -> Quote {
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        // Stepping by a number that shares no factor with the count visits every quote
        // once per cycle, and neighbouring days get different themes.
        let index = (day * step) % all.count
        return all[(index + all.count) % all.count]
    }

    private static let step = 29

    /// All quotes, theme by theme (16 per theme).
    static let all: [Quote] = happiness + productivity + gratitude + selfBelief
        + consistency + peacefulLiving + progress

    private static let happiness: [Quote] = quotes(.happiness, [
        ("Choose joy", "a little every day"),
        ("Smile first,", "the day follows"),
        ("Happiness grows", "where you water it"),
        ("Find the magic", "in little things"),
        ("Protect your joy,", "it's precious"),
        ("Laugh often,", "love deeply"),
        ("Sunshine starts", "on the inside"),
        ("Be the reason", "someone smiles"),
        ("Dance through", "the little moments"),
        ("Today is a gift,", "unwrap it gently"),
        ("Bloom where", "you are planted"),
        ("Collect happy", "moments today"),
        ("Joy is found", "in simple things"),
        ("Let your heart", "feel light today"),
        ("Kindness makes", "the day brighter"),
        ("Sprinkle a little", "sparkle today")
    ])

    private static let productivity: [Quote] = quotes(.productivity, [
        ("Dream it,", "plan it, do it"),
        ("Start small,", "finish strong"),
        ("One task", "at a time"),
        ("Focus on", "what matters most"),
        ("Done is better", "than perfect"),
        ("Your to-do list", "is your map today"),
        ("Begin now,", "shine later"),
        ("Plan the day,", "then enjoy it"),
        ("A clear plan", "makes a calm mind"),
        ("Tiny tasks", "add up to big wins"),
        ("Make today", "count"),
        ("Do it with love,", "do it well"),
        ("Start with", "the hardest thing"),
        ("Your effort", "is your superpower"),
        ("Organize the day,", "free your mind"),
        ("Work hard,", "rest well")
    ])

    private static let gratitude: [Quote] = quotes(.gratitude, [
        ("Grateful hearts", "shine brightest"),
        ("Count your", "blessings today"),
        ("Say thank you", "for small things"),
        ("Gratitude turns", "enough into plenty"),
        ("Notice the good,", "it is everywhere"),
        ("Thankful for", "this fresh start"),
        ("A grateful heart", "is a happy heart"),
        ("Today, find three", "things to love"),
        ("Cherish the people", "who love you"),
        ("Every sunrise", "is a new gift"),
        ("Look how far", "you have come"),
        ("Thank yourself", "for trying"),
        ("Little blessings", "are everywhere"),
        ("Gratitude makes", "today beautiful"),
        ("Be thankful", "for this moment"),
        ("Love what you have", "right now")
    ])

    private static let selfBelief: [Quote] = quotes(.selfBelief, [
        ("Believe in", "your own magic"),
        ("You are capable", "of amazing things"),
        ("Trust yourself,", "you know the way"),
        ("You are enough,", "just as you are"),
        ("Be brave,", "be you"),
        ("Your dreams", "are worth it"),
        ("Believe you can,", "and you will"),
        ("You are stronger", "than you think"),
        ("Shine in", "your own way"),
        ("Be proud", "of who you are"),
        ("Your voice", "matters"),
        ("You were made", "for great things"),
        ("Dream big,", "sparkle bright"),
        ("Believe in", "who you're becoming"),
        ("Chin up,", "you've got this"),
        ("Your light", "is beautiful")
    ])

    private static let consistency: [Quote] = quotes(.consistency, [
        ("Small steps", "every single day"),
        ("Keep going,", "you're growing"),
        ("Little by little", "becomes a lot"),
        ("Show up", "for yourself today"),
        ("Good habits", "grow good days"),
        ("Slow progress", "is still progress"),
        ("Keep planting", "little seeds"),
        ("Quiet days", "count too"),
        ("Consistency", "beats perfection"),
        ("Water your dreams", "every day"),
        ("One page,", "one day at a time"),
        ("Keep your promise", "to yourself"),
        ("Steady and kind", "wins the day"),
        ("Do a little,", "every day"),
        ("Roots grow", "before flowers"),
        ("Try again", "tomorrow, gently")
    ])

    private static let peacefulLiving: [Quote] = quotes(.peacefulLiving, [
        ("Breathe in,", "let it go"),
        ("Slow down,", "enjoy the view"),
        ("Peace begins", "with a deep breath"),
        ("Be gentle", "with yourself"),
        ("Rest is part", "of the journey"),
        ("Calm mind,", "happy heart"),
        ("Take a moment", "just for you"),
        ("Let today", "be soft and kind"),
        ("Find your calm", "in small moments"),
        ("Not everything", "needs to be rushed"),
        ("Quiet moments", "heal the heart"),
        ("Simplify,", "then smile"),
        ("Release what", "you can't control"),
        ("Stillness is", "a kind of strength"),
        ("Your pace", "is the right pace"),
        ("Make space", "for peace today")
    ])

    private static let progress: [Quote] = quotes(.progress, [
        ("Every step", "brings you closer"),
        ("Progress,", "not perfection"),
        ("You're further", "than yesterday"),
        ("Keep moving", "toward your dreams"),
        ("Small wins", "are still wins"),
        ("Today's effort", "is tomorrow's joy"),
        ("Growth takes time,", "and that's okay"),
        ("Look how much", "you've grown"),
        ("One more step,", "you're doing great"),
        ("Mistakes help", "you grow"),
        ("Every day", "is a fresh start"),
        ("Celebrate", "each little win"),
        ("You're on", "your way"),
        ("Better every day,", "bit by bit"),
        ("Turn the page,", "begin again"),
        ("The best is", "still ahead")
    ])

    private static func quotes(_ theme: Theme, _ lines: [(String, String)]) -> [Quote] {
        lines.map { Quote(firstLine: $0.0, secondLine: $0.1, theme: theme) }
    }
}
