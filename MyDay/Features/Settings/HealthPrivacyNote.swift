import SwiftUI

/// Shown just before Apple Health asks for the steps: what My Day reads (only the day's step
/// count), what it never does, and that nothing leaves the iPhone. Continue goes on to Health's
/// own sheet; Not Now turns Show my steps off (Settings can turn it on again, and asks then).
struct HealthPrivacyNote: View {
    let onContinue: () -> Void
    let onNotNow: () -> Void

    private struct Point: Identifiable {
        let icon: String
        let tint: Color
        let title: String
        let text: String
        var id: String { title }
    }

    private static let points = [
        Point(icon: "figure.walk", tint: Palette.hotPink, title: "Only your step count",
              text: "My Day reads just the number of steps you walk each day, to show it on your journal pages."),
        Point(icon: "hand.raised.fill", tint: Palette.grape, title: "No other health data",
              text: "My Day never asks for your heart rate, sleep, workouts, weight or anything else in Health."),
        Point(icon: "iphone", tint: Color(hex: 0x2E9BF0), title: "It stays on your iPhone",
              text: "Your steps are never sent to us or to anyone else. We have no servers that collect your data."),
        Point(icon: "pencil.slash", tint: Palette.honey, title: "Health is never changed",
              text: "My Day only reads. It never writes, edits or deletes anything in Health."),
        Point(icon: "switch.2", tint: Palette.mint, title: "You're in control",
              text: "Turn it off any time in Settings → Show my steps, or in the Health app."),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Self.points) { point in
                        row(point)
                    }
                }
                .padding(18)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Palette.hotPink.opacity(0.08), radius: 12, x: 0, y: 4)

                Label("Security Promise: we don't send your data to our servers.", systemImage: "lock.shield")
                    .font(.rounded(.footnote, weight: .semibold))
                    .foregroundStyle(SecurityPromise.green)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 22)
            .padding(.top, 30)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) { buttons }
        .background(LinearGradient(colors: [Palette.petal, Palette.blush],
                                   startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Palette.bubblegum, Palette.hotPink],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 84, height: 84)
                    .shadow(color: Palette.hotPink.opacity(0.3), radius: 10, x: 0, y: 5)
                Image(systemName: "figure.walk")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(Color.white)
                Image(systemName: "lock.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(SecurityPromise.green))
                    .overlay(Circle().strokeBorder(Color.white, lineWidth: 2.5))
                    .offset(x: 30, y: 30)
            }
            .accessibilityHidden(true)
            Text("Your steps, kept private")
                .font(.rounded(.title2, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text("Next, Apple Health will ask if My Day may read your steps. Here is exactly what that means:")
                .font(.rounded(.subheadline, weight: .medium))
                .foregroundStyle(Palette.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func row(_ point: Point) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: point.icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(point.tint)
                .frame(width: 38, height: 38)
                .background(Circle().fill(point.tint.opacity(0.14)))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(point.title)
                    .font(.rounded(.subheadline, weight: .bold))
                    .foregroundStyle(Palette.ink)
                Text(point.text)
                    .font(.rounded(.footnote))
                    .foregroundStyle(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var buttons: some View {
        VStack(spacing: 6) {
            Button("Continue", action: onContinue)
                .buttonStyle(PillButtonStyle())
            Button("Not Now", action: onNotNow)
                .font(.rounded(.subheadline, weight: .semibold))
                .foregroundStyle(Palette.inkSoft)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .padding(.horizontal, 22)
        .padding(.top, 10)
        .background(Palette.blush.opacity(0.95).ignoresSafeArea())
    }
}

extension View {
    /// Shows `HealthPrivacyNote` while `isPresented`. Continue then asks Health for the steps;
    /// Not Now (or swiping the note away) turns Show my steps off.
    func healthPrivacyNote(isPresented: Binding<Bool>) -> some View {
        modifier(HealthPrivacyNoteModifier(isPresented: isPresented))
    }
}

private struct HealthPrivacyNoteModifier: ViewModifier {
    @Binding var isPresented: Bool
    @AppStorage(Prefs.showSteps) private var showSteps = true
    /// Continue was tapped: once the note is gone, Health's own sheet shows.
    @State private var continues = false

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented, onDismiss: {
            if continues {
                Task { await StepCounter.shared.requestAccess() }
            } else {
                showSteps = false
            }
            continues = false
        }) {
            HealthPrivacyNote(onContinue: {
                continues = true
                isPresented = false
            }, onNotNow: {
                isPresented = false
            })
        }
    }
}
