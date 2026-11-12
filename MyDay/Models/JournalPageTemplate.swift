import SwiftUI

/// A page to start from, in My Journal Pages → Templates: a heading, a few gentle prompts to
/// write under, and tags. Writing on it is like any new page.
enum JournalPageTemplate: String, CaseIterable, Identifiable, Hashable {
    case gratitude, reflection, dream, selfCare, letter, memory, goals, letItGo

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .gratitude: "🙏"
        case .reflection: "🌸"
        case .dream: "🌙"
        case .selfCare: "🛁"
        case .letter: "💌"
        case .memory: "📸"
        case .goals: "🎯"
        case .letItGo: "🎈"
        }
    }

    var name: String {
        switch self {
        case .gratitude: "Gratitude Page"
        case .reflection: "Daily Reflection"
        case .dream: "Dream Journal"
        case .selfCare: "Self-Care Check-in"
        case .letter: "Letter to Myself"
        case .memory: "Happy Memory"
        case .goals: "Goals & Wishes"
        case .letItGo: "Let It Go"
        }
    }

    var summary: String {
        switch self {
        case .gratitude: "Three good things, big or small."
        case .reflection: "How today went and what I learned."
        case .dream: "A dream I had, or a dream I have."
        case .selfCare: "How my body and heart feel."
        case .letter: "Kind words for the future me."
        case .memory: "A moment I never want to forget."
        case .goals: "What I'm working toward."
        case .letItGo: "Write down a worry and feel lighter."
        }
    }

    /// The page's heading.
    var heading: String {
        switch self {
        case .gratitude: "Grateful for today 🙏"
        case .reflection: "Looking back on my day 🌸"
        case .dream: "My dream 🌙"
        case .selfCare: "Taking care of me 🛁"
        case .letter: "Dear me 💌"
        case .memory: "A moment to remember 📸"
        case .goals: "My goals and wishes 🎯"
        case .letItGo: "Letting it go 🎈"
        }
    }

    /// The prompts written on the page, each followed by an empty line to write on.
    var starter: String {
        let prompts: [String] = switch self {
        case .gratitude: ["Three things I'm grateful for:\n1.\n2.\n3.", "Why they made me smile…"]
        case .reflection: ["What went well today…", "What was hard…", "Something I learned…"]
        case .dream: ["In my dream…", "How it made me feel…", "What I think it means…"]
        case .selfCare: ["My body feels…", "My heart feels…", "One kind thing I'll do for myself…"]
        case .letter: ["Dear me,", "I'm proud of you for…", "Please remember…", "With love, me 💖"]
        case .memory: ["Where I was…", "Who I was with…", "Why it was so special…"]
        case .goals: ["This week I want to…", "One small step I can take today…", "I will feel proud when…"]
        case .letItGo: ["Something on my mind…", "What I can control…", "What I can let go of…"]
        }
        return prompts.joined(separator: "\n\n") + "\n"
    }

    var tags: [String] {
        switch self {
        case .gratitude: ["Grateful"]
        case .reflection: ["Better Me"]
        case .dream: ["Dreams"]
        case .selfCare, .letItGo: ["Self-Care"]
        case .letter: ["Better Me", "Love"]
        case .memory: ["Happy Thoughts"]
        case .goals: ["Better Me", "Dreams"]
        }
    }

    /// The card's soft colour.
    var tint: Color {
        switch self {
        case .gratitude: Color(hex: 0xFFE3EF)
        case .reflection: Color(hex: 0xFCE4F6)
        case .dream: Color(hex: 0xE7E4FD)
        case .selfCare: Color(hex: 0xE2F4F7)
        case .letter: Color(hex: 0xFFE6EA)
        case .memory: Color(hex: 0xFFF1DE)
        case .goals: Color(hex: 0xE5F6E9)
        case .letItGo: Color(hex: 0xEAF0FE)
        }
    }
}
