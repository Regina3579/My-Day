import Charts
import SwiftData
import SwiftUI

/// Goal Report, from the side menu, as in its three designs (Week, Month and Year): the girl
/// beside its title, the period to step through, how many goals were completed, in progress and
/// missed, the days (or weeks, or months) as little bars, the goals by kind, the achievements
/// earned, the goals ticked most, and a cheering card. The goals are the My Goals ticked on
/// journal pages. ⇪ shares the report as a picture.
struct GoalReportView: View {
    @Environment(AppState.self) private var appState
    @Query(filter: #Predicate<JournalEntry> { $0.deletedAt == nil }, sort: \JournalEntry.date)
    private var entries: [JournalEntry]
    @State private var span: GoalReport.Span = .week
    @State private var anchor = Date.now
    @State private var sharedImage: UIImage?

    private var report: GoalReport {
        GoalReport(span: span, containing: anchor, entries: entries, goalList: DayListKind.goals.items,
                   today: appState.today)
    }

    var body: some View {
        ScrollView {
            content(report)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
        }
        .background(ReportBackground())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .tabBarSafeArea()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: share) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Palette.hotPink)
                }
                .accessibilityLabel("Share report")
            }
        }
        #if DEBUG
        .task {
            switch DebugLaunchRoute.takeGoalReportSpan() {
            case "month": span = .month
            case "year": span = .year
            default: break
            }
        }
        #endif
        .sheet(item: Binding(get: { sharedImage.map(SharedPicture.init) }, set: { sharedImage = $0?.image })) { picture in
            ActivitySheet(items: [picture.image])
                .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private func content(_ report: GoalReport) -> some View {
        VStack(spacing: 14) {
            header(report)
            if span == .week { weekBanner(report) }
            stats(report)
            switch span {
            case .week: dailyProgress(report)
            case .month: weeklyProgress(report)
            case .year: monthlyProgress(report)
            }
            if span != .week {
                HStack(alignment: .top, spacing: 12) {
                    categoriesCard(report)
                    achievementsCard(report)
                }
            }
            HStack(alignment: .top, spacing: 12) {
                topGoals(report)
                if span != .week { closingCard }
            }
            if span == .week { achievementsCard(report) }
        }
    }

    // MARK: Header

    private var title: String {
        switch span {
        case .week: "Goal Report"
        case .month: "Monthly Goal Report"
        case .year: "Yearly Goal Report"
        }
    }

    private var subtitle: String {
        switch span {
        case .week: "See your progress and celebrate your little wins!"
        case .month: "A beautiful look at your progress this month!"
        case .year: "A look back at your amazing year ✨ You've grown, achieved and made so many beautiful moments!"
        }
    }

    private var girl: String {
        switch span {
        case .week: "GoalReport/GirlWeek"
        case .month: "GoalReport/GirlMonth"
        case .year: "GoalReport/GirlYear"
        }
    }

    private func header(_ report: GoalReport) -> some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.rounded(size: 30, weight: .heavy))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: 0xF0287F), Color(hex: 0xA80B55)],
                                                    startPoint: .top, endPoint: .bottom))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle)
                    .font(.rounded(.subheadline, weight: .medium))
                    .foregroundStyle(ReportStyle.plum)
                    .fixedSize(horizontal: false, vertical: true)
                Picker("Report", selection: $span) {
                    ForEach(GoalReport.Span.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .onChange(of: span) { _, _ in anchor = .now }
                periodStepper(report)
            }
            Image(girl)
                .resizable()
                .scaledToFit()
                .frame(width: 140)
                .padding(.leading, -6)
                .accessibilityHidden(true)
        }
    }

    private func periodStepper(_ report: GoalReport) -> some View {
        HStack {
            stepButton("chevron.left", by: -1)
            Spacer()
            Text(periodText(report))
                .font(.rounded(.subheadline, weight: .bold))
                .foregroundStyle(ReportStyle.berry)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
            stepButton("chevron.right", by: 1)
                .disabled(report.end > appState.today)
                .opacity(report.end > appState.today ? 0.35 : 1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.white.opacity(0.7)))
    }

    private func stepButton(_ symbol: String, by step: Int) -> some View {
        Button {
            let component: Calendar.Component = span == .week ? .weekOfYear : span == .month ? .month : .year
            anchor = Calendar.current.date(byAdding: component, value: step, to: anchor) ?? anchor
            Haptics.tap()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(Palette.hotPink)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color(hex: 0xFCE1EE)))
        }
        .accessibilityLabel(step < 0 ? "Earlier" : "Later")
    }

    private func periodText(_ report: GoalReport) -> String {
        switch span {
        case .week:
            let last = report.end.adding(days: -1)
            return "\(report.start.formatted(.dateTime.month(.abbreviated).day())) – \(last.formatted(.dateTime.month(.abbreviated).day().year()))"
        case .month: return report.start.formatted(.dateTime.month(.wide).year())
        case .year: return report.start.formatted(.dateTime.year())
        }
    }

    // MARK: Totals

    private func weekBanner(_ report: GoalReport) -> some View {
        HStack(spacing: 12) {
            Image("GoalReport/Trophy")
                .resizable()
                .scaledToFit()
                .frame(width: 92)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(report.percent >= 0.8 ? "Amazing Week!" : report.percent >= 0.5 ? "Great Week!" : "Keep Going!")
                    .font(.rounded(size: 26, weight: .heavy))
                    .foregroundStyle(ReportStyle.berry)
                Text("You met your goals \(report.totalTicks) of \(report.possibleTicks) times!")
                    .font(.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(ReportStyle.plum)
                HStack(spacing: 8) {
                    ReportBar(value: report.percent, color: Palette.hotPink)
                    Text(report.percent.formatted(.percent.precision(.fractionLength(0))))
                        .font(.rounded(.headline, weight: .heavy))
                        .foregroundStyle(ReportStyle.ink)
                }
            }
        }
        .reportCard()
    }

    private func stats(_ report: GoalReport) -> some View {
        HStack(spacing: 8) {
            StatCard(art: "GoalReport/StatTarget", value: report.totalGoals, label: "Total Goals", share: nil, color: .clear)
            StatCard(art: "GoalReport/StatCheck", value: report.completed, label: "Completed",
                     share: report.fraction(report.completed), color: Color(hex: 0x3CCB6F))
            StatCard(art: "GoalReport/StatStar", value: report.inProgress, label: "In Progress",
                     share: report.fraction(report.inProgress), color: Palette.bubblegum)
            StatCard(art: "GoalReport/StatHeart", value: report.missed, label: "Missed",
                     share: report.fraction(report.missed), color: Color(hex: 0xF77F9B))
        }
    }

    // MARK: Progress

    private func dailyProgress(_ report: GoalReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle("Daily Progress", symbol: "calendar")
            HStack(spacing: 6) {
                ForEach(report.allDays, id: \.self) { day in
                    let page = report.pages[day]
                    let isFuture = day > appState.today
                    VStack(spacing: 4) {
                        Group {
                            if let page {
                                Image(page.mood.artName).resizable().scaledToFit()
                            } else {
                                Image(systemName: "heart.circle.fill")
                                    .resizable().scaledToFit()
                                    .foregroundStyle(Color(hex: 0xF6D3E3))
                            }
                        }
                        .frame(width: 30, height: 30)
                        Text(day.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.rounded(.caption2, weight: .bold))
                            .foregroundStyle(ReportStyle.ink)
                        Text(day.formatted(.dateTime.day().month(.defaultDigits)))
                            .font(.rounded(size: 9, weight: .medium))
                            .foregroundStyle(ReportStyle.plum)
                        ReportColumn(share: isFuture ? 0 : report.dayShare(day), height: 64)
                        Text("\(report.ticked(on: day))/\(report.totalGoals)")
                            .font(.rounded(size: 11, weight: .heavy))
                            .foregroundStyle(ReportStyle.ink)
                            .opacity(isFuture ? 0.3 : 1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.6)))
                }
            }
        }
        .reportCard()
    }

    private func weeklyProgress(_ report: GoalReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle("Weekly Progress", symbol: "chart.bar.fill")
            HStack(spacing: 6) {
                ForEach(Array(report.weeks.enumerated()), id: \.offset) { index, week in
                    let isPast = (week.days.first ?? .distantFuture) <= appState.today
                    VStack(spacing: 4) {
                        Text("Week \(index + 1)")
                            .font(.rounded(.caption, weight: .heavy))
                            .foregroundStyle(ReportStyle.ink)
                        if let first = week.days.first, let last = week.days.last {
                            Text("\(first.formatted(.dateTime.day()))–\(last.formatted(.dateTime.day()))")
                                .font(.rounded(size: 9, weight: .medium))
                                .foregroundStyle(ReportStyle.plum)
                        }
                        HStack(alignment: .bottom, spacing: 2) {
                            ForEach(week.days, id: \.self) { day in
                                ReportColumn(share: day > appState.today ? 0 : report.dayShare(day), height: 46, width: 5)
                            }
                        }
                        .frame(height: 50)
                        Text(isPast ? week.share.formatted(.percent.precision(.fractionLength(0))) : "–")
                            .font(.rounded(.caption, weight: .heavy))
                            .foregroundStyle(week.share >= 0.999 ? Color(hex: 0x2BAE5B) : ReportStyle.ink)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.6)))
                }
            }
        }
        .reportCard()
    }

    private func monthlyProgress(_ report: GoalReport) -> some View {
        let best = report.months.filter(\.hasDays).max { $0.share < $1.share }
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                cardTitle("Monthly Progress", symbol: "chart.bar.fill")
                Spacer()
                if let best, best.share > 0 {
                    Text("Most consistent in \(best.month.formatted(.dateTime.month(.wide)))! 🎉")
                        .font(.rounded(.caption, weight: .bold))
                        .foregroundStyle(ReportStyle.berry)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.85)))
                }
            }
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(report.months, id: \.month) { month in
                    VStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(month.hasDays ? Palette.bubblegum : Color(hex: 0xF6D3E3))
                        ReportColumn(share: month.share, height: 90, width: 18,
                                     highlight: best.map { $0.month == month.month } ?? false)
                        Text(month.month.formatted(.dateTime.month(.abbreviated)))
                            .font(.rounded(size: 9, weight: .bold))
                            .foregroundStyle(ReportStyle.ink)
                        Text(month.hasDays ? month.share.formatted(.percent.precision(.fractionLength(0))) : "–")
                            .font(.rounded(size: 8, weight: .semibold))
                            .foregroundStyle(ReportStyle.plum)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .reportCard()
    }

    // MARK: Categories and achievements

    private func categoriesCard(_ report: GoalReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            cardTitle("Goal Categories", symbol: "heart.circle.fill")
            ZStack {
                Chart(report.categories, id: \.category) { item in
                    SectorMark(angle: .value("Goals", item.count), innerRadius: .ratio(0.55), angularInset: 1.5)
                        .foregroundStyle(item.category.color)
                        .cornerRadius(4)
                }
                .frame(height: 130)
                VStack(spacing: 0) {
                    Text("\(report.totalGoals)")
                        .font(.rounded(.title2, weight: .heavy))
                        .foregroundStyle(ReportStyle.ink)
                    Text("Goals")
                        .font(.rounded(.caption, weight: .semibold))
                        .foregroundStyle(ReportStyle.plum)
                }
            }
            ForEach(report.categories, id: \.category) { item in
                HStack(spacing: 6) {
                    Circle().fill(item.category.color).frame(width: 10, height: 10)
                    Text(item.category.rawValue)
                        .font(.rounded(.caption, weight: .semibold))
                        .foregroundStyle(ReportStyle.ink)
                    Spacer(minLength: 2)
                    Text("\(item.count)")
                        .font(.rounded(.caption, weight: .heavy))
                        .foregroundStyle(ReportStyle.ink)
                }
            }
        }
        .reportCard()
    }

    private func achievementsCard(_ report: GoalReport) -> some View {
        let center = AchievementCenter.shared
        let items: [(Achievement, String, String)] = [
            (.streak7, "\(report.bestStreak) Day Streak", "Goals in a row"),
            (.goalMaster, "Goal Master", "\(report.totalTicks) goals met"),
            (.waterHero, "Healthy Habit", "\(report.waterDays) water days"),
            (.firstDay, "Journal Star", "\(report.pagesWritten) entries"),
        ]
        return VStack(alignment: .leading, spacing: 10) {
            cardTitle("Achievements", symbol: "trophy.fill")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(items, id: \.0) { item in
                    let (achievement, title, detail) = item
                    VStack(spacing: 2) {
                        Image(achievement.art)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 54)
                            .saturation(center.isEarned(achievement) ? 1 : 0.3)
                        Text(title)
                            .font(.rounded(size: 11, weight: .heavy))
                            .foregroundStyle(ReportStyle.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(detail)
                            .font(.rounded(size: 10, weight: .medium))
                            .foregroundStyle(ReportStyle.plum)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
        }
        .reportCard()
    }

    // MARK: Top goals

    private func topGoals(_ report: GoalReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            cardTitle(span == .week ? "Top Goals This Week" : span == .month ? "Top Goals This Month" : "Top Goals This Year",
                      symbol: "medal.fill")
            if report.topGoals.isEmpty {
                Text("Tick your goals on your journal pages, and your favourites will shine here. 💖")
                    .font(.rounded(.subheadline, weight: .medium))
                    .foregroundStyle(ReportStyle.plum)
            }
            ForEach(report.topGoals, id: \.goal) { item in
                HStack(spacing: 10) {
                    DayItemIcon(title: item.goal, size: 40)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.goal)
                            .font(.rounded(.subheadline, weight: .bold))
                            .foregroundStyle(ReportStyle.ink)
                            .lineLimit(1)
                        ReportBar(value: Double(item.met) / Double(max(1, report.days.count)), color: Palette.hotPink)
                    }
                    Text("\(item.met)/\(report.days.count)")
                        .font(.rounded(.caption, weight: .heavy))
                        .foregroundStyle(ReportStyle.ink)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .reportCard()
    }

    private var closingCard: some View {
        VStack(spacing: 8) {
            if span == .month {
                Image("GoalReport/ClosingMonth")
                    .resizable()
                    .scaledToFit()
            } else {
                Image("GoalReport/ClosingYear")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 96)
                Text("You made this year brighter and more beautiful!")
                    .font(.rounded(.caption, weight: .bold))
                    .foregroundStyle(ReportStyle.ink)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 128)
        .reportCard()
    }

    private func cardTitle(_ text: String, symbol: String) -> some View {
        Label {
            Text(text)
                .font(.rounded(.headline, weight: .heavy))
                .foregroundStyle(ReportStyle.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(Palette.hotPink)
        }
    }

    // MARK: Sharing

    /// The report (its current period) as a picture, for ⇪.
    private func share() {
        let renderer = ImageRenderer(content:
            content(report)
                .padding(16)
                .frame(width: 402)
                .background(ReportBackground())
                .environment(appState)
        )
        renderer.scale = 3
        sharedImage = renderer.uiImage
        Haptics.tap()
    }
}

// MARK: - Pieces

enum ReportStyle {
    static let ink = Color(hex: 0x3B1240)
    static let berry = Color(hex: 0xC2126B)
    static let plum = Color(hex: 0x7A3A8C)
}

private struct StatCard: View {
    let art: String
    let value: Int
    let label: String
    let share: Double?
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(art)
                .resizable()
                .scaledToFit()
                .frame(height: 34)
            Text("\(value)")
                .font(.rounded(.title2, weight: .heavy))
                .foregroundStyle(ReportStyle.ink)
                .contentTransition(.numericText(value: Double(value)))
            Text(label)
                .font(.rounded(size: 11, weight: .semibold))
                .foregroundStyle(ReportStyle.plum)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            if let share {
                HStack(spacing: 3) {
                    ReportBar(value: share, color: color)
                    Text(share.formatted(.percent.precision(.fractionLength(0))))
                        .font(.rounded(size: 9, weight: .heavy))
                        .foregroundStyle(ReportStyle.ink)
                }
            } else {
                Color.clear.frame(height: 10)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white.opacity(0.8)))
        .accessibilityElement(children: .combine)
    }
}

struct ReportBar: View {
    let value: Double
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(hex: 0xF6DDE9))
                Capsule().fill(color.gradient)
                    .frame(width: max(value > 0 ? 8 : 0, proxy.size.width * min(1, value)))
            }
        }
        .frame(height: 9)
    }
}

/// A rounded pink column filled to `share` of its height.
private struct ReportColumn: View {
    let share: Double
    let height: CGFloat
    var width: CGFloat = 26
    var highlight = false

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: width / 3, style: .continuous)
                .fill(Color(hex: 0xFBE3EE))
            RoundedRectangle(cornerRadius: width / 3, style: .continuous)
                .fill(LinearGradient(colors: highlight ? [Color(hex: 0xFF6FAE), Color(hex: 0xE9157A)]
                                                       : [Color(hex: 0xFFB3D6), Color(hex: 0xF77FB4)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(height: max(share > 0 ? 6 : 0, height * min(1, share)))
        }
        .frame(width: width, height: height)
    }
}

private struct ReportBackground: View {
    var body: some View {
        LinearGradient(colors: [Color(hex: 0xFDE4EF), Color(hex: 0xFCEAF3), Color(hex: 0xFBDDEB)],
                       startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

private extension View {
    func reportCard() -> some View {
        padding(14)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.white.opacity(0.72)))
            .shadow(color: Palette.hotPink.opacity(0.08), radius: 8, x: 0, y: 3)
    }
}

private struct SharedPicture: Identifiable {
    let image: UIImage
    var id: ObjectIdentifier { ObjectIdentifier(image) }
}

/// iOS's share sheet for a picture.
private struct ActivitySheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
