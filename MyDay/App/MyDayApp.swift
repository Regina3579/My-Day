import SwiftUI
import SwiftData
import UserNotifications

@main
struct MyDayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var router = Router()
    @State private var appState = AppState()
    private let container: ModelContainer

    init() {
        Appearance.configure()
        container = Self.makeContainer()
        SoundEffects.preload()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .environment(appState)
                .tint(Palette.hotPink)
                .preferredColorScheme(.light)
        }
        .modelContainer(container)
    }

    /// On-device store for to-dos, priorities, journal pages and saved templates.
    private static func makeContainer() -> ModelContainer {
        let schema = Schema([TaskItem.self, Priority.self, JournalEntry.self, JournalPhoto.self, JournalVoiceNote.self,
                             TaskTemplate.self, CustomCategory.self])
        let configuration = ModelConfiguration("MyDay", schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not open the My Day store: \(error)")
        }
    }
}

/// Lets reminder banners appear even while My Day is open.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
