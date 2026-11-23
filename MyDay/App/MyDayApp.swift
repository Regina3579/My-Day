import SwiftUI
import SwiftData
import UserNotifications
import CloudKit

@main
struct MyDayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var router = Router()
    @State private var appState = AppState()
    /// The to-dos, priorities, templates and journal pages, on the iPhone and in iCloud.
    @State private var store = DataStore()
    /// When the "Enjoying My Day?" card asks for a rating.
    @State private var rating = RatingPrompt()
    /// Whether My Day Pro is active (asked of the App Store at launch and kept up to date).
    @State private var pro = MyDayPro()

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
                } else if store.isLaunching {
                    // A moment while the store opens, under the splash.
                    Color(hex: 0xFFF5FA).ignoresSafeArea()
                } else {
                    StoreSwitchingView(turningOn: store.syncsWithICloud)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: store.container == nil)
            .environment(router)
            .environment(appState)
            .environment(store)
            .environment(rating)
            .environment(pro)
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
        // Silent pushes tell the shared lists (and the iCloud store) that something changed.
        application.registerForRemoteNotifications()
        return true
    }

    /// The scene delegate below receives Shared Lists invitations.
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SharedListSceneDelegate.self
        return configuration
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}

/// Someone tapped an invitation to a shared list (in Messages, Mail or a link): with
/// `CKSharingSupported` in `Info.plist`, iOS opens My Day and hands the invitation here, while
/// running or at launch. They join the list, and it opens.
final class SharedListSceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let metadata = connectionOptions.cloudKitShareMetadata else { return }
        Task { @MainActor in await SharedListStore.shared.accept(metadata) }
    }

    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        Task { @MainActor in await SharedListStore.shared.accept(cloudKitShareMetadata) }
    }
}
