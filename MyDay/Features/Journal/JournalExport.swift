import ImageIO
import PDFKit
import SwiftData
import SwiftUI

// MARK: - Making the PDF

/// Turns journal pages into a beautiful PDF (A4): optionally a cover ("My Beautiful Memories –
/// 2026") and a table of contents, then each page starting on a new sheet, with its date, mood,
/// title, writing, reflections, activities and goals, photos, stickers and tags. Text stays
/// sharp (it is drawn, not pictured), so it prints well as a keepsake.
@MainActor
enum JournalPDF {
    struct Options {
        var includesCover = true
        var coverTitle = "My Beautiful Memories"
        var coverSubtitle = ""
        var includesContents = true
    }

    static let pageSize = CGSize(width: 595, height: 842)
    static let margin: CGFloat = 44
    static var contentWidth: CGFloat { pageSize.width - margin * 2 }
    private static let top: CGFloat = 52
    private static let bottom: CGFloat = 58

    /// Writes the PDF to a temporary file and returns it (nil if cancelled or empty).
    /// `progress` goes from 0 to 1. Each journal page is laid out, drawn and let go of before
    /// the next, and its photos are read at print size (1200 pixels), so even hundreds of pages
    /// with photos stay light on memory.
    static func make(_ entries: [JournalEntry], options: Options, fileName: String,
                     progress: @escaping (Double) -> Void = { _ in }) async -> URL? {
        let pages = entries.sorted { $0.date < $1.date }
        guard !pages.isEmpty else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName.replacingOccurrences(of: "/", with: "-"))
            .appendingPathExtension("pdf")
        try? FileManager.default.removeItem(at: url)
        var box = CGRect(origin: .zero, size: pageSize)
        let info = [kCGPDFContextTitle as String: options.coverTitle, kCGPDFContextCreator as String: "My Day"]
        guard let pdf = CGContext(url as CFURL, mediaBox: &box, info as CFDictionary) else { return nil }
        let steps = Double(pages.count * 2)
        var done = 0.0

        // Where each journal page starts, for the contents: laid out first without drawing
        // (photos are not read for this; their rows have a fixed height).
        let contentsRows = options.includesContents && pages.count > 1 ? pages.count : 0
        let contentsSheets = contentsRows == 0 ? 0 : Int(ceil(Double(contentsRows) / Double(contentsPerSheet)))
        var sheet = (options.includesCover ? 1 : 0) + contentsSheets + 1
        var starts: [Int] = []
        for page in pages {
            starts.append(sheet)
            sheet += layout(page, into: nil, firstSheet: sheet)
            done += 1
            progress(done / steps)
            await Task.yield()
            if Task.isCancelled { pdf.closePDF(); try? FileManager.default.removeItem(at: url); return nil }
        }

        if options.includesCover {
            drawFull(CoverSheet(title: options.coverTitle, subtitle: options.coverSubtitle, count: pages.count), in: pdf)
        }
        if contentsSheets > 0 {
            for index in 0..<contentsSheets {
                let slice = Array(zip(pages, starts)).dropFirst(index * contentsPerSheet).prefix(contentsPerSheet)
                drawFull(ContentsSheet(rows: slice.map { ($0.0.date, $0.0.displayTitle, $0.1) },
                                       isFirst: index == 0), in: pdf)
            }
        }
        for (page, start) in zip(pages, starts) {
            autoreleasepool {
                _ = layout(page, into: pdf, firstSheet: start)
            }
            done += 1
            progress(done / steps)
            await Task.yield()
            if Task.isCancelled { pdf.closePDF(); try? FileManager.default.removeItem(at: url); return nil }
        }
        pdf.closePDF()
        return url
    }

    private static let contentsPerSheet = 24

    /// Lays a journal page out on as many sheets as it needs, drawing them when `pdf` is given.
    /// Returns how many sheets it took.
    private static func layout(_ entry: JournalEntry, into pdf: CGContext?, firstSheet: Int) -> Int {
        let blocks = JournalPDFBlocks.blocks(for: entry, readsPhotos: pdf != nil)
        var sheets = 0
        var y: CGFloat = .infinity
        let usable = pageSize.height - top - bottom
        for block in blocks {
            let height = measure(block)
            if y + height > pageSize.height - bottom {
                if sheets > 0 { pdf?.endPDFPage() }
                if let pdf { beginSheet(pdf, number: firstSheet + sheets) }
                sheets += 1
                y = top
            }
            if let pdf { draw(block, at: y, height: min(height, usable), in: pdf) }
            y += height + 14
        }
        if sheets > 0 { pdf?.endPDFPage() }
        return max(sheets, 1)
    }

    private static func beginSheet(_ pdf: CGContext, number: Int) {
        pdf.beginPDFPage(nil)
        draw(AnyView(SheetBackground(number: number)), at: 0, height: pageSize.height, in: pdf, fullPage: true)
    }

    private static func drawFull<V: View>(_ view: V, in pdf: CGContext) {
        pdf.beginPDFPage(nil)
        draw(AnyView(view.frame(width: pageSize.width, height: pageSize.height)), at: 0, height: pageSize.height,
             in: pdf, fullPage: true)
        pdf.endPDFPage()
    }

    private static func measure(_ view: AnyView) -> CGFloat {
        let renderer = ImageRenderer(content: view.frame(width: contentWidth).fixedSize(horizontal: false, vertical: true))
        renderer.proposedSize = ProposedViewSize(width: contentWidth, height: nil)
        var height: CGFloat = 0
        renderer.render { size, _ in height = size.height }
        return height
    }

    private static func draw(_ view: AnyView, at y: CGFloat, height: CGFloat, in pdf: CGContext, fullPage: Bool = false) {
        let width = fullPage ? pageSize.width : contentWidth
        let content = view.frame(width: width).fixedSize(horizontal: false, vertical: true)
        let renderer = ImageRenderer(content: content)
        renderer.proposedSize = ProposedViewSize(width: width, height: fullPage ? pageSize.height : nil)
        renderer.render { size, render in
            pdf.saveGState()
            // PDF pages count up from the bottom.
            pdf.translateBy(x: fullPage ? 0 : margin, y: pageSize.height - y - size.height)
            render(pdf)
            pdf.restoreGState()
        }
    }
}

/// A journal page cut into pieces that each fit on a sheet: the heading, every paragraph, the
/// reflections, the photos two by two, the stickers and tags.
@MainActor
enum JournalPDFBlocks {
    static func blocks(for entry: JournalEntry, readsPhotos: Bool) -> [AnyView] {
        var blocks: [AnyView] = [AnyView(PDFEntryHeader(entry: entry))]
        let paragraphs = entry.body.components(separatedBy: "\n").map(\.trimmed).filter { !$0.isEmpty }
        for paragraph in paragraphs.flatMap(split) {
            blocks.append(AnyView(
                Text(paragraph)
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundStyle(PDFStyle.ink)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            ))
        }
        let reflections: [(String, String, String)] = [
            ("💖", "Grateful for", entry.gratitude), ("🌟", "Highlight of the day", entry.highlight),
            ("🏆", "Little win", entry.littleWin), ("🌈", "Looking forward to", entry.lookingForward),
        ].filter { !$0.2.trimmed.isEmpty }
        for (emoji, title, text) in reflections {
            blocks.append(AnyView(PDFReflection(emoji: emoji, title: title, text: text.trimmed)))
        }
        if !entry.activities.isEmpty {
            blocks.append(AnyView(PDFChips(title: "What I was up to", items: entry.activities)))
        }
        if !entry.goals.isEmpty {
            blocks.append(AnyView(PDFChips(title: "Goals I met", items: entry.goals)))
        }
        let photos = entry.sortedPhotos
        for pair in stride(from: 0, to: photos.count, by: 2) {
            let row = photos[pair..<min(pair + 2, photos.count)]
            blocks.append(AnyView(PDFPhotoRow(images: row.map { readsPhotos ? printImage($0.imageData) : nil })))
        }
        if !entry.stickers.isEmpty || !entry.tags.isEmpty {
            blocks.append(AnyView(PDFFooterBits(entry: entry)))
        }
        return blocks
    }

    /// A photo at print size (at most 1200 pixels across), read without loading the full image.
    private static func printImage(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 1200,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary).map(UIImage.init(cgImage:))
    }

    /// Splits a very long paragraph at sentence ends, so no piece is taller than a sheet.
    private static func split(_ paragraph: String) -> [String] {
        guard paragraph.count > 1400 else { return [paragraph] }
        var pieces: [String] = []
        var current = ""
        for sentence in paragraph.split(separator: ".", omittingEmptySubsequences: false) {
            let piece = sentence + "."
            if current.count + piece.count > 1200, !current.isEmpty {
                pieces.append(current.trimmed)
                current = ""
            }
            current += piece
        }
        if !current.trimmed.isEmpty { pieces.append(String(current.trimmed.dropLast(paragraph.hasSuffix(".") ? 0 : 1))) }
        return pieces
    }
}

// MARK: - The sheets

enum PDFStyle {
    static let ink = Color(hex: 0x3B1240)
    static let berry = Color(hex: 0xC2126B)
    static let plum = Color(hex: 0x7A3A8C)
    static let paper = Color(hex: 0xFFFBF6)
    static let blush = Color(hex: 0xFDE4EF)
}

/// Every sheet's paper: soft cream with a thin pink frame, little hearts and its number.
private struct SheetBackground: View {
    let number: Int

    var body: some View {
        ZStack {
            PDFStyle.paper
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color(hex: 0xF6C3D8), lineWidth: 1.5)
                .padding(18)
            VStack {
                Spacer()
                HStack {
                    Text("My Day 💖")
                    Spacer()
                    Text("\(number)")
                }
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(PDFStyle.plum.opacity(0.7))
                .padding(.horizontal, 44)
                .padding(.bottom, 30)
            }
        }
        .frame(width: JournalPDF.pageSize.width, height: JournalPDF.pageSize.height)
    }
}

/// The cover: "My Beautiful Memories – 2026" on soft pink, with the girl and her friends.
private struct CoverSheet: View {
    let title: String
    let subtitle: String
    let count: Int

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xFFF1F7), Color(hex: 0xFDDDEB), Color(hex: 0xF3E6FF)],
                           startPoint: .top, endPoint: .bottom)
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color(hex: 0xF4A9C8), lineWidth: 2)
                .padding(22)
            VStack(spacing: 18) {
                Spacer()
                Image("HeroFriends")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 400, height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Color.white, lineWidth: 6))
                    .shadow(color: Color(hex: 0xC2126B).opacity(0.2), radius: 12, x: 0, y: 6)
                Text("💗 💗 💗")
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(PDFStyle.berry)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(PDFStyle.plum)
                }
                Text(count == 1 ? "1 journal page" : "\(count) journal pages")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(PDFStyle.plum.opacity(0.8))
                Spacer()
                Text("Made with My Day 💖")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(PDFStyle.plum.opacity(0.7))
                    .padding(.bottom, 48)
            }
        }
    }
}

/// The table of contents: each page's date and title, and the sheet it starts on.
private struct ContentsSheet: View {
    let rows: [(Date, String, Int)]
    let isFirst: Bool

    var body: some View {
        ZStack(alignment: .top) {
            PDFStyle.paper
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color(hex: 0xF6C3D8), lineWidth: 1.5)
                .padding(18)
            VStack(alignment: .leading, spacing: 10) {
                if isFirst {
                    Text("Contents")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(PDFStyle.berry)
                        .padding(.bottom, 8)
                }
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(row.0.formatted(.dateTime.day().month(.abbreviated).year()))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(PDFStyle.plum)
                            .frame(width: 90, alignment: .leading)
                        Text(row.1)
                            .font(.system(size: 13, weight: .semibold, design: .serif))
                            .foregroundStyle(PDFStyle.ink)
                            .lineLimit(1)
                        Spacer(minLength: 6)
                        Text("\(row.2)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(PDFStyle.berry)
                    }
                    Divider().overlay(Color(hex: 0xF6C3D8))
                }
            }
            .padding(.horizontal, 54)
            .padding(.top, 60)
        }
    }
}

/// A page's heading: the weekday and date, its mood, title, weather and place.
private struct PDFEntryHeader: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 14) {
                Image(entry.mood.artName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.date.formatted(.dateTime.weekday(.wide)).uppercased())
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(PDFStyle.plum)
                    Text(entry.date.formatted(.dateTime.day().month(.wide).year()))
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(PDFStyle.berry)
                    Text("Feeling \(entry.mood.label.lowercased()) \(entry.mood.emoji)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(PDFStyle.plum)
                }
                Spacer(minLength: 0)
            }
            Text(entry.displayTitle)
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(PDFStyle.ink)
            let details = [entry.weather.map { $0.label + (entry.temperature.isEmpty ? "" : " · \(entry.temperature)") },
                           entry.place.trimmed.isEmpty ? nil : "📍 " + entry.place.trimmed].compactMap { $0 }
            if !details.isEmpty {
                Text(details.joined(separator: "   "))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(PDFStyle.plum)
            }
            Capsule().fill(LinearGradient(colors: [Color(hex: 0xFF8CC6), Color(hex: 0xC9A7F2)],
                                          startPoint: .leading, endPoint: .trailing))
                .frame(height: 3)
                .padding(.top, 2)
        }
    }
}

private struct PDFReflection: View {
    let emoji: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(emoji).font(.system(size: 18))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(PDFStyle.berry)
                Text(text)
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(PDFStyle.ink)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(PDFStyle.blush.opacity(0.7)))
    }
}

private struct PDFChips: View {
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(PDFStyle.berry)
            Text(items.joined(separator: "  ·  "))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(PDFStyle.plum)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Up to two photos side by side, framed in white.
private struct PDFPhotoRow: View {
    /// Nil while only measuring (the row's height does not depend on the photo).
    let images: [UIImage?]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(images.enumerated()), id: \.offset) { _, image in
                Group {
                    if let image {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        Color(hex: 0xF4E6EE)
                    }
                }
                    .frame(width: images.count == 1 ? JournalPDF.contentWidth : (JournalPDF.contentWidth - 12) / 2,
                           height: images.count == 1 ? 300 : 200)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.white, lineWidth: 4))
                    .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
            }
        }
    }
}

private struct PDFFooterBits: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !entry.stickers.isEmpty {
                StickerRow(stickers: entry.stickers, size: 34)
            }
            if !entry.tags.isEmpty {
                Text(entry.tags.map { "#" + $0 }.joined(separator: "  "))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(PDFStyle.berry)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Showing and sharing it

/// A finished PDF: a preview of its pages, and Share to save it to Files, print it, or send it.
struct JournalPDFPreview: View {
    let url: URL
    let title: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PDFKitView(url: url)
                .ignoresSafeArea(edges: .bottom)
                .background(Color(hex: 0xF4ECF2))
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        ShareLink(item: url) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                }
        }
    }
}

private struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.backgroundColor = UIColor(red: 0.96, green: 0.93, blue: 0.95, alpha: 1)
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {}
}

/// Export My Journal (My Day Pro): a Single Journal Page, a Monthly Journal, a Selected Date
/// Range or the Entire Journal, as a beautiful PDF (with an optional cover and table of
/// contents) or as plain text; made with a progress bar, then previewed and shared.
struct ExportJournalSheet: View {
    enum Scope: String, CaseIterable, Identifiable {
        case page = "Single Journal Page"
        case month = "Monthly Journal"
        case dates = "Selected Date Range"
        case all = "Entire Journal"
        var id: String { rawValue }
    }

    enum Format: String, CaseIterable, Identifiable {
        case pdf = "Beautiful PDF"
        case text = "Text"
        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<JournalEntry> { $0.deletedAt == nil }, sort: \JournalEntry.date)
    private var pages: [JournalEntry]
    @State private var scope: Scope = .all
    @State private var format: Format = .pdf
    @State private var pageID: UUID?
    @State private var from = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var to = Date.now
    @State private var month = Date.now.startOfMonth
    @State private var options = JournalPDF.Options()
    @State private var editedTitle = false
    @State private var progress: Double?
    @State private var work: Task<Void, Never>?
    @State private var made: MadePDF?
    @State private var madeText: MadePDF?

    private var chosen: [JournalEntry] {
        let calendar = Calendar.current
        switch scope {
        case .page:
            return pages.filter { $0.id == (pageID ?? pages.last?.id) }
        case .all:
            return pages
        case .month:
            return pages.filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }
        case .dates:
            let start = calendar.startOfDay(for: min(from, to))
            let end = calendar.startOfDay(for: max(from, to)).adding(days: 1)
            return pages.filter { $0.date >= start && $0.date < end }
        }
    }

    private var months: [Date] {
        Array(Set(pages.map(\.date.startOfMonth))).sorted(by: >)
    }

    /// "2026", "October 2026", or "2025 – 2026".
    private var periodText: String {
        let years = Set(chosen.map { Calendar.current.component(.year, from: $0.date) }).sorted()
        switch scope {
        case .month: return month.formatted(.dateTime.month(.wide).year())
        case .page: return chosen.first?.date.formatted(.dateTime.day().month(.wide).year()) ?? ""
        default:
            guard let first = years.first, let last = years.last else { return "" }
            return first == last ? "\(first)" : "\(first) – \(last)"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(Palette.hotPink)
                            Text("Export My Journal")
                                .font(.rounded(.title3, weight: .heavy))
                                .foregroundStyle(Palette.ink)
                            Spacer()
                            Text("Pro")
                                .font(.rounded(.caption, weight: .heavy))
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Palette.hotPink.gradient))
                        }
                        Text("Turn your precious memories into a beautiful PDF.")
                            .font(.rounded(.subheadline, weight: .medium))
                            .foregroundStyle(Palette.inkSoft)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Picker("Export", selection: $scope) {
                        ForEach(Scope.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    switch scope {
                    case .page:
                        Picker("Page", selection: Binding(get: { pageID ?? pages.last?.id }, set: { pageID = $0 })) {
                            ForEach(pages.reversed()) { page in
                                Text("\(page.date.formatted(.dateTime.day().month(.abbreviated).year())) · \(page.displayTitle)")
                                    .tag(Optional(page.id))
                            }
                        }
                    case .dates:
                        DatePicker("From", selection: $from, displayedComponents: .date)
                        DatePicker("To", selection: $to, displayedComponents: .date)
                    case .month:
                        Picker("Month", selection: $month) {
                            ForEach(months.isEmpty ? [Date.now.startOfMonth] : months, id: \.self) { month in
                                Text(month.formatted(.dateTime.month(.wide).year())).tag(month)
                            }
                        }
                    case .all:
                        EmptyView()
                    }
                }

                Section("Format") {
                    Picker("Format", selection: $format) {
                        ForEach(Format.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    if format == .pdf, scope != .page {
                        Toggle("Cover page", isOn: $options.includesCover)
                            .tint(Palette.hotPink)
                        if options.includesCover {
                            TextField("Cover title", text: $options.coverTitle)
                                .onChange(of: options.coverTitle) { _, _ in editedTitle = true }
                        }
                        Toggle("Table of contents", isOn: $options.includesContents)
                            .tint(Palette.hotPink)
                    }
                }

                Section {
                    EmptyView()
                } footer: {
                    Text(chosen.isEmpty ? "No journal pages here yet."
                         : chosen.count == 1 ? "1 journal page will be exported."
                         : "\(chosen.count) journal pages will be exported.")
                }
            }
            .font(.rounded(.body))
            .scrollContentBackground(.hidden)
            .background(DreamyBackground(theme: .journal))
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        work?.cancel()
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) { exportButton }
            .onAppear {
                if let newest = months.first, !months.contains(month) { month = newest }
            }
            .onAppear {
                if !editedTitle, options.coverTitle == JournalPDF.Options().coverTitle {
                    options.coverTitle = "My Beautiful Memories – \(Calendar.current.component(.year, from: .now))"
                }
            }
            .sheet(item: $made) { pdf in
                JournalPDFPreview(url: pdf.url, title: options.includesCover ? options.coverTitle : "My Journal")
            }
            .sheet(item: $madeText) { file in
                JournalTextPreview(url: file.url)
            }
        }
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .interactiveDismissDisabled(progress != nil)
    }

    @ViewBuilder
    private var exportButton: some View {
        VStack(spacing: 8) {
            if let progress {
                ProgressView(value: progress)
                    .tint(Palette.hotPink)
                Text("Making your \(format == .pdf ? "PDF" : "file")… \(Int(progress * 100))%")
                    .font(.rounded(.caption, weight: .semibold))
                    .foregroundStyle(Palette.inkSoft)
                Button("Stop") {
                    work?.cancel()
                    self.progress = nil
                }
                .font(.rounded(.subheadline, weight: .bold))
                .foregroundStyle(Palette.hotPink)
            } else {
                Button(action: export) {
                    Label(format == .pdf ? "Create My PDF" : "Create Text File", systemImage: "arrow.down.doc.fill")
                }
                .buttonStyle(PillButtonStyle())
                .disabled(chosen.isEmpty)
                .opacity(chosen.isEmpty ? 0.5 : 1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private func export() {
        let entries = chosen
        guard !entries.isEmpty else { return }
        var final = options
        if scope == .page {
            final.includesCover = false
            final.includesContents = false
        }
        if !editedTitle, !periodText.isEmpty {
            final.coverTitle = scope == .page ? "My Day – \(periodText)" : "My Beautiful Memories – \(periodText)"
        }
        final.coverSubtitle = subtitle(entries)
        progress = 0
        work = Task {
            if format == .text {
                let url = JournalText.make(entries, title: final.coverTitle)
                progress = nil
                if let url { madeText = MadePDF(url: url); Haptics.success() }
                return
            }
            let url = await JournalPDF.make(entries, options: final, fileName: final.coverTitle) { value in
                progress = value
            }
            progress = nil
            if let url, !Task.isCancelled {
                made = MadePDF(url: url)
                Haptics.success()
            }
        }
    }

    private func subtitle(_ entries: [JournalEntry]) -> String {
        guard let first = entries.first?.date, let last = entries.last?.date else { return "" }
        let format = Date.FormatStyle.dateTime.day().month(.abbreviated).year()
        return Calendar.current.isDate(first, inSameDayAs: last) ? first.formatted(format)
            : "\(first.formatted(format)) – \(last.formatted(format))"
    }
}

/// Export as Text: every page's date, mood, title, writing, reflections, activities, goals and
/// tags in a plain text file, readable anywhere.
@MainActor
enum JournalText {
    static func make(_ entries: [JournalEntry], title: String) -> URL? {
        let format = Date.FormatStyle.dateTime.weekday(.wide).day().month(.wide).year()
        var text = "\(title)\nMade with My Day 💖\n"
        for entry in entries.sorted(by: { $0.date < $1.date }) {
            text += "\n\n────────────────────\n"
            text += entry.date.formatted(format) + "\n"
            text += "Mood: \(entry.mood.label) \(entry.mood.emoji)\n"
            if let weather = entry.weather { text += "Weather: \(weather.label) \(entry.temperature)\n" }
            if !entry.place.trimmed.isEmpty { text += "Place: \(entry.place.trimmed)\n" }
            text += "\n\(entry.displayTitle)\n\n"
            if !entry.body.trimmed.isEmpty { text += entry.body.trimmed + "\n" }
            let reflections = [("Grateful for", entry.gratitude), ("Highlight of the day", entry.highlight),
                               ("Little win", entry.littleWin), ("Looking forward to", entry.lookingForward)]
            for (label, value) in reflections where !value.trimmed.isEmpty {
                text += "\n\(label): \(value.trimmed)"
            }
            if !entry.activities.isEmpty { text += "\nWhat I was up to: " + entry.activities.joined(separator: ", ") }
            if !entry.goals.isEmpty { text += "\nGoals I met: " + entry.goals.joined(separator: ", ") }
            if !entry.tags.isEmpty { text += "\nTags: " + entry.tags.map { "#" + $0 }.joined(separator: " ") }
            text += "\n"
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(title.replacingOccurrences(of: "/", with: "-"))
            .appendingPathExtension("txt")
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}

/// The text file made, to read and share.
struct JournalTextPreview: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text((try? String(contentsOf: url, encoding: .utf8)) ?? "")
                    .font(.system(.footnote, design: .serif))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .textSelection(.enabled)
            }
            .background(Color(hex: 0xFFFBF6))
            .navigationTitle("My Journal (Text)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    ShareLink(item: url) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

/// A made PDF, for `.sheet(item:)`.
struct MadePDF: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}
