import SwiftUI

/// One way to open the journal, as a row: its icon, name and a line about it, with a
/// checkmark when it is the one in use.
struct JournalLockMethodRow: View {
    let method: JournalLockMethod
    var isOn = false
    /// Face ID needs Face ID, Touch ID or a passcode set up on the iPhone.
    var isAvailable = true

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: method.symbol)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(width: 38, height: 38)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(method.tint.gradient))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(method.title)
                    .font(.rounded(.body, weight: .bold))
                    .foregroundStyle(Palette.ink)
                Text(isAvailable ? method.detail : "Set up Face ID or a passcode on your iPhone first.")
                    .font(.rounded(.footnote, weight: .medium))
                    .foregroundStyle(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(isOn ? Palette.hotPink : Palette.inkSoft.opacity(0.35))
                .accessibilityHidden(true)
        }
        .padding(.vertical, 2)
        .opacity(isAvailable ? 1 : 0.5)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
    }
}

extension JournalLockMethod {
    /// The row icon's colour.
    var tint: Color {
        switch self {
        case .biometrics: Color(hex: 0x1FAE6A)
        case .pattern: Color(hex: 0x8B5CF6)
        case .passcode: Palette.hotPink
        }
    }
}

/// Turning the journal lock on or off, or changing how it opens. Anything but turning it on
/// first asks for the way it opens now; a new pattern or passcode is asked for twice.
struct JournalLockSetupSheet: View {
    enum Goal: Identifiable {
        case turnOn
        case turnOff
        case switchTo(JournalLockMethod)
        case changeSecret

        var id: String {
            switch self {
            case .turnOn: "on"
            case .turnOff: "off"
            case .switchTo(let method): "switch-\(method.rawValue)"
            case .changeSecret: "change"
            }
        }
    }

    private enum Step: Equatable {
        /// Picking how to open it (turning the lock on).
        case choose
        /// Opening it the way it opens now.
        case verify(JournalLockMethod)
        /// A new pattern or passcode.
        case create(JournalLockMethod)
        /// Face ID, to finish choosing it.
        case biometricCheck
    }

    let goal: Goal

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var step: Step
    @State private var biometricFailed = false
    @State private var problem: String?

    init(goal: Goal) {
        self.goal = goal
        if case .turnOn = goal {
            _step = State(initialValue: .choose)
        } else {
            _step = State(initialValue: .verify(JournalLock.effectiveMethod))
        }
    }

    /// The first step of turning the lock on, drawn as its design (see `JournalLockChooseView`).
    private var isChoosing: Bool { step == .choose }

    /// Choosing or checking a pattern or passcode: the pink lock screen from its designs.
    private var usesScene: Bool {
        switch step {
        case .create: true
        case .verify(let method): method.usesSecret
        default: false
        }
    }

    var body: some View {
        Group {
            if usesScene {
                sceneStep
            } else {
                VStack(spacing: 0) {
                    if !isChoosing {
                        header
                    }
                    ScrollView {
                        content
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                            .frame(maxWidth: .infinity)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
        }
        .background {
            if isChoosing {
                JournalLockChooseView.background.ignoresSafeArea()
            } else {
                MoodChooserStyle.background.ignoresSafeArea()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .task(id: step) {
            // Face ID asks by itself when its step appears.
            switch step {
            case .verify(.biometrics), .biometricCheck: await runBiometrics()
            default: break
            }
        }
        .alert("Journal lock", isPresented: Binding(get: { problem != nil }, set: { if !$0 { problem = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(problem ?? "")
        }
    }

    // MARK: Parts

    private var header: some View {
        HStack {
            Text(headerTitle)
                .font(.rounded(.title3, weight: .heavy))
                .foregroundStyle(MoodChooserStyle.title)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(MoodChooserStyle.close)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white))
                    .shadow(color: MoodChooserStyle.close.opacity(0.18), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel("Cancel")
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 8)
    }

    private var headerTitle: String {
        switch goal {
        case .turnOn: "Lock My Journal"
        case .turnOff: "Turn Off the Lock"
        case .switchTo(let method): "Use \(method.title)"
        case .changeSecret: JournalLockMethod.current == .pattern ? "Change Pattern" : "Change Passcode"
        }
    }

    @ViewBuilder
    private var sceneStep: some View {
        switch step {
        case .create(let method):
            JournalSecretCreate(method: method, onBack: backFromCreate) { secret in
                finish(method, secret: secret)
            }
        case .verify(let method):
            JournalLockScene(title: JournalLockView.title(method), subtitle: "Just to be sure it's you.",
                             ornament: method == .pattern ? .sparkHearts : .hearts, onBack: { dismiss() }) {
                JournalSecretCheck(method: method) { verified() }
            }
        default:
            EmptyView()
        }
    }

    /// ‹ while choosing a pattern or passcode: back to the three ways when turning the lock on.
    private func backFromCreate() {
        if case .turnOn = goal {
            withAnimation(.snappy) { step = .choose }
        } else {
            dismiss()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .choose:
            JournalLockChooseView(onPick: picked, onClose: { dismiss() })
                // Edge to edge, as in the design (the scroll view pads the other steps).
                .padding(.horizontal, -20)
                .padding(.top, -8)

        case .verify(let method):
            VStack(spacing: 14) {
                Text(verifyTitle(method))
                    .font(.rounded(.title3, weight: .heavy))
                    .foregroundStyle(JournalPagesStyle.heading)
                    .multilineTextAlignment(.center)
                Text("Just to be sure it's you.")
                    .font(.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(JournalStyle.soft)
                if method.usesSecret {
                    JournalSecretCheck(method: method) { verified() }
                        .padding(.top, 6)
                } else {
                    biometricButton
                }
            }

        case .create(let method):
            JournalSecretCreate(method: method) { secret in
                finish(method, secret: secret)
            }
            .padding(.top, 6)

        case .biometricCheck:
            VStack(spacing: 14) {
                JournalLockArt(size: 96)
                Text("Use \(JournalLock.methodName) to finish")
                    .font(.rounded(.title3, weight: .heavy))
                    .foregroundStyle(JournalPagesStyle.heading)
                    .multilineTextAlignment(.center)
                Text("Your journal will ask for \(JournalLock.methodName) each time you come back to the app.")
                    .font(.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(JournalStyle.soft)
                    .multilineTextAlignment(.center)
                biometricButton
            }
        }
    }

    private func verifyTitle(_ method: JournalLockMethod) -> String {
        switch method {
        case .biometrics: "First, unlock with \(JournalLock.methodName)"
        case .pattern: "First, draw your pattern"
        case .passcode: "First, enter your passcode"
        }
    }

    private var biometricButton: some View {
        VStack(spacing: 10) {
            Button {
                Task { await runBiometrics() }
            } label: {
                Label("Unlock with \(JournalLock.methodName)", systemImage: JournalLock.symbolName)
            }
            .buttonStyle(PillButtonStyle())
            .padding(.horizontal, 30)
            .padding(.top, 10)
            if biometricFailed {
                Text("Couldn't check it. Please try again.")
                    .font(.rounded(.footnote, weight: .semibold))
                    .foregroundStyle(LockPadState.wrong.color)
            }
        }
    }

    // MARK: Steps

    private func picked(_ method: JournalLockMethod) {
        withAnimation(.snappy) {
            step = method.usesSecret ? .create(method) : .biometricCheck
        }
    }

    /// The way it opens now was used: go on to what was asked for.
    private func verified() {
        switch goal {
        case .turnOn:
            withAnimation(.snappy) { step = .choose }
        case .turnOff:
            JournalLock.disable()
            appState.isJournalUnlocked = true
            Haptics.success()
            dismiss()
        case .switchTo(let method):
            picked(method)
        case .changeSecret:
            let current = JournalLockMethod.current
            withAnimation(.snappy) { step = current.usesSecret ? .create(current) : .biometricCheck }
        }
    }

    private func runBiometrics() async {
        biometricFailed = false
        guard JournalLock.canAuthenticate else {
            if case .verify = step {
                // Nothing on the iPhone to check against, just as on the lock screen.
                verified()
            } else {
                problem = "Face ID and the iPhone passcode are off on this iPhone. Choose Pattern or Number Passcode instead."
                withAnimation(.snappy) { step = .choose }
            }
            return
        }
        let reason = step == .biometricCheck ? "Lock your journal with \(JournalLock.methodName)" : "Confirm it's you"
        guard await JournalLock.authenticate(reason: reason) else {
            biometricFailed = true
            return
        }
        if step == .biometricCheck {
            finish(.biometrics, secret: nil)
        } else {
            verified()
        }
    }

    private func finish(_ method: JournalLockMethod, secret: String?) {
        guard JournalLock.enable(method, secret: secret) else {
            problem = "Your \(method == .pattern ? "pattern" : "passcode") couldn't be saved on this iPhone, so nothing was changed. Please try again."
            withAnimation(.snappy) { step = .create(method) }
            return
        }
        appState.isJournalUnlocked = true
        Haptics.success()
        dismiss()
    }
}

/// "Lock My Journal", as in its design: the picture at the top (the title "Lock My Journal" and
/// "Keep your thoughts private and safe 💗" in the design's own lettering, the pink journal with
/// its gold heart lock and the puppy with a pink bow among hearts, sparkles and flowers, on a
/// cloud; enlarged 4× with Real-ESRGAN, its ✕ and the words on the cloud taken out), then
/// "How would you like to open your journal?" on the cloud, and a row for each way: its icon
/// from the design (the green Face ID, purple dots and pink 123 tiles, each with a little heart),
/// its name and a line about it, hearts and sparkles, and a round choice button.
struct JournalLockChooseView: View {
    let onPick: (JournalLockMethod) -> Void
    let onClose: () -> Void

    @State private var chosen: JournalLockMethod?
    /// The sheet's width (the picture spans it).
    @State private var width: CGFloat = 402

    /// The sheet under the picture: the cloud's soft pink, a little deeper at the bottom.
    static let background = LinearGradient(colors: [Color(hex: 0xFDEDF3), Color(hex: 0xFDE7EF)],
                                           startPoint: .top, endPoint: .bottom)
    /// The picture's size, in pixels of the 1024-pixel-wide design.
    private static let heroSize = CGSize(width: 1024, height: 847)
    private static let navy = Color(hex: 0x0B0436)
    private static let soft = Color(hex: 0x7A6496)

    var body: some View {
        let k = width / Self.heroSize.width
        VStack(spacing: 0) {
            hero(width: width, k: k)
            VStack(spacing: 14 * k) {
                ForEach(JournalLockMethod.allCases) { method in
                    row(method)
                }
            }
            .padding(.horizontal, 48 * k)
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }

    private func hero(width w: CGFloat, k: CGFloat) -> some View {
        Image("LockChooseHero")
            .resizable()
            .frame(width: w, height: Self.heroSize.height * k)
            .accessibilityLabel("Lock My Journal. Keep your thoughts private and safe.")
            .accessibilityAddTraits(.isHeader)
            .overlay(alignment: .topTrailing) {
                // Where the design's ✕ is.
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(Color(hex: 0xE8237A))
                        .frame(width: 84 * k, height: 84 * k)
                        .background(Circle().fill(Color.white))
                        .shadow(color: Color(hex: 0xE8237A).opacity(0.15), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(PressScaleStyle())
                .padding(.trailing, 50 * k)
                .padding(.top, 7 * k)
                .accessibilityLabel("Cancel")
            }
            .overlay(alignment: .top) {
                // On the cloud, where the design writes them.
                VStack(spacing: 6) {
                    Text("How would you like to open your journal?")
                        .font(.rounded(size: max(39 * k, 17), weight: .heavy))
                        .foregroundStyle(Self.navy)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("You can change it any time in Settings.")
                        .font(.rounded(size: max(25 * k, 13), weight: .medium))
                        .foregroundStyle(Self.soft)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 600 * k)
                .padding(.top, 680 * k)
            }
    }

    private func row(_ method: JournalLockMethod) -> some View {
        let available = method.usesSecret || JournalLock.canAuthenticate
        let look = Self.look(method)
        return Button {
            guard chosen == nil else { return }
            Haptics.tap()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { chosen = method }
            Task {
                try? await Task.sleep(for: .seconds(0.25))
                onPick(method)
                chosen = nil
            }
        } label: {
            HStack(spacing: 14) {
                Image(look.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 50)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(method.title)
                        .font(.rounded(size: 18, weight: .heavy))
                        .foregroundStyle(Self.navy)
                    Text(available ? method.detail : "Set up Face ID or a passcode on your iPhone first.")
                        .font(.rounded(size: 14, weight: .medium))
                        .foregroundStyle(Self.soft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(look.deco)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 38)
                    .accessibilityHidden(true)
                ZStack {
                    Circle().fill(Color.white)
                    Circle().strokeBorder(Color(hex: 0x8569A0), lineWidth: 2.5)
                    if chosen == method {
                        Circle().fill(Color(hex: 0xE8237A)).padding(7)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 26, height: 26)
                .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(look.fill))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.white, lineWidth: 2))
            .shadow(color: Color(hex: 0xE58AAE).opacity(0.16), radius: 8, x: 0, y: 3)
            .opacity(available ? 1 : 0.5)
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(PressScaleStyle(scale: 0.97))
        .disabled(!available)
        .accessibilityElement(children: .combine)
    }

    /// Each row's icon, hearts and sparkles, and soft colour, as in the design.
    private static func look(_ method: JournalLockMethod) -> (icon: String, deco: String, fill: Color) {
        switch method {
        case .biometrics: ("LockMethodFaceID", "LockMethodDeco1", Color(hex: 0xF5F7F4))
        case .pattern: ("LockMethodPattern", "LockMethodDeco2", Color(hex: 0xF8E8FB))
        case .passcode: ("LockMethodPasscode", "LockMethodDeco3", Color(hex: 0xFDE6EE))
        }
    }
}
