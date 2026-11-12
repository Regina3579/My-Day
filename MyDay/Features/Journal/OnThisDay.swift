import SwiftUI

/// "A Little Memory for You!" (My Day Pro): on My Journal Pages, the pages written on this
/// day one, two or three years ago, in a small card that can be closed (until tomorrow) and
/// swiped between years. Open Memory opens the page where it always stays, on its own date;
/// nothing is copied into today. It shows only when there is a memory, never as a pop-up, and
/// nothing from the pages ever goes into a notification.
struct OnThisDayCard: View {
    let entries: [JournalEntry]
    let today: Date

    @AppStorage(Prefs.onThisDayClosed) private var closedOn: Double = 0
    @State private var page = 0

    /// The newest page of each of the last three years written on this month and day.
    static func memories(in entries: [JournalEntry], today: Date) -> [JournalEntry] {
        let calendar = Calendar.current
        let now = calendar.dateComponents([.year, .month, .day], from: today)
        var byYear: [Int: JournalEntry] = [:]
        for entry in entries where !entry.isInTrash {
            let parts = calendar.dateComponents([.year, .month, .day], from: entry.date)
            guard parts.month == now.month, parts.day == now.day,
                  let year = parts.year, let thisYear = now.year,
                  (1...3).contains(thisYear - year) else { continue }
            if byYear[year].map({ $0.date < entry.date }) ?? true { byYear[year] = entry }
        }
        return byYear.keys.sorted(by: >).compactMap { byYear[$0] }
    }

    private var isClosedToday: Bool {
        Calendar.current.isDate(Date(timeIntervalSince1970: closedOn), inSameDayAs: today)
    }

    var body: some View {
        let memories = Self.memories(in: entries, today: today)
        if !memories.isEmpty, !isClosedToday {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("💌")
                    Text("A Little Memory for You!")
                        .font(.rounded(.headline, weight: .heavy))
                        .foregroundStyle(Color(hex: 0xA80B55))
                    Spacer()
                    Button {
                        withAnimation(.snappy) { closedOn = today.timeIntervalSince1970 }
                        Haptics.tap()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: 0x8E6CAA))
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close until tomorrow")
                }
                TabView(selection: $page) {
                    ForEach(Array(memories.enumerated()), id: \.offset) { index, entry in
                        NavigationLink(value: entry) {
                            MemoryRow(entry: entry, today: today)
                        }
                        .buttonStyle(.plain)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 120)
                // A memory trashed, or a new day with fewer: never a blank page.
                .onChange(of: memories.count) { _, count in page = min(page, max(0, count - 1)) }
                .onChange(of: today) { _, _ in page = 0 }
                if memories.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(memories.indices, id: \.self) { index in
                            Circle()
                                .fill(index == page ? Color(hex: 0xF0287F) : Color(hex: 0xF6C3D8))
                                .frame(width: 7, height: 7)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: 0xFFF4F8), Color(hex: 0xFDE6F1)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Color(hex: 0xF6B8D2), lineWidth: 1.5))
            .shadow(color: Color(hex: 0xF0287F).opacity(0.1), radius: 10, x: 0, y: 4)
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
        }
    }
}

/// One memory: its first photo (or its mood on a scrapbook card), how long ago, and Open Memory.
private struct MemoryRow: View {
    let entry: JournalEntry
    let today: Date

    private var yearsAgo: Int {
        Calendar.current.component(.year, from: today) - Calendar.current.component(.year, from: entry.date)
    }

    var body: some View {
        HStack(spacing: 14) {
            picture
                .frame(width: 104, height: 104)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.white, lineWidth: 3))
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                .rotationEffect(.degrees(-2))
            VStack(alignment: .leading, spacing: 5) {
                Text(yearsAgo == 1 ? "This Day Last Year" : "\(yearsAgo) Years Ago Today")
                    .font(.rounded(.headline, weight: .heavy))
                    .foregroundStyle(Color(hex: 0x3B1240))
                Text(entry.date.formatted(.dateTime.day().month(.wide).year()))
                    .font(.rounded(.caption, weight: .bold))
                    .foregroundStyle(Color(hex: 0xC2126B))
                Text("Remember this beautiful moment?")
                    .font(.rounded(.subheadline, weight: .medium))
                    .foregroundStyle(Color(hex: 0x7A3A8C))
                    .lineLimit(2)
                Label("Open Memory", systemImage: "arrow.right")
                    .labelStyle(TrailingIconLabelStyle())
                    .font(.rounded(.subheadline, weight: .heavy))
                    .foregroundStyle(Color(hex: 0xF0287F))
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the page from \(entry.date.formatted(date: .long, time: .omitted))")
    }

    @ViewBuilder
    private var picture: some View {
        if let data = entry.sortedPhotos.first.flatMap({ $0.thumbnailData ?? $0.imageData }),
           let image = UIImage(data: data) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            ZStack {
                Color(hex: 0xFFFBF2)
                // Grid paper with a strip of washi tape, like a scrapbook page.
                Path { path in
                    for step in stride(from: 0.0, through: 104.0, by: 10.0) {
                        path.move(to: CGPoint(x: step, y: 0)); path.addLine(to: CGPoint(x: step, y: 104))
                        path.move(to: CGPoint(x: 0, y: step)); path.addLine(to: CGPoint(x: 104, y: step))
                    }
                }
                .stroke(Color(hex: 0xF3DCE6), lineWidth: 0.6)
                Image(entry.mood.artName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 58, height: 58)
                Capsule()
                    .fill(Color(hex: 0xF9B9D3).opacity(0.85))
                    .frame(width: 46, height: 12)
                    .rotationEffect(.degrees(-24))
                    .offset(x: -30, y: -38)
            }
        }
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon
        }
    }
}
