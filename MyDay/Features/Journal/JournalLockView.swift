import SwiftUI

/// Shown instead of the journal while it is locked: Face ID (or Touch ID, or the iPhone
/// passcode), the pattern, or the number passcode, whichever was chosen in Settings.
struct JournalLockView: View {
    @Environment(AppState.self) private var appState
    @Environment(Router.self) private var router
    @Environment(\.hostTab) private var hostTab
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Prefs.journalLockMethod) private var methodRaw = JournalLockMethod.biometrics.rawValue
    @State private var failed = false

    /// The chosen method, or Face ID when its pattern or passcode is missing (see
    /// `JournalLock.effectiveMethod`).
    private var method: JournalLockMethod {
        let chosen = JournalLockMethod(rawValue: methodRaw) ?? .biometrics
        return chosen.usesSecret && !JournalSecretStore.hasSecret(for: chosen) ? .biometrics : chosen
    }

    var body: some View {
        let method = self.method
        JournalLockScene(title: Self.title(method), subtitle: Self.subtitle(method),
                         ornament: method == .pattern ? .sparkHearts : .hearts,
                         onBack: { dismiss() }) {
            if method.usesSecret {
                JournalSecretCheck(method: method) {
                    withAnimation { appState.isJournalUnlocked = true }
                }
            } else {
                VStack(spacing: 12) {
                    Button(action: unlock) {
                        Label("Unlock with \(JournalLock.methodName)", systemImage: JournalLock.symbolName)
                    }
                    .buttonStyle(PillButtonStyle())
                    .padding(.horizontal, 40)
                    if failed {
                        Text("Couldn't unlock. Please try again.")
                            .font(.rounded(.footnote, weight: .medium))
                            .foregroundStyle(Palette.hotPink)
                    }
                }
                .padding(.top, 10)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        // Full screen, as in the designs: no tab bar under the pad.
        .onAppear { router.setFullScreen(true, in: hostTab) }
        .onDisappear { router.setFullScreen(false, in: hostTab) }
        .task {
            if !method.usesSecret { unlock() }
        }
    }

    static func title(_ method: JournalLockMethod) -> String {
        switch method {
        case .biometrics: "My Journal is Locked"
        case .pattern: "Draw Your Pattern"
        case .passcode: "Enter Your Passcode"
        }
    }

    static func subtitle(_ method: JournalLockMethod) -> String {
        switch method {
        case .biometrics: "Your thoughts are safe and private. 💖"
        case .pattern: "Connect at least 4 dots to unlock your journal."
        case .passcode: "Type your 4- or 6-digit number\nto unlock your journal."
        }
    }

    private func unlock() {
        // Without Face ID or a passcode on the iPhone there is nothing to check against.
        guard JournalLock.canAuthenticate else {
            appState.isJournalUnlocked = true
            return
        }
        Task {
            let success = await JournalLock.authenticate(reason: "Unlock your journal")
            withAnimation { appState.isJournalUnlocked = success }
            failed = !success
        }
    }
}

/// The golden padlock with a heart, on a soft white circle.
struct JournalLockArt: View {
    var size: CGFloat = 150

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.75))
                .frame(width: size, height: size)
                .shadow(color: Palette.hotPink.opacity(0.3), radius: size * 0.13)
            Image(systemName: "lock.fill")
                .font(.system(size: size * 0.43))
                .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFFD66B), Color(hex: 0xE8A21C)],
                                                startPoint: .top, endPoint: .bottom))
            Image(systemName: "heart.fill")
                .font(.system(size: size * 0.15))
                .foregroundStyle(Palette.hotPink)
                .offset(y: size * 0.08)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Checking the pattern or passcode

/// Asks for the pattern or passcode and says what went wrong ("Wrong pattern. 2 tries
/// left."), or how long to wait after too many tries. "Forgot?" opens it with Face ID or the
/// iPhone passcode instead.
struct JournalSecretCheck: View {
    let method: JournalLockMethod
    let onSuccess: () -> Void

    @State private var dots: [Int] = []
    @State private var code = ""
    @State private var state: LockPadState = .normal
    @State private var message: String?
    @State private var waitUntil: Date? = JournalLock.waitUntil
    @State private var shakes = 0
    @State private var forgotProblem: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var noun: String { method == .pattern ? "pattern" : "passcode" }

    var body: some View {
        VStack(spacing: 16) {
            Group {
                if method == .pattern {
                    PatternPad(dots: $dots, state: $state, isDisabled: waitUntil != nil) { joined in
                        check(joined.map(String.init).joined(separator: "-"), dotCount: joined.count)
                    }
                } else {
                    PasscodePad(length: JournalLock.passcodeLength, code: $code, state: $state,
                                isDisabled: waitUntil != nil) { typed in
                        check(typed, dotCount: nil)
                    }
                }
            }
            .modifier(ShakeEffect(shakes: CGFloat(shakes)))

            statusLine
                .frame(minHeight: 22)

            JournalLockPillButton(title: method == .pattern ? "Forgot Pattern?" : "Forgot Passcode?", action: forgot)
        }
        .task(id: waitUntil) {
            guard let waitUntil else { return }
            try? await Task.sleep(for: .seconds(max(0, waitUntil.timeIntervalSinceNow)))
            guard !Task.isCancelled else { return }
            self.waitUntil = nil
            message = nil
            clear()
        }
        .alert("Forgot your \(noun)?", isPresented: Binding(get: { forgotProblem != nil },
                                                            set: { if !$0 { forgotProblem = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(forgotProblem ?? "")
        }
    }

    @ViewBuilder
    private var statusLine: some View {
        if let waitUntil {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let seconds = max(1, Int(waitUntil.timeIntervalSince(context.date).rounded(.up)))
                Text("Too many tries. Try again in \(Self.waitText(seconds)).")
            }
            .font(.rounded(.subheadline, weight: .bold))
            .foregroundStyle(LockPadState.wrong.color)
            .multilineTextAlignment(.center)
        } else {
            Text(message ?? " ")
                .font(.rounded(.subheadline, weight: .bold))
                .foregroundStyle(LockPadState.wrong.color)
                .multilineTextAlignment(.center)
        }
    }

    static func waitText(_ seconds: Int) -> String {
        seconds < 60 ? "\(seconds) seconds" : String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func check(_ secret: String, dotCount: Int?) {
        if let dotCount, dotCount < 4 {
            // Too short to be anyone's pattern: not counted as a try.
            fail("Join at least 4 dots.")
            return
        }
        switch JournalLock.attempt(secret, for: method) {
        case .success:
            state = .right
            message = nil
            Haptics.success()
            Task {
                try? await Task.sleep(for: .seconds(0.25))
                onSuccess()
            }
        case .wrong(let triesLeft):
            let wrong = method == .pattern ? "Wrong pattern." : "Wrong passcode."
            if triesLeft <= 2 {
                fail("\(wrong) \(triesLeft == 1 ? "1 try" : "\(triesLeft) tries") left.")
            } else {
                fail("\(wrong) Try again.")
            }
        case .waiting(let until):
            waitUntil = until
            fail(nil)
        }
    }

    private func fail(_ text: String?) {
        state = .wrong
        message = text
        Haptics.error()
        if reduceMotion {
            shakes += 1
        } else {
            withAnimation(.linear(duration: 0.45)) { shakes += 1 }
        }
        if let text {
            UIAccessibility.post(notification: .announcement, argument: text)
        }
        Task {
            try? await Task.sleep(for: .seconds(0.8))
            // Not if a new try has started meanwhile.
            if state == .wrong { clear() }
        }
    }

    private func clear() {
        dots = []
        code = ""
        state = .normal
    }

    private func forgot() {
        guard JournalLock.canAuthenticate else {
            forgotProblem = "To open your journal without your \(noun), first set up Face ID or a passcode on your iPhone (in the iPhone's Settings)."
            return
        }
        Task {
            if await JournalLock.authenticate(reason: "Open your journal without your \(noun)") {
                JournalLock.resetTries()
                waitUntil = nil
                message = nil
                Haptics.success()
                onSuccess()
            }
        }
    }
}

// MARK: - Choosing a new pattern or passcode

/// Choosing a new pattern or passcode: once, then again to confirm.
struct JournalSecretCreate: View {
    let method: JournalLockMethod
    /// The ‹ at the top.
    var onBack: (() -> Void)?
    let onDone: (String) -> Void

    @State private var first: String?
    @State private var dots: [Int] = []
    @State private var code = ""
    @State private var state: LockPadState = .normal
    @State private var message: String?
    @State private var length = 4
    @State private var shakes = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        JournalLockScene(title: title, subtitle: hint, ornament: method == .pattern ? .sparkHearts : .hearts,
                         onBack: onBack) {
            pads
        }
    }

    private var pads: some View {
        VStack(spacing: 14) {
            if let message {
                Text(message)
                    .font(.rounded(.subheadline, weight: .bold))
                    .foregroundStyle(LockPadState.wrong.color)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            if method == .passcode && first == nil {
                Picker("Digits", selection: $length) {
                    Text("4 digits").tag(4)
                    Text("6 digits").tag(6)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 240)
                .onChange(of: length) { _, _ in code = "" }
            }
            Group {
                if method == .pattern {
                    PatternPad(dots: $dots, state: $state) { joined in
                        submit(joined.map(String.init).joined(separator: "-"), dotCount: joined.count)
                    }
                } else {
                    PasscodePad(length: length, code: $code, state: $state) { typed in
                        submit(typed, dotCount: nil)
                    }
                }
            }
            .modifier(ShakeEffect(shakes: CGFloat(shakes)))
            .padding(.top, 4)
            if first != nil {
                JournalLockPillButton(title: "Start Over") {
                    withAnimation(.snappy) {
                        first = nil
                        message = nil
                        clear()
                    }
                }
            }
        }
    }

    private var title: String {
        switch (method, first == nil) {
        case (.pattern, true): "Draw Your Pattern"
        case (.pattern, false): "Draw It Again"
        case (_, true): "Choose Your Passcode"
        case (_, false): "Type It Again"
        }
    }

    private var hint: String {
        switch (method, first == nil) {
        case (.pattern, true): "Connect at least 4 dots to lock your journal."
        case (_, true): "Pick a \(length)-digit number to lock your journal."
        default: "Just to be sure you remember it."
        }
    }

    private func submit(_ secret: String, dotCount: Int?) {
        if let dotCount, dotCount < 4 {
            fail("Join at least 4 dots.")
            return
        }
        guard let first else {
            first = secret
            message = nil
            state = .right
            Haptics.tap()
            Task {
                try? await Task.sleep(for: .seconds(0.35))
                withAnimation(.snappy) { clear() }
            }
            return
        }
        if secret == first {
            state = .right
            Haptics.success()
            Task {
                try? await Task.sleep(for: .seconds(0.3))
                onDone(secret)
            }
        } else {
            self.first = nil
            fail(method == .pattern ? "That didn't match. Draw a new pattern." : "That didn't match. Choose a new passcode.")
        }
    }

    private func fail(_ text: String) {
        state = .wrong
        message = text
        Haptics.error()
        if reduceMotion {
            shakes += 1
        } else {
            withAnimation(.linear(duration: 0.45)) { shakes += 1 }
        }
        UIAccessibility.post(notification: .announcement, argument: text)
        Task {
            try? await Task.sleep(for: .seconds(0.8))
            if state == .wrong { clear() }
        }
    }

    private func clear() {
        dots = []
        code = ""
        state = .normal
    }
}

// MARK: - The pads

/// How a pad looks: pink while drawing or typing, red when wrong, green when right.
enum LockPadState: Equatable {
    case normal, wrong, right

    var color: Color {
        switch self {
        case .normal: JournalStyle.pink
        case .wrong: Color(hex: 0xE5484D)
        case .right: Color(hex: 0x1FAE6A)
        }
    }
}

/// Nine dots, three across: draw a pattern by joining them. A dot passed over on the way
/// between two others is joined too.
struct PatternPad: View {
    @Binding var dots: [Int]
    @Binding var state: LockPadState
    var isDisabled = false
    /// Called with the dots joined, in order, when the finger lifts.
    let onFinish: ([Int]) -> Void

    @State private var finger: CGPoint?
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { proxy in
                let side = min(proxy.size.width, proxy.size.height)
                board(cell: side / 3)
                    .frame(width: side, height: side)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 300)
            .opacity(isDisabled ? 0.45 : 1)
            .allowsHitTesting(!isDisabled)

            // With VoiceOver the dots are chosen one by one, then Done.
            if voiceOver && !dots.isEmpty && !isDisabled {
                Button("Done") { onFinish(dots) }
                    .font(.rounded(.headline, weight: .heavy))
                    .foregroundStyle(JournalStyle.pink)
            }
        }
    }

    private func board(cell: CGFloat) -> some View {
        let color = state.color
        return ZStack {
            Path { path in
                guard let first = dots.first else { return }
                path.move(to: center(first, cell: cell))
                for dot in dots.dropFirst() {
                    path.addLine(to: center(dot, cell: cell))
                }
                if let finger {
                    path.addLine(to: finger)
                }
            }
            .stroke(color.opacity(0.8), style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))
            .accessibilityHidden(true)

            ForEach(0..<9, id: \.self) { dot in
                dotView(dot, color: color)
                    .position(center(dot, cell: cell))
            }
        }
        .contentShape(Rectangle())
        .gesture(drag(cell: cell))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pattern dots")
    }

    /// A soft white button with a glossy pink heart, from the pattern's design; joined, it glows
    /// in the pad's colour.
    private func dotView(_ dot: Int, color: Color) -> some View {
        let isOn = dots.contains(dot)
        return ZStack {
            Circle()
                .fill(color.opacity(isOn ? 0.22 : 0))
                .frame(width: 74, height: 74)
                .blur(radius: 4)
            Image("LockPatternNode")
                .resizable()
                .scaledToFit()
                .frame(width: 66, height: 66)
            Circle()
                .strokeBorder(color.opacity(isOn ? 0.9 : 0), lineWidth: 3)
                .frame(width: 60, height: 60)
        }
        .frame(width: 74, height: 74)
        .scaleEffect(isOn ? 1.06 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isOn)
        .accessibilityElement()
        .accessibilityLabel("Dot \(dot + 1)")
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
        .accessibilityAction {
            guard !isOn else { return }
            if dots.isEmpty { state = .normal }
            add(dot)
        }
    }

    private func center(_ dot: Int, cell: CGFloat) -> CGPoint {
        CGPoint(x: (CGFloat(dot % 3) + 0.5) * cell, y: (CGFloat(dot / 3) + 0.5) * cell)
    }

    private func drag(cell: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                if finger == nil {
                    // A new try starts.
                    dots = []
                    state = .normal
                }
                finger = value.location
                if let dot = hit(value.location, cell: cell), !dots.contains(dot) {
                    add(dot)
                }
            }
            .onEnded { _ in
                finger = nil
                if !dots.isEmpty { onFinish(dots) }
            }
    }

    /// The dot under the finger, if it is close enough to one.
    private func hit(_ point: CGPoint, cell: CGFloat) -> Int? {
        let column = Int(point.x / cell)
        let row = Int(point.y / cell)
        guard (0..<3).contains(column), (0..<3).contains(row), point.x >= 0, point.y >= 0 else { return nil }
        let dot = row * 3 + column
        let middle = center(dot, cell: cell)
        return hypot(point.x - middle.x, point.y - middle.y) < cell * 0.34 ? dot : nil
    }

    private func add(_ dot: Int) {
        if let last = dots.last {
            let rows = (last / 3) + (dot / 3)
            let columns = (last % 3) + (dot % 3)
            if rows % 2 == 0, columns % 2 == 0 {
                let between = rows / 2 * 3 + columns / 2
                if !dots.contains(between) { dots.append(between) }
            }
        }
        dots.append(dot)
        Haptics.tap()
    }
}

/// A row of dots and a round number keypad, like the iPhone's.
struct PasscodePad: View {
    let length: Int
    @Binding var code: String
    @Binding var state: LockPadState
    var isDisabled = false
    /// Called when the last digit is typed.
    let onComplete: (String) -> Void

    private let keySize: CGFloat = 66
    private let rows = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"]]
    private static let berry = Color(hex: 0xA80B55)
    private static let keyHeart = Color(hex: 0xF58DB9)

    var body: some View {
        VStack(spacing: 22) {
            // As in the design: little hearts at each end of the row of circles.
            HStack(spacing: 14) {
                Image("LockDotOrnL").resizable().scaledToFit().frame(height: 26).accessibilityHidden(true)
                ForEach(0..<length, id: \.self) { index in
                    let isFilled = index < code.count
                    Circle()
                        .fill(isFilled
                              ? AnyShapeStyle(state == .normal
                                              ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xFF9CC8), Color(hex: 0xF0569B)],
                                                                             startPoint: .top, endPoint: .bottom))
                                              : AnyShapeStyle(state.color))
                              : AnyShapeStyle(Color.white.opacity(0.8)))
                        .overlay(Circle().strokeBorder(state == .normal ? Color(hex: 0xF3A3C6) : state.color, lineWidth: 2.5))
                        .frame(width: 24, height: 24)
                        .scaleEffect(isFilled ? 1.08 : 1)
                }
                Image("LockDotOrnR").resizable().scaledToFit().frame(height: 26).accessibilityHidden(true)
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: code)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(code.count) of \(length) digits entered")

            Grid(horizontalSpacing: 18, verticalSpacing: 10) {
                ForEach(rows, id: \.self) { row in
                    GridRow {
                        ForEach(row, id: \.self) { digit in
                            key(digit)
                        }
                    }
                }
                GridRow {
                    deleteKey
                    key("0")
                    doneKey
                }
            }
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.45 : 1)
        }
    }

    private func key(_ digit: String) -> some View {
        Button {
            guard code.count < length else { return }
            if state != .normal { state = .normal }
            code.append(digit)
            Haptics.tap()
            if code.count == length { onComplete(code) }
        } label: {
            VStack(spacing: 1) {
                Text(digit)
                    .font(.rounded(size: 30, weight: .heavy))
                    .foregroundStyle(Self.berry)
                Image(systemName: "heart.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Self.keyHeart)
            }
            .padding(.top, 4)
            .frame(width: keySize, height: keySize)
            .background(keyFace(lilac: false))
        }
        .buttonStyle(PressScaleStyle(scale: 0.9))
        .accessibilityLabel(digit)
    }

    /// A key from the design: a soft white bubble with a pink edge (lilac for ⌫ and the heart).
    private func keyFace(lilac: Bool) -> some View {
        Circle()
            .fill(RadialGradient(colors: lilac ? [Color(hex: 0xF6EEFD), Color(hex: 0xE6D4F8)]
                                               : [Color.white, Color(hex: 0xFDECF3)],
                                 center: .init(x: 0.4, y: 0.3), startRadius: 2, endRadius: keySize * 0.7))
            .overlay(Circle().strokeBorder(lilac ? Color(hex: 0xD9BEF2) : Color(hex: 0xF7C8DB), lineWidth: 2))
            .shadow(color: Color(hex: 0xE58AAE).opacity(0.22), radius: 6, x: 0, y: 3)
    }

    private var deleteKey: some View {
        Button {
            if !code.isEmpty { code.removeLast() }
        } label: {
            Image(systemName: "delete.left")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color(hex: 0x8A63B8))
                .frame(width: keySize, height: keySize)
                .background(keyFace(lilac: true))
        }
        .buttonStyle(PressScaleStyle(scale: 0.9))
        .disabled(code.isEmpty)
        .accessibilityLabel("Delete")
    }

    /// The pink heart: sends the passcode (it is sent by itself, too, once every digit is in).
    private var doneKey: some View {
        Button {
            if code.count == length {
                onComplete(code)
            } else {
                Haptics.tap()
            }
        } label: {
            Image(systemName: "heart.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFF7DB9), Color(hex: 0xF0418E)],
                                                startPoint: .top, endPoint: .bottom))
                .frame(width: keySize, height: keySize)
                .background(keyFace(lilac: true))
        }
        .buttonStyle(PressScaleStyle(scale: 0.9))
        .accessibilityLabel("Done")
    }
}

/// A quick side-to-side shake, for a wrong pattern or passcode.
struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 9 * sin(shakes * .pi * 4), y: 0))
    }
}
