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

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                content
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(MoodChooserStyle.background.ignoresSafeArea())
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
    private var content: some View {
        switch step {
        case .choose:
            VStack(spacing: 14) {
                JournalLockArt(size: 96)
                Text("How would you like to open your journal?")
                    .font(.rounded(.title3, weight: .heavy))
                    .foregroundStyle(JournalPagesStyle.heading)
                    .multilineTextAlignment(.center)
                Text("You can change it any time here in Settings.")
                    .font(.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(JournalStyle.soft)
                    .multilineTextAlignment(.center)
                VStack(spacing: 10) {
                    ForEach(JournalLockMethod.allCases) { method in
                        let available = method.usesSecret || JournalLock.canAuthenticate
                        Button {
                            picked(method)
                        } label: {
                            JournalLockMethodRow(method: method, isAvailable: available)
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.white.opacity(0.92)))
                                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(Color.white, lineWidth: 1.5))
                                .shadow(color: JournalStyle.pink.opacity(0.12), radius: 8, x: 0, y: 3)
                        }
                        .buttonStyle(PressScaleStyle(scale: 0.97))
                        .disabled(!available)
                    }
                }
                .padding(.top, 6)
            }

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
        JournalLock.enable(method, secret: secret)
        appState.isJournalUnlocked = true
        Haptics.success()
        dismiss()
    }
}
