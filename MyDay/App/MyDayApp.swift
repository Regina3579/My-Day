import SwiftUI
import SwiftData
import UserNotifications

@main
struct MyDayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var router = Router()
    @State private var appState = AppState()
    /// The to-dos, priorities, templates and journal pages, on the iPhone and in iCloud.
    @State private var store = DataStore()
    /// When the "Enjoying My Day?" card asks for a rating.
    @State private var rating = RatingPrompt()

    init() {
        Appearance.configure()
        SoundEffects.preload()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let container = store.container {
                    RootView()
                        // Opened again (Sync with iCloud switched): every screen starts afresh.
                        .id(store.generation)
                        .modelContainer(container)
                } else {
                    StoreSwitchingView(turningOn: store.syncsWithICloud)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: store.container == nil)
            .environment(router)
            .environment(appState)
            .environment(store)
            .environment(rating)
            .launchSplash()
            .tint(Palette.hotPink)
            .preferredColorScheme(.light)
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
