import Foundation
import SwiftData
import UIKit

/// Moves unfinished to-dos from earlier days onto today.
enum DayRollover {
    @MainActor
    static func carryOver(into today: Date, context: ModelContext) {
        let start = today.startOfDay
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.isDone == false && $0.day < start }
        )
        guard let stale = try? context.fetch(descriptor), !stale.isEmpty else { return }
        let now = Date()
        for task in stale {
            task.day = start
            if let reminder = task.reminderAt, reminder < now {
                task.reminderAt = nil
            }
        }
    }
}

/// A friendly first page so a brand-new app never looks empty.
enum WelcomeContent {
    @MainActor
    static func seedIfNeeded(in context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Prefs.didSeedWelcome) else { return }
        defaults.set(true, forKey: Prefs.didSeedWelcome)

        let existing = (try? context.fetchCount(FetchDescriptor<TaskItem>())) ?? 0
        guard existing == 0 else { return }

        let today = Date()
        context.insert(TaskItem(title: "Tap the circle to finish a to-do ✓", day: today))
        context.insert(TaskItem(title: "Star a to-do to make it today's priority ⭐", day: today, isPriority: true))
        context.insert(TaskItem(title: "Write my first journal page 📔", day: today))
        context.insert(JournalEntry(
            date: today,
            title: "Welcome to My Day 💖",
            body: "This is my little place for plans, priorities and beautiful moments.\n\nA new day, a fresh start — I've got this!",
            mood: .happy
        ))
    }
}

/// Shrinks picked photos so the journal stays light.
enum PhotoProcessor {
    struct Output {
        let photo: Data
        let thumbnail: Data
    }

    static func prepare(_ data: Data) -> Output? {
        guard let image = UIImage(data: data),
              let photo = resized(image, maxSide: 1600).jpegData(compressionQuality: 0.82),
              let thumbnail = resized(image, maxSide: 360).jpegData(compressionQuality: 0.75)
        else { return nil }
        return Output(photo: photo, thumbnail: thumbnail)
    }

    /// Redraws the image upright and no larger than `maxSide` pixels.
    private static func resized(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let factor = min(1, maxSide / max(pixelWidth, pixelHeight))
        let target = CGSize(width: (pixelWidth * factor).rounded(), height: (pixelHeight * factor).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
