import SwiftUI

/// The floating pink + button. Its plus turns into a close mark while the menu is open.
struct QuickAddButton: View {
    let isOpen: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color(hex: 0xFF62A5), Palette.hotPink, Color(hex: 0xDD1067)],
                                         center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: 46))
                Circle()
                    .strokeBorder(Color.white.opacity(0.95), lineWidth: 3)
                Image(systemName: "plus")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.white)
                    .rotationEffect(.degrees(isOpen ? 45 : 0))
            }
            .frame(width: 62, height: 62)
            .shadow(color: Palette.hotPink.opacity(0.55), radius: 12, x: 0, y: 4)
            .contentShape(Circle())
        }
        .buttonStyle(PressScaleStyle(scale: 0.9))
        .accessibilityLabel(isOpen ? "Close quick add" : "Quick add")
        .accessibilityHint(isOpen ? "" : "Add a task, a priority or a journal page")
    }
}

/// The small floating menu above the + button.
struct QuickAddMenu: View {
    let onTask: () -> Void
    let onPriority: () -> Void
    let onJournal: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            QuickAddChip(kind: .task, action: onTask)
            QuickAddChip(kind: .priority, action: onPriority)
            QuickAddChip(kind: .journal, action: onJournal)
        }
        .overlay(alignment: .bottomTrailing) {
            // Little pointer towards the + button.
            ChipTail()
                .fill(Color.white)
                .frame(width: 16, height: 9)
                .offset(x: -23, y: 8)
                .accessibilityHidden(true)
        }
    }
}

struct QuickAddChip: View {
    enum Kind {
        case task, priority, journal

        var title: String {
            switch self {
            case .task: "Add Task"
            case .priority: "Add Priority"
            case .journal: "Add Journal"
            }
        }
    }

    let kind: Kind
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 12) {
                icon.frame(width: 28, height: 28)
                Text(kind.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(width: 176, height: 50)
            .background(Capsule().fill(Color.white))
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
            .contentShape(Capsule())
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(kind.title)
    }

    @ViewBuilder
    private var icon: some View {
        switch kind {
        case .task:
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Palette.mint.gradient)
                .frame(width: 25, height: 25)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(Color.white)
                )
        case .priority:
            Image(systemName: "star.fill")
                .font(.system(size: 24))
                .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFFD84A), Palette.honey],
                                                startPoint: .top, endPoint: .bottom))
        case .journal:
            Image(systemName: "book.closed.fill")
                .font(.system(size: 22))
                .foregroundStyle(Palette.hotPink)
        }
    }
}

private struct ChipTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
