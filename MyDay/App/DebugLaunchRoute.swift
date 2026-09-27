#if DEBUG
import Foundation

/// Debug builds only: `-screenshotRoute <name>` opens a screen at launch,
/// so `scripts/screenshots.sh` can capture every screen in the simulator.
enum DebugLaunchRoute {
    @MainActor
    static func apply(to router: Router, today: Date) {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-screenshotRoute"), index + 1 < arguments.count else { return }

        switch arguments[index + 1] {
        case "menu": router.isMenuOpen = true
        case "todos": router.open(.todos(today))
        case "priority": router.open(.priority(today))
        case "journal": router.open(.journal)
        case "calendar": router.tab = .calendar
        case "insights": router.tab = .insights
        case "settings": router.tab = .settings
        case "quickadd": router.sheet = .quickCapture
        default: break
        }
    }
}
#endif
