import SwiftUI
import SwiftData

/// Colours of My Journal Pages, sampled from the design and made a little more vivid.
enum JournalPagesStyle {
    static let title = Color(hex: 0xC2127A)          // "My Pages"
    static let heading = Color(hex: 0x1C1A5E)        // a page's heading
    static let preview = Color(hex: 0x5E4A8C)        // a page's first lines
    static let time = Color(hex: 0x6F6790)
    static let weekday = Color(hex: 0xD61F7E)        // "Tue" on the date
    static let heartPink = Color(hex: 0xFF4FA3)
    static let calendarFill = Color(hex: 0xF6ECFF)
    static let cardFill = LinearGradient(colors: [Color.white.opacity(0.95), Color(hex: 0xFFF6FA)],
                                         startPoint: .top, endPoint: .bottom)
    static let writeButton = LinearGradient(colors: [Color(hex: 0xFF7DBE), Color(hex: 0xF5238F)],
                                            startPoint: .top, endPoint: .bottom)
}

extension View {
    /// A card of My Journal Pages: soft white (in Heavenly Angel Wishes, cream with gold edges;
    /// in Enchanted Fairy Garden, cream with vines round two corners; in Rainbow Glow Unicorn,
    /// white fading to pink).
    func journalPagesCard(padding: CGFloat = 14, radius: CGFloat = 26) -> some View {
        modifier(JournalPagesCard(padding: padding, radius: radius))
    }
}

private struct JournalPagesCard: ViewModifier {
    @Environment(\.journalTheme) private var theme
    let padding: CGFloat
    let radius: CGFloat

    func body(content: Content) -> some View {
        let card = content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
        switch theme {
        case .heavenlyAngelWishes:
            card.background(HeavenlyCardBackground(radius: radius))
        case .enchantedFairyGarden:
            card.background(FairyCardBackground(radius: radius))
        case .rainbowGlowUnicorn:
            card.background(UnicornCardBackground(radius: radius))
        case .roseGoldElegance:
            card.background(RoseCardBackground(radius: radius))
        case .cozyRainyDay:
            card.background(RainyCardBackground(radius: radius))
        case .candyCloudKingdom:
            // More room at the top, under the icing.
            card
                .padding(.top, 10)
                .background(CandyCardBackground(radius: radius))
        case .blushBlossom:
            // The glow belongs to the card's shape (not its words and stars), drawn once.
            let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
            card.background(
                shape
                    .fill(JournalPagesStyle.cardFill)
                    .overlay(shape.strokeBorder(Color.white, lineWidth: 1.5))
                    .shadow(color: JournalStyle.pink.opacity(0.12), radius: 10, x: 0, y: 4)
                    .renderedOnce(bleed: 16)
            )
        }
    }
}

// MARK: - Write a new page

/// The star waving beside the big pink "✏️ Write a new page ›" (in Heavenly Angel Wishes, an
/// angel hugging a heart, on a gold-edged card; in Enchanted Fairy Garden, a fairy asleep on a
/// mushroom and a butterfly on the button; in Rainbow Glow Unicorn, a unicorn peeking over a
/// cloud). A journal is one page a day, so once today has a page it reads "Continue writing"
/// and opens that page.
struct WriteNewPageRow: View {
    /// Today's page, when it has been written.
    let todayPage: JournalEntry?
    @Environment(\.journalTheme) private var theme

    var body: some View {
        switch theme {
        case .heavenlyAngelWishes:
            // Heavenly Angel Wishes: the angel hugging a heart, on a gold-edged card.
            HStack(spacing: 2) {
                Image("HeavenlyWriteAngel")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 88, height: 80)
                    .overlay(alignment: .topLeading) { heavenlyHeart(size: 13).offset(x: -2, y: 8) }
                    .overlay(alignment: .topTrailing) { heavenlyHeart(size: 12).offset(x: 4, y: 4) }
                    .accessibilityHidden(true)
                button
            }
            .padding(.leading, 6)
            .padding(.trailing, 10)
            .padding(.vertical, 8)
            .background(HeavenlyCardBackground(radius: 30))
            .overlay(alignment: .bottomLeading) {
                HeavenlyStarView(size: 20).rotationEffect(.degrees(-10)).offset(x: -8, y: 8)
            }
        case .enchantedFairyGarden:
            HStack(spacing: 0) {
                Image("FairyWriteFairy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 92)
                    .accessibilityHidden(true)
                button
                    .overlay(alignment: .topTrailing) {
                        Image("FairyButterflyPink")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 26)
                            .rotationEffect(.degrees(12))
                            .offset(x: 2, y: -14)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
            }
        case .roseGoldElegance:
            // Rose Gold Elegance: the star with a bow and hearts, on a rose-gold card.
            HStack(spacing: 2) {
                Image("RoseWriteStar")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 74)
                    .accessibilityHidden(true)
                button
            }
            .padding(.leading, 6)
            .padding(.trailing, 10)
            .padding(.vertical, 10)
            .background(RoseCardBackground(radius: 30))
        case .cozyRainyDay:
            // Cozy Rainy Day: the bunny under her pink umbrella.
            HStack(spacing: 2) {
                Image("RainyBunny")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 92, height: 76)
                    .accessibilityHidden(true)
                button
            }
        case .candyCloudKingdom:
            // Candy Cloud Kingdom: the bunny cloud with a pink bow and a star wand, hugging a
            // heart in front of the button's end.
            ZStack(alignment: .leading) {
                button
                    .padding(.leading, 52)
                Image("CandyWrite")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 82)
                    .offset(x: -6)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        case .rainbowGlowUnicorn:
            HStack(spacing: 0) {
                Image("UnicornWrite")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 88)
                    .accessibilityHidden(true)
                button
            }
        case .blushBlossom:
            HStack(spacing: 4) {
                Image("JournalWriteStar")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 72)
                    .accessibilityHidden(true)
                button
            }
        }
    }

    private func heavenlyHeart(size: CGFloat) -> some View {
        Image(systemName: "heart.fill")
            .font(.system(size: size))
            .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFF9ACB), Color(hex: 0xF5459A)],
                                            startPoint: .top, endPoint: .bottom))
            .shadow(color: Color.white, radius: 1)
            .renderedOnce(bleed: 3)
    }

    private var button: some View {
        NavigationLink(value: todayPage.map { AppRoute.editJournalPage($0) } ?? AppRoute.newJournalPage(nil)) {
            HStack(spacing: 10) {
                Image(systemName: "pencil.line")
                    .font(.system(size: 22, weight: .bold))
                Text(title)
                    .font(.rounded(.title3, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(JournalStyle.pink)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.white))
            }
            .foregroundStyle(Color.white)
            // Candy Cloud Kingdom: clear of the heart the bunny holds over the button's end.
            .padding(.leading, theme == .candyCloudKingdom ? 40 : 20)
            .padding(.trailing, 12)
            .frame(maxWidth: .infinity, minHeight: theme == .blushBlossom ? 66 : 58)
            .background {
                ZStack(alignment: .top) {
                    Capsule().fill(JournalPagesStyle.writeButton)
                    if theme == .candyCloudKingdom {
                        // Vanilla icing with sprinkles, dripping over the top of the button.
                        CandyIcing(band: 7, dripLength: 7, seed: 5)
                            .padding(.horizontal, 20)
                    }
                }
                .clipShape(Capsule())
            }
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.6), lineWidth: 1.5))
            .overlay(alignment: .topTrailing) {
                Image(systemName: "sparkle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .padding(.top, 9)
                    .padding(.trailing, 58)
                    .accessibilityHidden(true)
            }
            .overlay {
                if theme == .heavenlyAngelWishes {
                    Capsule().strokeBorder(HeavenlyStyle.goldEdge, lineWidth: 1.5)
                } else if theme == .roseGoldElegance {
                    Capsule().strokeBorder(RoseStyle.roseGold, lineWidth: 2)
                } else if theme == .candyCloudKingdom {
                    CandyStripes().mask(Capsule().strokeBorder(lineWidth: 4))
                }
            }
            .shadow(color: JournalStyle.pink.opacity(0.4), radius: 12, x: 0, y: 6)
            .renderedOnce(bleed: 22)
        }
        .buttonStyle(PressScaleStyle(scale: 0.97))
        .accessibilityLabel(todayPage == nil ? title : "Continue writing today's page")
    }

    /// Both fit the button: "Continue today's page" did not.
    private var title: String {
        todayPage == nil ? "Write a new page" : "Continue writing"
    }
}

// MARK: - My week in moods

/// The last seven days, each with the star of its latest page (tap one to open that page). In
/// Heavenly Angel Wishes a moon hangs on its corner, an angel peeks over it, and a day with no
/// page is a pink star with little wings; in Enchanted Fairy Garden a butterfly rests on it and
/// a day with no page is a pink flower with a face; in Rainbow Glow Unicorn a little winged
/// unicorn flies over its corner and a day with no page is a rainbow star with a face.
struct MoodWeekCard: View {
    let entries: [JournalEntry]
    let today: Date
    let onCalendar: () -> Void
    @Environment(\.journalTheme) private var theme

    private var heavenly: Bool { theme == .heavenlyAngelWishes }
    private var fairy: Bool { theme == .enchantedFairyGarden }

    var body: some View {
        let days = (0..<7).reversed().map { today.adding(days: -$0) }
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text("My week in moods")
                        .font(theme.headingFont(.headline))
                        .foregroundStyle(theme.headingColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(JournalPagesStyle.heartPink)
                        .accessibilityHidden(true)
                }
                .accessibilityAddTraits(.isHeader)
                .padding(.leading, heavenly ? 14 : 0)
                Spacer(minLength: 4)
                Button(action: onCalendar) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(JournalStyle.pink)
                        ViewThatFits(in: .horizontal) {
                            Text("View Calendar")
                            Text("Calendar")
                        }
                        .font(.rounded(.subheadline, weight: .bold))
                        .foregroundStyle(JournalStyle.plum)
                        .lineLimit(1)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(JournalStyle.purple)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: 38)
                    .background {
                        if heavenly {
                            Capsule()
                                .fill(LinearGradient(colors: [Color.white, Color(hex: 0xFDE4F1)],
                                                     startPoint: .top, endPoint: .bottom))
                                .overlay(Capsule().strokeBorder(HeavenlyStyle.goldEdge, lineWidth: 1.2))
                        } else if theme == .roseGoldElegance {
                            Capsule()
                                .fill(RoseStyle.calendarFill)
                                .overlay(Capsule().strokeBorder(RoseStyle.roseGold, lineWidth: 1.6))
                        } else if theme == .candyCloudKingdom {
                            Capsule()
                                .fill(CandyStyle.calendarFill)
                                .overlay(Capsule().strokeBorder(Color(hex: 0xF7A8CF), lineWidth: 1.5))
                                .overlay(Capsule().inset(by: 1.5).strokeBorder(Color.white, lineWidth: 1))
                        } else {
                            Capsule().fill(JournalPagesStyle.calendarFill)
                        }
                    }
                    .angelWings(width: 13, y: -3, isShown: heavenly)
                }
                .buttonStyle(PressScaleStyle())
                .padding(.trailing, heavenly ? 6 : 0)
                .accessibilityLabel("View Calendar")
            }
            HStack(spacing: 0) {
                ForEach(days, id: \.self) { day in
                    dayColumn(day)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .journalPagesCard()
        .overlay(alignment: .topLeading) {
            if heavenly {
                HeavenlyMoon()
                    .frame(width: 26, height: 30)
                    .rotationEffect(.degrees(-24))
                    .offset(x: -5, y: -9)
            }
        }
        .overlay(alignment: .topTrailing) {
            if heavenly {
                // Flying over the card's corner, clear of Calendar (her hand rests on the edge).
                Image("HeavenlyPeekAngel")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 53)
                    .offset(x: 14, y: -48)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if heavenly {
                HeavenlyStarView(size: 20).rotationEffect(.degrees(12)).offset(x: 8, y: 7)
            }
        }
        .overlay(alignment: .topTrailing) {
            if theme == .rainbowGlowUnicorn {
                // The design's little winged unicorn, whole, flying over the card's corner
                // (turned to face the page), clear of Calendar and Write a new page.
                Image("UnicornWinged")
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(x: -1, y: 1)
                    .frame(width: 52, height: 52)
                    .offset(x: 14, y: -42)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .overlay(alignment: .bottomLeading) {
            if theme == .roseGoldElegance {
                Image("RoseMoodsCorner")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 48)
                    .offset(x: -8, y: 8)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .overlay(alignment: .top) {
            if theme == .roseGoldElegance {
                GlossyHeart(size: 13)
                    .offset(x: 30, y: -7)
            }
        }
        .overlay(alignment: .topLeading) {
            if theme == .candyCloudKingdom {
                // A little rainbow on two clouds, sitting on the frosting.
                Image("CandyRainbowCloud")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 62, height: 45)
                    .offset(x: 4, y: -28)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .overlay(alignment: .bottomLeading) {
            if theme == .candyCloudKingdom {
                Image("CandyMoodsHearts")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .offset(x: -14, y: 16)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if theme == .candyCloudKingdom {
                Image("CandyMoodsLollipop")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 58)
                    .offset(x: 14, y: 14)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .overlay(alignment: .top) {
            if fairy {
                Image("FairyButterflyPink")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 25)
                    .rotationEffect(.degrees(-14))
                    .offset(x: 40, y: -13)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }

    @ViewBuilder
    private func dayColumn(_ day: Date) -> some View {
        if let page = entries.first(where: { $0.date.isSameDay(as: day) }) {
            NavigationLink(value: page) {
                dayLabel(day, mood: page.mood)
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel("\(day.formatted(.dateTime.weekday(.wide))): \(page.mood.label)")
        } else {
            dayLabel(day, mood: nil)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(day.formatted(.dateTime.weekday(.wide))): no page")
        }
    }

    private func dayLabel(_ day: Date, mood: Mood?) -> some View {
        VStack(spacing: 5) {
            Group {
                if let mood {
                    Image(mood.artName)
                        .resizable()
                        .scaledToFit()
                } else if heavenly {
                    WingedPinkStar()
                } else if fairy {
                    FairyFlowerFace(day: day)
                } else if theme == .rainbowGlowUnicorn {
                    UnicornFaceStar(day: day)
                        .frame(width: 40, height: 40)
                } else if theme == .roseGoldElegance {
                    RoseEmptyStar()
                } else if theme == .cozyRainyDay {
                    RainyCloudFace(day: day)
                        .frame(width: 46, height: 40)
                } else if theme == .candyCloudKingdom {
                    CandyEmptyStar()
                } else {
                    Image(systemName: "star.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(JournalStyle.pink.opacity(0.14))
                }
            }
            .frame(width: 46, height: 42)
            Text(day.formatted(.dateTime.weekday(.abbreviated)))
                .font(.rounded(.subheadline, weight: .bold))
                .foregroundStyle(day.isToday ? Color.white : JournalStyle.plum)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background {
                    if day.isToday {
                        Capsule().fill(JournalStyle.pinkGradient)
                    }
                }
        }
    }
}

// MARK: - Tabs

/// One row of tabs, left to right: All Pages, Favorites, My Feelings, Photos, Voice Notes and
/// ＋ More, which lists the rest (Little Wins, Templates, My Growth, Dreams and Trash). While
/// one of those is open, the ＋ tile shows it, with a small ＋ still on its icon.
struct JournalTabsRow: View {
    @Binding var selection: JournalShelf
    @Environment(\.journalTheme) private var theme

    var body: some View {
        // Six equal columns.
        grid
            .background(alignment: .bottom) {
                if theme == .enchantedFairyGarden {
                    // Enchanted Fairy Garden: a vine with flowers under the tabs, and mushrooms.
                    FairyVineLine(leafLength: 9)
                        .frame(height: 16)
                        .offset(y: 8)
                }
            }
            .overlay(alignment: .bottom) {
                if theme == .enchantedFairyGarden {
                    GeometryReader { proxy in
                        ForEach([2, 4], id: \.self) { column in
                            Image(column == 2 ? "FairyMushroomPink" : "FairyMushroomViolet")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 20)
                                .position(x: proxy.size.width * CGFloat(column) / 6, y: proxy.size.height - 6)
                        }
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
    }

    private var grid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 6), spacing: 0) {
            ForEach(JournalShelf.shown) { shelf in
                let isOn = shelf == selection
                Button {
                    select(shelf)
                } label: {
                    JournalTabTile(symbol: shelf.symbol, label: shelf.label, color: shelf.color, isOn: isOn)
                }
                .buttonStyle(PressScaleStyle(scale: 0.95))
                .accessibilityLabel(shelf.label)
                .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
            }
            moreMenu
        }
    }

    private var moreMenu: some View {
        let open = JournalShelf.more.contains(selection) ? selection : nil
        return Menu {
            ForEach(JournalShelf.more) { shelf in
                Button {
                    select(shelf)
                } label: {
                    Label(shelf.label, systemImage: shelf.symbol)
                }
            }
        } label: {
            JournalTabTile(symbol: open?.symbol ?? "plus", label: open?.label ?? "More",
                           color: open?.color ?? JournalStyle.pink, isOn: open != nil, showsPlus: open != nil)
        }
        .menuOrder(.fixed)
        .accessibilityLabel(open.map { "\($0.label). More tabs" } ?? "More tabs")
        .accessibilityHint("Little Wins, Templates, My Growth, Dreams and Trash")
        .accessibilityAddTraits(open != nil ? AccessibilityTraits.isSelected : [])
    }

    private func select(_ shelf: JournalShelf) {
        withAnimation(.snappy) { selection = shelf }
        Haptics.tap()
    }
}

/// A tab: a round icon over its name on one line, pink when it is the open tab. In Heavenly
/// Angel Wishes the icon has little wings.
private struct JournalTabTile: View {
    let symbol: String
    let label: String
    let color: Color
    let isOn: Bool
    /// A small ＋ on the icon, on the ＋ More tile while it shows one of the tabs behind it.
    var showsPlus = false
    @Environment(\.journalTheme) private var theme

    var body: some View {
        let heavenly = theme == .heavenlyAngelWishes
        let candy = theme == .candyCloudKingdom
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color.gradient)
                .frame(width: 30, height: 30)
                .background(Circle().fill(isOn ? Color.white : color.opacity(0.13)))
                .overlay(alignment: .topTrailing) {
                    if showsPlus {
                        Image(systemName: "plus")
                            .font(.system(size: 7, weight: .black))
                            .foregroundStyle(Color.white)
                            .frame(width: 13, height: 13)
                            .background(Circle().fill(JournalStyle.pink))
                            .overlay(Circle().strokeBorder(Color.white, lineWidth: 1.5))
                            .offset(x: 4, y: -3)
                    }
                }
                .angelWings(width: 11, tucked: 0.35, y: -1, isShown: heavenly)
            // Small enough for six across, clear of the tile's rim; a long name (Voice Notes) or a
            // narrow iPhone shrinks it a touch.
            Text(label)
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .foregroundStyle(isOn ? Color.white : JournalPagesStyle.heading)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 3)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 7)
        .padding(.bottom, 6)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(isOn ? AnyShapeStyle(JournalPagesStyle.writeButton)
                      : AnyShapeStyle(Color.white.opacity(candy ? 0 : 0.9)))
        )
        .background {
            if candy && !isOn {
                // Candy Cloud Kingdom: frosted, with icing and sprinkles.
                CandyCardBackground(radius: 15, seed: label.unicodeScalars.reduce(0) { $0 + Int($1.value) },
                                    ring: 5, stripes: false, icing: 6, dripLength: 4)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(isOn ? Color.white : heavenly ? Color(hex: 0xF9D7C6)
                              : theme == .enchantedFairyGarden ? Color(hex: 0xF6D6E4) : Color.white,
                              lineWidth: isOn ? 2 : 1.5)
        )
        .overlay {
            if theme == .roseGoldElegance {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .strokeBorder(RoseStyle.roseGold, lineWidth: 1.6)
                    .padding(-2)
            } else if candy && isOn {
                CandyGlowRim(shape: RoundedRectangle(cornerRadius: 17, style: .continuous), lineWidth: 2.4)
                    .padding(-2)
            }
        }
        .shadow(color: (heavenly && !isOn ? HeavenlyStyle.glow : JournalStyle.pink)
                    .opacity(isOn ? 0.3 : heavenly ? 0.1 : 0.08),
                radius: isOn ? 6 : 4, x: 0, y: isOn ? 3 : 2)
        .renderedOnce(bleed: 12)
        .contentShape(Rectangle())
    }
}

/// "📅 This Month ⌄": which dates the list shows.
struct JournalPeriodMenu: View {
    @Binding var period: JournalPeriod
    @Environment(\.journalTheme) private var theme

    var body: some View {
        let heavenly = theme == .heavenlyAngelWishes
        Menu {
            Picker("Show pages from", selection: $period) {
                ForEach(JournalPeriod.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(JournalStyle.purple)
                Text(period.label)
                    .font(.rounded(.subheadline, weight: .bold))
                    .foregroundStyle(JournalPagesStyle.heading)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(JournalStyle.purple)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 40)
            .background(Capsule().fill(Color.white.opacity(0.92)))
            .overlay {
                if heavenly {
                    Capsule().strokeBorder(HeavenlyStyle.goldEdge, lineWidth: 1.3)
                } else if theme == .roseGoldElegance {
                    Capsule().strokeBorder(RoseStyle.roseGold, lineWidth: 1.8)
                } else if theme == .candyCloudKingdom {
                    CandyGlowRim(shape: Capsule())
                } else {
                    Capsule().strokeBorder(JournalPagesStyle.calendarFill, lineWidth: 1.5)
                }
            }
            .shadow(color: (heavenly ? HeavenlyStyle.glow : JournalStyle.purple).opacity(heavenly ? 0.3 : 0.12),
                    radius: 5, x: 0, y: 2)
            .angelWings(width: 15, y: -3, isShown: heavenly)
            .renderedOnce(bleed: 18)
        }
        .accessibilityLabel("Show pages from: \(period.label)")
    }
}

// MARK: - A page in the list

/// A page, as in the design: its date under a ribbon bow, its star and heading, its first
/// lines, when it was written, its mood, a heart, its photos and ⋮. In Trash: Restore and
/// Delete Forever.
struct JournalEntryCard: View {
    let entry: JournalEntry
    var shelf: JournalShelf = .all

    @Environment(Router.self) private var router
    @Environment(\.hostTab) private var hostTab
    @Environment(\.modelContext) private var context
    @Environment(\.journalTheme) private var theme
    @State private var confirmDelete = false
    @State private var trashChoices = false
    @AppStorage(Prefs.showSteps) private var showSteps = true

    private var inTrash: Bool { entry.isInTrash }
    private var heavenly: Bool { theme == .heavenlyAngelWishes }
    private var blush: Bool { theme == .blushBlossom }

    var body: some View {
        Group {
            if inTrash {
                Button {
                    trashChoices = true
                } label: {
                    card
                }
                .buttonStyle(PressScaleStyle(scale: 0.98))
            } else {
                NavigationLink(value: entry) {
                    card
                }
                .buttonStyle(PressScaleStyle(scale: 0.98))
            }
        }
        .accessibilityActions {
            if inTrash {
                Button("Restore Page", action: restore)
                Button("Delete Forever") { confirmDelete = true }
            } else {
                Button(entry.isFavorite ? "Remove from Favorites" : "Add to Favorites") { entry.isFavorite.toggle() }
                Button("Edit Page") { router.push(.editJournalPage(entry), in: hostTab) }
                Button("Move to Trash") { JournalTrash.moveToTrash(entry) }
            }
        }
        .confirmationDialog(entry.displayTitle, isPresented: $trashChoices, titleVisibility: .visible) {
            Button("Restore Page", action: restore)
            Button("Delete Forever", role: .destructive) { confirmDelete = true }
        }
        .confirmationDialog("Delete this page forever?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Forever", role: .destructive, action: deleteForever)
        } message: {
            Text("This can't be undone.")
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                JournalDateTile(date: entry.date)
                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .center, spacing: 6) {
                        Image(entry.mood.artName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 30)
                            .accessibilityHidden(true)
                        Text(entry.displayTitle)
                            .font(heavenly ? HeavenlyStyle.serif(.headline) : .rounded(.headline, weight: .heavy))
                            .foregroundStyle(JournalPagesStyle.heading)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                        moreMenu
                    }
                    HStack(alignment: .top, spacing: 10) {
                        if !previewText.isEmpty {
                            Text(previewText)
                                .font(.rounded(.subheadline, weight: .medium))
                                .foregroundStyle(JournalPagesStyle.preview)
                                .lineSpacing(1)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                                .padding(.trailing, previewClearance)
                        }
                        Spacer(minLength: 0)
                    }
                    metaRow
                }
            }
            // The page's photos, as a row across the card.
            JournalCardPhotos(entry: entry)
        }
        .padding(12)
        .padding(.bottom, 2)
        // Candy Cloud Kingdom: room under the icing.
        .padding(.top, theme == .candyCloudKingdom ? 9 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            Group {
                switch theme {
                case .heavenlyAngelWishes: heavenlyBackground
                case .enchantedFairyGarden: fairyBackground
                case .rainbowGlowUnicorn: unicornBackground
                case .roseGoldElegance: roseBackground
                case .cozyRainyDay: rainyBackground
                case .candyCloudKingdom: candyBackground
                case .blushBlossom: blushBackground
                }
            }
            // The card's frame, pictures and glow, drawn once instead of on every frame of a scroll.
            .renderedOnce(bleed: 18)
        }
        .overlay(alignment: .bottomTrailing) {
            // The flowers would cover the last photo's corner.
            if blush && !inTrash && entry.sortedPhotos.isEmpty {
                Image("JournalFlowerCorner")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 44)
                    .offset(x: 4, y: 4)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .opacity(inTrash ? 0.9 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    /// Blush Blossom: soft white with a white edge and a pink glow.
    private var blushBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        return shape
            .fill(JournalPagesStyle.cardFill)
            .overlay(shape.strokeBorder(Color.white, lineWidth: 1.5))
            .shadow(color: JournalStyle.pink.opacity(0.12), radius: 10, x: 0, y: 4)
    }

    /// Heavenly Angel Wishes: gold edges, an angel hugging a star in the bottom corner (asleep or
    /// awake, day by day) and a star on the top edge.
    private var heavenlyBackground: some View {
        HeavenlyCardBackground(radius: 26)
            .overlay(alignment: .bottomTrailing) {
                if !inTrash {
                    Image(entry.date.dayNumber.isMultiple(of: 2) ? "HeavenlyCardAngelSleepy" : "HeavenlyCardAngelAwake")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 82, height: 76)
                        // Her cloud fades out just at the card's bottom edge.
                        .offset(x: 6, y: -1)
                        .accessibilityHidden(true)
                }
            }
            .overlay(alignment: .topTrailing) {
                HeavenlyStarView(size: 18).rotationEffect(.degrees(-8)).offset(x: -96, y: -9)
            }
    }

    /// Enchanted Fairy Garden: vines round two corners, and a fairy in the bottom corner (hugging
    /// her knees, or asleep on a mushroom, day by day).
    private var fairyBackground: some View {
        FairyCardBackground(radius: 26)
            .overlay(alignment: .bottomTrailing) {
                if !inTrash {
                    Image(entry.date.dayNumber.isMultiple(of: 2) ? "FairyCardFairyKnees" : "FairyCardFairyViolet")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 88, height: 72)
                        // The grass fades out just at the card's bottom edge.
                        .offset(x: 4, y: -1)
                        .accessibilityHidden(true)
                }
            }
    }

    /// Cozy Rainy Day: a cosy rainy scene on the card's right, fading in from the left (a puppy
    /// asleep under an umbrella with cocoa, or a kitten asleep on books among hydrangeas, day by
    /// day).
    private var rainyBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
        return ZStack(alignment: .trailing) {
            shape.fill(RainyStyle.cardFill)
            if !inTrash {
                Image(entry.date.dayNumber.isMultiple(of: 2) ? "RainySceneCocoa" : "RainySceneKitten")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 128)
                    .frame(maxHeight: .infinity)
                    .clipped()
                    .accessibilityHidden(true)
            }
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color.white, lineWidth: 1.5))
        .shadow(color: RainyStyle.glow.opacity(0.3), radius: 9, x: 0, y: 3)
    }

    /// Candy Cloud Kingdom: frosting, drips and sprinkles inside a candy-cane edge, and in the
    /// corner a candy castle with lollipops, or a bunny asleep in the clouds under a rainbow
    /// (day by day).
    private var candyBackground: some View {
        let day = entry.date.dayNumber
        return CandyCardBackground(radius: 26, seed: day,
                                   scene: inTrash ? nil : day.isMultiple(of: 2) ? "CandySceneCastle" : "CandySceneBunny")
    }

    /// Rose Gold Elegance: a rose-gold frame, with roses, leaves and a bow in the bottom corner.
    private var roseBackground: some View {
        RoseCardBackground(radius: 26)
            .overlay(alignment: .bottomTrailing) {
                if !inTrash {
                    Image("RoseCorner")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 64)
                        .offset(x: 6, y: 6)
                        .accessibilityHidden(true)
                }
            }
    }

    /// Rainbow Glow Unicorn: a unicorn in the bottom corner in front of a rainbow (hugging a heart
    /// cloud, or prancing, day by day).
    private var unicornBackground: some View {
        UnicornCardBackground(radius: 26)
            .overlay(alignment: .bottomTrailing) {
                if !inTrash {
                    ZStack(alignment: .bottomTrailing) {
                        RainbowArc(band: 4)
                            .frame(width: 80, height: 80)
                            .offset(x: -34, y: 22)
                        Image(entry.date.dayNumber.isMultiple(of: 2) ? "UnicornCardHug" : "UnicornCardPrance")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 84, height: 76)
                    }
                    .offset(x: 4, y: -1)
                    .accessibilityHidden(true)
                }
            }
    }

    /// Room beside the first lines for the picture in the card's corner (the angel, the fairy;
    /// Candy Cloud Kingdom's castle or bunny is wider).
    private var previewClearance: CGFloat {
        if blush || inTrash { return 0 }
        return theme == .candyCloudKingdom ? 84 : 60
    }

    /// The page's first lines, or on some tabs the line the tab is about.
    private var previewText: String {
        let body = entry.body.trimmed
        switch shelf {
        case .wins where entry.hasLittleWin: return "🏆 " + entry.littleWin.trimmed
        case .dreams where !entry.lookingForward.trimmed.isEmpty: return "🌙 " + entry.lookingForward.trimmed
        case .growth:
            if !entry.gratitude.trimmed.isEmpty { return "🙏 " + entry.gratitude.trimmed }
            if !entry.highlight.trimmed.isEmpty { return "⭐️ " + entry.highlight.trimmed }
        default: break
        }
        if !body.isEmpty { return body }
        return [entry.highlight, entry.gratitude, entry.littleWin].map(\.trimmed).first { !$0.isEmpty } ?? ""
    }

    private var metaRow: some View {
        HStack(spacing: 8) {
            if inTrash {
                Label(trashText, systemImage: "trash")
                    .font(.rounded(.footnote, weight: .semibold))
                    .foregroundStyle(JournalPagesStyle.time)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 13, weight: .semibold))
                    Text(entry.date.formatted(date: .omitted, time: .shortened))
                        .font(.rounded(.footnote, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(JournalPagesStyle.time)
                .fixedSize()
                MoodChip(mood: entry.mood)
                if showSteps {
                    StepsChip(date: entry.date, mood: entry.mood)
                }
                if entry.hasVoiceNotes {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(JournalStyle.purple)
                        .accessibilityLabel("Has voice notes")
                }
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { entry.isFavorite.toggle() }
                    Haptics.tap()
                } label: {
                    Image(systemName: entry.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(JournalPagesStyle.heartPink)
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressScaleStyle(scale: 0.8))
                .accessibilityLabel(entry.isFavorite ? "Remove from favorites" : "Add to favorites")
            }
            Spacer(minLength: 0)
        }
    }

    private var moreMenu: some View {
        Menu {
            if inTrash {
                Button(action: restore) {
                    Label("Restore Page", systemImage: "arrow.uturn.backward")
                }
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Label("Delete Forever", systemImage: "trash")
                }
            } else {
                Button {
                    router.push(.editJournalPage(entry), in: hostTab)
                } label: {
                    Label("Edit Page", systemImage: "pencil")
                }
                Button {
                    entry.isFavorite.toggle()
                    Haptics.tap()
                } label: {
                    Label(entry.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                          systemImage: entry.isFavorite ? "heart.slash" : "heart")
                }
                Button(role: .destructive) {
                    withAnimation(.snappy) { JournalTrash.moveToTrash(entry) }
                    Haptics.tap()
                } label: {
                    Label("Move to Trash", systemImage: "trash")
                }
            }
        } label: {
            Image(uiImage: PriorityMoreSymbol.image)
                .foregroundStyle(JournalStyle.plum)
                .frame(width: 30, height: 32)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("More for this page")
    }

    private var trashText: String {
        let trashedOn = entry.deletedAt ?? .now
        let daysIn = Calendar.current.dateComponents([.day], from: trashedOn.startOfDay, to: Date().startOfDay).day ?? 0
        let left = max(1, JournalTrash.keepDays - daysIn)
        return left == 1 ? "Deleted for good tomorrow" : "\(left) days left in Trash"
    }

    private var accessibilityText: String {
        var parts = [entry.date.formatted(date: .complete, time: .shortened), entry.displayTitle,
                     "Feeling \(entry.mood.label)"]
        if !previewText.isEmpty { parts.append(previewText) }
        let photos = (entry.photos ?? []).count
        if photos > 0 { parts.append(photos == 1 ? "1 photo" : "\(photos) photos") }
        if entry.isFavorite { parts.append("Favorite") }
        if inTrash { parts.append(trashText) }
        return parts.joined(separator: ", ")
    }

    private func restore() {
        withAnimation(.snappy) { JournalTrash.restore(entry) }
        Haptics.success()
    }

    private func deleteForever() {
        withAnimation(.snappy) { context.delete(entry) }
        Haptics.tap()
    }
}

/// The date on a page card: the day and weekday under a ribbon bow, pink, purple or blue (in
/// Heavenly Angel Wishes: with little wings, a gold moon and a star, edged in gold).
struct JournalDateTile: View {
    let date: Date
    @Environment(\.journalTheme) private var theme

    private enum Ribbon: Int {
        case pink, purple, blue

        var bow: String {
            switch self {
            case .pink: "JournalBowPink"
            case .purple: "JournalBowPurple"
            case .blue: "JournalBowBlue"
            }
        }

        var edge: Color {
            switch self {
            case .pink: Color(hex: 0xF7A6CD)
            case .purple: Color(hex: 0xCDB2F6)
            case .blue: Color(hex: 0xA9CCF4)
            }
        }

        var fill: Color {
            switch self {
            case .pink: Color(hex: 0xFFF0F6)
            case .purple: Color(hex: 0xF6F0FF)
            case .blue: Color(hex: 0xEFF6FF)
            }
        }
    }

    var body: some View {
        // Next days take turns: pink, purple, blue.
        let ribbon = Ribbon(rawValue: ((date.dayNumber % 3) + 3) % 3) ?? .pink
        Group {
            switch theme {
            case .heavenlyAngelWishes: heavenly(ribbon)
            case .enchantedFairyGarden: fairy(ribbon)
            case .rainbowGlowUnicorn: unicorn(ribbon)
            case .roseGoldElegance: roseGold(ribbon)
            case .cozyRainyDay: rainy(ribbon)
            case .candyCloudKingdom: candy(ribbon)
            case .blushBlossom: blush(ribbon)
            }
        }
        // Its frame, bow or lollipop and shadow, drawn once.
        .renderedOnce(bleed: 14)
    }

    /// Candy Cloud Kingdom: the date on a frosted tile with sprinkles, under a swirl lollipop
    /// (pink, lemon or blue, day by day), with a candy cane at its side.
    private func candy(_ ribbon: Ribbon) -> some View {
        VStack(spacing: 0) {
            Text(date.formatted(.dateTime.day()))
                .font(.rounded(.title, weight: .heavy))
                .foregroundStyle(Palette.berry)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.rounded(.subheadline, weight: .heavy))
                .foregroundStyle(JournalPagesStyle.weekday)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.top, 14)
        .frame(width: 64, height: 88)
        .background(CandyCardBackground(radius: 16, seed: date.dayNumber &+ 3, ring: 8, icing: 10, dripLength: 7))
        .overlay(alignment: .top) {
            Image(ribbon == .pink ? "CandyLollipopPink" : ribbon == .purple ? "CandyLollipopYellow" : "CandyLollipopBlue")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 46)
                .offset(x: -3, y: -30)
                .accessibilityHidden(true)
        }
        .overlay(alignment: .trailing) {
            Image("CandyCane")
                .resizable()
                .scaledToFit()
                .frame(width: 17, height: 28)
                .offset(x: 9, y: 10)
                .accessibilityHidden(true)
        }
        .padding(.top, 18)
    }

    /// Cozy Rainy Day: an umbrella over the date (pink, blue or purple, day by day) instead of
    /// the bow.
    private func rainy(_ ribbon: Ribbon) -> some View {
        VStack(spacing: 0) {
            Text(date.formatted(.dateTime.day()))
                .font(.rounded(.title, weight: .heavy))
                .foregroundStyle(Palette.berry)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.rounded(.subheadline, weight: .heavy))
                .foregroundStyle(JournalPagesStyle.weekday)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.top, 16)
        .frame(width: 64, height: 88)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [Color.white, ribbon.fill], startPoint: .top, endPoint: .bottom))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(ribbon.edge, lineWidth: 1.5)
        )
        .overlay(alignment: .top) {
            Image(ribbon == .pink ? "RainyUmbrellaPink" : ribbon == .purple ? "RainyUmbrellaPurple" : "RainyUmbrellaBlue")
                .resizable()
                .scaledToFit()
                .frame(width: 74, height: 42)
                .offset(x: 2, y: -20)
                .accessibilityHidden(true)
        }
        .padding(.top, 14)
        .shadow(color: ribbon.edge.opacity(0.35), radius: 4, x: 0, y: 2)
    }

    /// Rose Gold Elegance, as in its design: a blush tile framed in rose gold, crowned with the
    /// gold filigree heart (a pink jewel heart, little diamonds and pearls), with a diamond at
    /// its foot. Every day wears the same pink and gold.
    private func roseGold(_: Ribbon) -> some View {
        let tile = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return VStack(spacing: 0) {
            Text(date.formatted(.dateTime.day()))
                .font(.rounded(.title, weight: .heavy))
                .foregroundStyle(Palette.berry)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.rounded(.subheadline, weight: .heavy))
                .foregroundStyle(JournalPagesStyle.weekday)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.top, 20)
        .frame(width: 64, height: 92)
        .background(tile.fill(LinearGradient(colors: [Color(hex: 0xFFF8F4), Color(hex: 0xFCE6E0)],
                                             startPoint: .top, endPoint: .bottom)))
        .overlay(tile.strokeBorder(RoseStyle.roseGold, lineWidth: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(RoseStyle.goldLine.opacity(0.7), lineWidth: 0.8)
                .padding(4)
        )
        .overlay(alignment: .top) {
            Image("RoseDateCrown")
                .resizable()
                .scaledToFit()
                .frame(width: 78, height: 52)
                .offset(y: -34)
                .accessibilityHidden(true)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(LinearGradient(colors: [Color.white, Color(hex: 0xF3C9A2)], startPoint: .top, endPoint: .bottom))
                .frame(width: 7, height: 7)
                .rotationEffect(.degrees(45))
                .overlay(Rectangle().stroke(RoseStyle.goldLine, lineWidth: 0.8).rotationEffect(.degrees(45)))
                .offset(y: 4)
                .accessibilityHidden(true)
        }
        .padding(.top, 30)
        .shadow(color: RoseStyle.glow.opacity(0.35), radius: 4, x: 0, y: 2)
    }

    /// Rainbow Glow Unicorn: a cute rainbow cloud on top (a little rainbow resting on two smiling
    /// clouds) and little golden stars, with the day and weekday clear below.
    private func unicorn(_ ribbon: Ribbon) -> some View {
        VStack(spacing: 0) {
            Text(date.formatted(.dateTime.day()))
                .font(.rounded(.title, weight: .heavy))
                .foregroundStyle(Palette.berry)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.rounded(.subheadline, weight: .heavy))
                .foregroundStyle(JournalPagesStyle.weekday)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.top, 14)
        .frame(width: 64, height: 88)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [Color.white, ribbon.fill], startPoint: .top, endPoint: .bottom))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(ribbon.edge, lineWidth: 1.5)
        )
        .overlay(alignment: .top) {
            RainbowCloud()
                .frame(width: 58, height: 32)
                .offset(y: -17)
        }
        .overlay(alignment: .leading) {
            HeavenlyStarView(size: 10).offset(x: 3, y: -4)
        }
        .overlay(alignment: .trailing) {
            HeavenlyStarView(size: 11).offset(x: -3, y: -10)
        }
        .padding(.top, 10)
        .shadow(color: ribbon.edge.opacity(0.35), radius: 4, x: 0, y: 2)
    }

    /// Enchanted Fairy Garden: a little wooden frame with vines and flowers, a butterfly on top
    /// (pink, violet or blue, day by day) and a mushroom at its foot.
    private func fairy(_ ribbon: Ribbon) -> some View {
        VStack(spacing: 0) {
            Text(date.formatted(.dateTime.day()))
                .font(.system(.title, design: .serif, weight: .bold))
                .foregroundStyle(Palette.berry)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.rounded(.subheadline, weight: .heavy))
                .foregroundStyle(JournalPagesStyle.weekday)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.top, 8)
        .frame(width: 62, height: 82)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(FairyStyle.parchment))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(FairyStyle.wood, lineWidth: 2)
        )
        .overlay(FairyVines(radius: 14, reach: 0.5, leafLength: 7))
        .overlay(alignment: .top) {
            Image(ribbon == .pink ? "FairyButterflyPink" : ribbon == .purple ? "FairyButterflyViolet" : "FairyButterflyBlue")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 32)
                .offset(y: -24)
                .accessibilityHidden(true)
        }
        .overlay(alignment: .bottomTrailing) {
            Image(ribbon == .blue ? "FairyMushroomViolet" : "FairyMushroomPink")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 24)
                .offset(x: 9, y: 6)
                .accessibilityHidden(true)
        }
        .padding(.top, 12)
        .shadow(color: FairyStyle.glow.opacity(0.25), radius: 4, x: 0, y: 2)
    }

    private func heavenly(_ ribbon: Ribbon) -> some View {
        VStack(spacing: 0) {
            Text(date.formatted(.dateTime.day()))
                .font(.system(.title, design: .serif, weight: .bold))
                .foregroundStyle(Palette.berry)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.rounded(.subheadline, weight: .heavy))
                .foregroundStyle(JournalPagesStyle.weekday)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.top, 6)
        .frame(width: 62, height: 82)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: [Color.white, ribbon.fill], startPoint: .top, endPoint: .bottom))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(HeavenlyStyle.goldEdge, lineWidth: 1.3)
        )
        .angelWings(width: 16, tucked: 0.4, y: -18)
        .overlay(alignment: .topLeading) {
            HeavenlyMoon()
                .frame(width: 20, height: 22)
                .rotationEffect(.degrees(-20))
                .offset(x: 2, y: -11)
        }
        .overlay(alignment: .topTrailing) {
            HeavenlyStarView(size: 17).rotationEffect(.degrees(10)).offset(x: 5, y: -4)
        }
        .padding(.top, 8)
        .shadow(color: HeavenlyStyle.glow.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    private func blush(_ ribbon: Ribbon) -> some View {
        VStack(spacing: 0) {
            Text(date.formatted(.dateTime.day()))
                .font(.rounded(.title, weight: .heavy))
                .foregroundStyle(Palette.berry)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.rounded(.subheadline, weight: .heavy))
                .foregroundStyle(JournalPagesStyle.weekday)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.top, 16)
        .frame(width: 64, height: 88)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [Color.white, ribbon.fill], startPoint: .top, endPoint: .bottom))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(ribbon.edge, lineWidth: 1.5)
        )
        .overlay(alignment: .top) {
            Image(ribbon.bow)
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 34)
                .offset(y: -15)
                .accessibilityHidden(true)
        }
        .padding(.top, 8)
        .shadow(color: ribbon.edge.opacity(0.35), radius: 4, x: 0, y: 2)
    }
}

/// A page's photos on its card: up to three equal square photos with rounded corners, side by
/// side across the card (each a third of its width, even when there are fewer), with "+2" on the
/// third when there are more.
struct JournalCardPhotos: View {
    let entry: JournalEntry

    private static let gap: CGFloat = 8

    var body: some View {
        let images = entry.sortedPhotos.compactMap { photo in photo.thumbnailData.flatMap(UIImage.init(data:)) }
        if !images.isEmpty {
            HStack(spacing: Self.gap) {
                ForEach(0..<3, id: \.self) { index in
                    if index < images.count {
                        tile(images[index], more: index == 2 ? images.count - 3 : 0)
                    } else {
                        Color.clear.aspectRatio(1, contentMode: .fit).frame(maxWidth: .infinity)
                    }
                }
            }
            .renderedOnce(bleed: 8)
            .accessibilityElement()
            .accessibilityLabel(images.count == 1 ? "1 photo" : "\(images.count) photos")
        }
    }

    private func tile(_ image: UIImage, more: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return Color.clear
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .overlay(Image(uiImage: image).resizable().scaledToFill())
            .clipShape(shape)
            .overlay(shape.strokeBorder(Color.white.opacity(0.9), lineWidth: 1.5))
            .overlay {
                if more > 0 {
                    ZStack {
                        shape.fill(Color.black.opacity(0.35))
                        Text("+\(more)")
                            .font(.rounded(.title3, weight: .heavy))
                            .foregroundStyle(Color.white)
                    }
                }
            }
            .shadow(color: JournalStyle.pink.opacity(0.18), radius: 4, x: 0, y: 2)
    }
}

/// "⭐ Happy" in the mood's colours.
struct MoodChip: View {
    let mood: Mood

    var body: some View {
        let colors = mood.chooserColors
        HStack(spacing: 4) {
            Image(mood.artName)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 19)
            Text(mood.label)
                .font(.rounded(.footnote, weight: .bold))
                .foregroundStyle(colors.label)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.leading, 6)
        .padding(.trailing, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(colors.tile))
        .overlay(Capsule().strokeBorder(Color.white, lineWidth: 1))
    }
}

// MARK: - Search

/// "🔍 Search your journal… 💗" and Filter, floating over the pages.
struct JournalSearchBar: View {
    @Binding var text: String
    var focused: FocusState<Bool>.Binding
    /// How many filters are on (shown on the Filter button).
    let filterCount: Int
    let onFilter: () -> Void
    @Environment(\.journalTheme) private var theme

    var body: some View {
        let heavenly = theme == .heavenlyAngelWishes
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(JournalStyle.plum)
                    .accessibilityHidden(true)
                TextField("Search your journal…", text: $text)
                    .font(.rounded(.callout, weight: .medium))
                    .foregroundStyle(JournalStyle.ink)
                    .focused(focused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                if text.isEmpty {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(JournalPagesStyle.heartPink)
                        .accessibilityHidden(true)
                } else {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(JournalStyle.placeholder)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 56)
            // The capsule, its rim and glow, drawn once behind the text field (the pages scroll
            // under it, so it would otherwise be painted again on every frame).
            .background(capsule.renderedOnce(bleed: 18))

            Button(action: onFilter) {
                HStack(spacing: 5) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(JournalStyle.pink)
                    Text("Filter")
                        .font(.rounded(.callout, weight: .bold))
                        .foregroundStyle(JournalStyle.plum)
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 56)
                .background(capsule)
                .angelWingTrailing(width: 15, tucked: 0.45, y: -6, isShown: heavenly)
                .overlay(alignment: .topTrailing) {
                    if filterCount > 0 {
                        Text("\(filterCount)")
                            .font(.rounded(.caption, weight: .heavy))
                            .foregroundStyle(Color.white)
                            .frame(minWidth: 22, minHeight: 22)
                            .background(Circle().fill(JournalStyle.pink))
                            .offset(x: 4, y: -4)
                    }
                }
                .renderedOnce(bleed: 18)
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel(filterCount > 0 ? "Filter, \(filterCount) on" : "Filter")
        }
        .padding(.horizontal, theme.sideInset)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .overlay(alignment: .bottom) {
            if theme == .roseGoldElegance {
                RoseSearchBarTrim()
            }
        }
        .background(alignment: .bottom) {
            if theme == .cozyRainyDay {
                RainySearchBarTrim()
            } else if theme == .candyCloudKingdom {
                CandySearchBarTrim()
            }
        }
        .background(alignment: .bottom) {
            let base = theme.pagesBase
            LinearGradient(colors: [base.opacity(0), base.opacity(0.92)], startPoint: .top, endPoint: .center)
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
        }
    }

    /// The look of the search field and Filter: white, a pink edge (rose gold or caramel in those
    /// themes) and a soft pink shadow.
    private var capsule: some View {
        Capsule()
            .fill(Color.white.opacity(0.97))
            .overlay(Capsule().strokeBorder(JournalStyle.pinkFill, lineWidth: 1.5))
            .overlay {
                if theme == .roseGoldElegance {
                    Capsule().strokeBorder(RoseStyle.roseGold, lineWidth: 1.8)
                } else if theme == .candyCloudKingdom {
                    CandyGlowRim(shape: Capsule())
                }
            }
            .shadow(color: JournalStyle.pink.opacity(0.18), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Small pieces

/// Pages grouped by month, newest month first (or oldest first).
struct JournalMonth: Identifiable {
    let month: Date
    let entries: [JournalEntry]
    var id: Date { month }

    var title: String { month.formatted(.dateTime.month(.wide).year()) }

    static func group(_ pages: [JournalEntry], oldestFirst: Bool) -> [JournalMonth] {
        let groups = Dictionary(grouping: pages) { $0.date.startOfMonth }
        let oldest = groups.keys.sorted()
        let months = oldestFirst ? oldest : Array(oldest.reversed())
        return months.map { JournalMonth(month: $0, entries: groups[$0] ?? []) }
    }
}

/// Shown above the Little Wins: how many there are.
struct LittleWinsSummary: View {
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("🏆")
                .font(.system(size: 30))
                .frame(width: 54, height: 54)
                .background(Circle().fill(Palette.cream))
                .overlay(Circle().strokeBorder(Palette.butter, lineWidth: 1.5))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(count == 1 ? "1 little win" : "\(count) little wins")
                    .font(.rounded(.title3, weight: .heavy))
                    .foregroundStyle(Palette.cocoa)
                    .contentTransition(.numericText(value: Double(count)))
                Text("Look how far you've come! 🌟")
                    .font(.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(JournalStyle.soft)
            }
            Spacer(minLength: 0)
        }
        .journalPagesCard()
        .accessibilityElement(children: .combine)
    }
}

/// A friendly line at the top of a tab.
struct ShelfHint: View {
    let emoji: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji)
                .font(.system(size: 30))
                .frame(width: 52, height: 52)
                .background(Circle().fill(JournalStyle.pinkFill))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.rounded(.headline, weight: .heavy))
                    .foregroundStyle(JournalPagesStyle.heading)
                Text(message)
                    .font(.rounded(.subheadline, weight: .medium))
                    .foregroundStyle(JournalStyle.soft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .journalPagesCard()
        .accessibilityElement(children: .combine)
    }
}

/// A tab with nothing to show.
struct ShelfEmpty: View {
    let emoji: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 44))
                .accessibilityHidden(true)
            Text(title)
                .font(.rounded(.title3, weight: .heavy))
                .foregroundStyle(JournalPagesStyle.heading)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.rounded(.body, weight: .medium))
                .foregroundStyle(JournalStyle.soft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .journalPagesCard(padding: 20)
        .accessibilityElement(children: .combine)
    }
}

/// "🚶 1,254": the steps walked that day, from Apple Health, in a chip beside the mood, in the
/// mood's colours (shown once Health has given them; none on a day without steps).
struct StepsChip: View {
    let date: Date
    let mood: Mood
    @State private var counter = StepCounter.shared

    var body: some View {
        Group {
            if let steps = counter.steps(on: date), steps > 0 {
                let colors = mood.chooserColors
                HStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 13, weight: .heavy))
                    Text(steps, format: .number)
                        .font(.rounded(.footnote, weight: .heavy))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .foregroundStyle(colors.label)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Capsule().fill(colors.tile))
                .overlay(Capsule().strokeBorder(colors.label.opacity(0.45), lineWidth: 1.2))
                .fixedSize()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(steps) steps walked that day")
            }
        }
        .task(id: date) { await counter.load(date) }
    }
}
