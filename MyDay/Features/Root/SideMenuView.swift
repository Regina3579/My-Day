import SwiftUI

/// The drawer that opens from the ☰ button on the home screen.
struct SideMenuView: View {
    @Environment(Router.self) private var router
    @AppStorage(Prefs.userName) private var userName = ""
    let today: Date
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 4) {
                    row("house.fill", "My Day", tint: Palette.hotPink) { router.goHome() }
                    row("checklist", "Today's To-Dos", tint: Palette.grape) { router.open(.todos(today)) }
                    row("star.fill", "Today's Priority", tint: Palette.honey) { router.open(.priority(today)) }
                    row("book.closed.fill", "My Journal", tint: Palette.hotPink) { router.open(.journal) }

                    Divider().padding(.vertical, 8)

                    row("calendar", "Calendar", tint: Palette.inkSoft) { router.tab = .calendar }
                    row("chart.bar.fill", "Insights", tint: Palette.inkSoft) { router.tab = .insights }
                    row("bell.fill", "Reminders", tint: Palette.inkSoft) { router.sheet = .reminders }
                    row("gearshape.fill", "Settings", tint: Palette.inkSoft) { router.tab = .settings }
                }
                .padding(14)
            }

            Text("A new day, a fresh start.\nYou got this! 💖")
                .font(.rounded(.footnote, weight: .semibold))
                .foregroundStyle(Palette.berry)
                .padding(.horizontal, 22)
                .padding(.bottom, 18)
        }
        .frame(width: 300)
        .frame(maxHeight: .infinity, alignment: .top)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0,
                                   bottomTrailingRadius: 30, topTrailingRadius: 30, style: .continuous)
                .fill(LinearGradient(colors: [Palette.petal, Palette.lilac], startPoint: .top, endPoint: .bottom))
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 4, y: 0)
                .ignoresSafeArea()
        }
        .gesture(
            DragGesture(minimumDistance: 20).onEnded { value in
                if value.translation.width < -60 { close() }
            }
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Greeting.text(name: userName))
                .font(.rounded(.title3, weight: .heavy))
            Text(today.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.rounded(.subheadline, weight: .semibold))
                .opacity(0.9)
        }
        .foregroundStyle(Color.white)
        .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 1)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .bottomLeading)
        .padding(18)
        .background {
            Color.clear
                .overlay(Image("HeroFriends").resizable().scaledToFill())
                .overlay(LinearGradient(colors: [.clear, Color.black.opacity(0.45)],
                                        startPoint: .center, endPoint: .bottom))
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0,
                                                  bottomTrailingRadius: 0, topTrailingRadius: 30,
                                                  style: .continuous))
                .ignoresSafeArea(edges: .top)
        }
    }

    private func row(_ icon: String, _ title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button {
            action()
            close()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 34, height: 34)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(tint.gradient))
                Text(title)
                    .font(.rounded(.body, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.inkSoft.opacity(0.5))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleStyle(scale: 0.97))
    }
}
