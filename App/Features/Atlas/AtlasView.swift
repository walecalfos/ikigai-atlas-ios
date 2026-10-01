import SwiftUI
import UIKit
import IkigaiCore

struct AtlasView: View {
    @EnvironmentObject private var store: AtlasStore
    @EnvironmentObject private var router: AppRouter
    @State private var shareItem: ShareItem?

    var body: some View {
        NavigationStack {
            Group {
                if store.atlas.hasStarted {
                    ScrollViewReader { proxy in
                        ScrollView {
                            AtlasContent(atlas: store.atlas, isExample: false)
                                .padding(.horizontal, Space.m)
                                .padding(.vertical, Space.m)
                        }
                        .screenshotScroll(proxy)
                    }
                } else {
                    EmptyAtlas()
                }
            }
            .atlasScreen()
            .navigationTitle("Your atlas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Example") { router.showingExample = true }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            if let url = Exporter.pdfFile(named: "Ikigai Atlas", content: { PrintableAtlas(atlas: store.atlas) }) {
                                shareItem = ShareItem(url: url)
                            }
                        } label: { Label("Share as PDF", systemImage: "doc.richtext") }
                        Button {
                            if let url = Exporter.markdownFile(for: store.atlas) { shareItem = ShareItem(url: url) }
                        } label: { Label("Share as text", systemImage: "doc.plaintext") }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share your atlas")
                    .disabled(!store.atlas.hasStarted)
                }
            }
            .sheet(item: $shareItem) { item in
                ActivityView(items: [item.url]).ignoresSafeArea()
            }
            .sheet(isPresented: $router.showingExample) {
                NavigationStack {
                    ScrollView {
                        AtlasContent(atlas: .example, isExample: true)
                            .padding(.horizontal, Space.m)
                            .padding(.vertical, Space.m)
                    }
                    .atlasScreen()
                    .navigationTitle("Example atlas")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { router.showingExample = false }.fontWeight(.semibold)
                        }
                    }
                }
                .themed()
            }
        }
    }
}

struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

/// The system share sheet.
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

private struct EmptyAtlas: View {
    @EnvironmentObject private var router: AppRouter
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.l) {
                NacreTablet {
                    Text("生")
                        .font(Typo.display)
                        .foregroundStyle(Palette.ink)
                }
                .accessibilityHidden(true)
                Text("Your atlas is still blank")
                    .font(Typo.largeTitle)
                    .foregroundStyle(Palette.ink)
                Text("It fills in as you work through the six stages. Every mark on it comes from something you write or rate.")
                    .font(Typo.body)
                    .foregroundStyle(Palette.ink2)
                HStack(spacing: Space.s) {
                    Button("Begin with the pulse") { router.open(.pulse) }
                        .atlasButton(.primary)
                    Button("See an example") { router.showingExample = true }
                        .atlasButton(.secondary)
                }
            }
            .padding(Space.l)
        }
    }
}

/// Every panel of the finished atlas. Used for the person's own atlas, the example and the PDF.
struct AtlasContent: View {
    let atlas: Atlas
    let isExample: Bool
    var forPrint = false

    var body: some View {
        let sources = atlas.liveSources
        let insights = atlas.insights()
        VStack(alignment: .leading, spacing: Space.m) {
            if isExample {
                Text("This atlas belongs to Sam, a fictional nurse, to show what the framework produces.")
                    .font(Typo.body2)
                    .foregroundStyle(Palette.ink2)
                    .padding(Space.s)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(RoundedRectangle(cornerRadius: Radius.control).strokeBorder(Palette.hungry, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
            }

            VStack(alignment: .leading, spacing: Space.xs) {
                Eyebrow(text: headerLine)
                Text(atlas.name.hasText ? "\(atlas.name.trimmed)’s ikigai" : "Your ikigai")
                    .font(Typo.largeTitle)
                    .foregroundStyle(Palette.ink)
                    .accessibilityAddTraits(.isHeader)
            }

            NacreTablet(padding: Space.l) {
                Text(atlas.statement.hasText ? atlas.statement.trimmed : "Your ikigai statement will appear here once you write it in stage 5.")
                    .font(atlas.statement.hasText ? Typo.statement : Typo.body)
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Panel {
                Eyebrow(text: "Sources of ikigai").id("map")
                if sources.isEmpty {
                    EmptyNote(text: "Name your sources in stage 4 and they’ll be mapped here.")
                } else {
                    Text("\(sources.count) sources across \(Set(sources.compactMap(\.domain)).count) of 8 areas. Nearer the centre means more worth.")
                        .font(Typo.body2)
                        .foregroundStyle(Palette.ink2)
                    SourceMapChart(sources: sources)
                    SourceLegend(sources: sources)
                }
            }

            Panel {
                Eyebrow(text: "Ikigai-kan pulse").id("pulse")
                if let average = atlas.pulseAverage {
                    HStack(alignment: .firstTextBaseline, spacing: Space.xs) {
                        Text(atlas.pulse.overall.map { "\($0)" } ?? "–").font(Typo.display).monospacedDigit().foregroundStyle(Palette.ink)
                        Text("out of 10: how worth living life feels. Needs average \(String(format: "%.1f", average)) of 5.")
                            .font(Typo.body2)
                            .foregroundStyle(Palette.ink2)
                    }
                    NeedsRadarChart(pulse: atlas.pulse, coverage: atlas.needCoverage().mapValues(\.count))
                    HStack(spacing: Space.m) {
                        KeySwatch(dashed: false, text: "How fed each need feels")
                        KeySwatch(dashed: true, text: "Sources feeding it (0 to 3+)")
                    }
                } else {
                    EmptyNote(text: "Take the pulse in stage 1.")
                }
            }

            Panel {
                Eyebrow(text: "What your atlas shows").id("insights")
                if insights.isEmpty {
                    EmptyNote(text: "Insights appear as you complete the stages.")
                } else {
                    VStack(alignment: .leading, spacing: Space.s) {
                        ForEach(insights.prefix(9)) { insight in
                            HStack(alignment: .top, spacing: Space.s) {
                                Circle()
                                    .fill(color(for: insight.tone))
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 6)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(insight.title).font(Typo.bodyStrong).foregroundStyle(Palette.ink)
                                    Text(insight.body).font(Typo.body2).foregroundStyle(Palette.ink2)
                                }
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }

            Panel {
                Eyebrow(text: "Threads").id("threads")
                if atlas.namedThreads.isEmpty {
                    EmptyNote(text: "Name your threads in stage 5.")
                } else {
                    ForEach(atlas.namedThreads) { t in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t.name).font(Typo.title1).foregroundStyle(Palette.ink)
                            if t.note.hasText { Text(t.note).font(Typo.body2).foregroundStyle(Palette.ink2) }
                        }
                    }
                }
            }

            if !sources.isEmpty {
                Panel {
                    Eyebrow(text: "Balance").id("balance")
                    BalanceBar(title: "Belonging and becoming", parts: [
                        ("Belonging", sources.filter { $0.mode == .belonging }.count, 1.0),
                        ("Both", sources.filter { $0.mode == .both }.count, 0.55),
                        ("Becoming", sources.filter { $0.mode == .becoming }.count, 0.25)
                    ])
                    BalanceBar(title: "Where in time", parts: [
                        ("Past", sources.filter { $0.time == .past }.count, 0.25),
                        ("Present", sources.filter { $0.time == .present }.count, 1.0),
                        ("Future", sources.filter { $0.time == .future }.count, 0.55)
                    ])
                }
            }

            Panel {
                Eyebrow(text: "Energy map").id("energy")
                if atlas.namedActivities.isEmpty {
                    EmptyNote(text: "Complete the energy audit in stage 3.")
                } else {
                    EnergyMapChart(activities: atlas.activities)
                }
            }

            Panel {
                Eyebrow(text: "Small joys").id("joys")
                if atlas.joys.isEmpty {
                    EmptyNote(text: "Collect them in stage 3.")
                } else {
                    FlowLayout(spacing: Space.xs) {
                        ForEach(atlas.joys, id: \.self) { TagChip(title: $0) }
                    }
                }
            }

            if !atlas.namedLens.isEmpty {
                Panel {
                    Eyebrow(text: "Work lens").id("lens")
                    ForEach(atlas.namedLens.sorted { $0.circleCount > $1.circleCount }) { l in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(l.text).font(Typo.body).foregroundStyle(Palette.ink)
                                Text(l.label).font(Typo.caption).foregroundStyle(Palette.ink2)
                            }
                            Spacer()
                            HStack(spacing: 4) {
                                CircleMark(letter: "L", on: l.love)
                                CircleMark(letter: "G", on: l.good)
                                CircleMark(letter: "N", on: l.needed)
                                CircleMark(letter: "P", on: l.paid)
                            }
                            .accessibilityHidden(true)
                        }
                    }
                    Text("L love · G good at · N the world needs · P paid for").font(Typo.caption).foregroundStyle(Palette.ink3)
                }
            }

            Panel {
                Eyebrow(text: "Experiments and rhythm").id("experiments")
                if atlas.namedExperiments.isEmpty {
                    EmptyNote(text: "Design experiments in stage 6.")
                } else {
                    ForEach(atlas.namedExperiments) { e in
                        HStack(alignment: .top, spacing: Space.s) {
                            Image(systemName: e.status == .planned ? "square" : "checkmark.square.fill")
                                .foregroundStyle(Palette.brand)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(e.text).font(Typo.body).foregroundStyle(Palette.ink)
                                Text([e.when.trimmed, e.need.map { "feeds " + $0.name.lowercased() } ?? "", e.status.name.lowercased()]
                                        .filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(Typo.caption)
                                    .foregroundStyle(Palette.ink2)
                            }
                        }
                    }
                }
                if atlas.rhythm.morning.hasText {
                    LabeledLine(label: "Each morning", text: atlas.rhythm.morning)
                }
                if atlas.rhythm.evening.hasText {
                    LabeledLine(label: "Each evening", text: atlas.rhythm.evening)
                }
                if let review = atlas.rhythm.review {
                    Text("Retake the pulse on \(review.formatted(date: .long, time: .omitted)).")
                        .font(Typo.body2Strong)
                        .foregroundStyle(Palette.ink)
                }
            }

            if let reading = atlas.reading, !reading.isEmpty {
                Panel {
                    Eyebrow(text: "Pattern reading")
                    if !reading.pattern.isEmpty { Text(reading.pattern).font(Typo.body).foregroundStyle(Palette.ink) }
                    if !reading.tension.isEmpty { Text(reading.tension).font(Typo.body2).foregroundStyle(Palette.ink2) }
                    if !reading.question.isEmpty { Text(reading.question).font(Typo.title1).foregroundStyle(Palette.ink) }
                }
            }

            if !isExample && !forPrint {
                PulseHistoryPanel().id("history")
            }
        }
    }

    private var headerLine: String {
        var parts = ["Ikigai Atlas"]
        parts.append((isExample ? Date() : (atlas.updatedAt ?? Date())).formatted(date: .long, time: .omitted))
        if !isExample && atlas.completedStageCount < 6 { parts.append("\(atlas.completedStageCount) of 6 stages complete") }
        return parts.joined(separator: " · ")
    }

    private func color(for tone: Insight.Tone) -> Color {
        switch tone {
        case .hungry: return Palette.hungry
        case .good: return Palette.fed
        case .note: return Palette.ink3
        }
    }
}

private struct EmptyNote: View {
    let text: String
    var body: some View { Text(text).font(Typo.body2).foregroundStyle(Palette.ink3) }
}

private struct LabeledLine: View {
    let label: String
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased()).font(Typo.caption2).tracking(1).foregroundStyle(Palette.ink3)
            Text(text).font(Typo.body).foregroundStyle(Palette.ink)
        }
    }
}

private struct CircleMark: View {
    let letter: String
    let on: Bool
    var body: some View {
        Text(letter)
            .font(Typo.caption2)
            .fontWeight(.bold)
            .foregroundStyle(on ? Palette.onBrand : Palette.ink3)
            .frame(width: 22, height: 22)
            .background(on ? Palette.brandFill : Color.clear, in: Circle())
            .overlay(Circle().strokeBorder(on ? Color.clear : Palette.line, lineWidth: 1))
    }
}

private struct KeySwatch: View {
    let dashed: Bool
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            if dashed {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 5))
                    p.addLine(to: CGPoint(x: 18, y: 5))
                }
                .stroke(Palette.fed, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                .frame(width: 18, height: 10)
            } else {
                RoundedRectangle(cornerRadius: 2).fill(Palette.brand.opacity(0.3)).overlay(RoundedRectangle(cornerRadius: 2).stroke(Palette.brand, lineWidth: 1.5)).frame(width: 14, height: 10)
            }
            Text(text).font(Typo.caption).foregroundStyle(Palette.ink2)
        }
    }
}

private struct SourceLegend: View {
    let sources: [Source]
    var body: some View {
        let numbers = Dictionary(sources.enumerated().map { ($0.element.id, $0.offset + 1) }, uniquingKeysWith: { a, _ in a })
        VStack(alignment: .leading, spacing: Space.s) {
            ForEach(Domain.allCases) { domain in
                let inDomain = sources.filter { $0.domain == domain }
                if !inDomain.isEmpty {
                    VStack(alignment: .leading, spacing: Space.xxs) {
                        Text(domain.name.uppercased()).font(Typo.caption2).tracking(1).foregroundStyle(Palette.ink3)
                        ForEach(inDomain) { s in
                            LegendRow(number: numbers[s.id] ?? 0, text: s.text, status: s.authStatus)
                        }
                    }
                }
            }
            let unplaced = sources.filter { $0.domain == nil }
            if !unplaced.isEmpty {
                VStack(alignment: .leading, spacing: Space.xxs) {
                    Text("NOT PLACED YET").font(Typo.caption2).tracking(1).foregroundStyle(Palette.ink3)
                    ForEach(unplaced) { s in LegendRow(number: numbers[s.id] ?? 0, text: s.text, status: s.authStatus) }
                }
            }
            HStack(spacing: Space.m) {
                LegendKey(status: .core, text: "Core")
                LegendKey(status: .growing, text: "Growing or untested")
                LegendKey(status: .borrowed, text: "Borrowed")
            }
            .padding(.top, Space.xxs)
        }
    }
}

private struct LegendRow: View {
    let number: Int
    let text: String
    let status: AuthStatus
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.xs) {
            NumberBadge(number: number, status: status)
            Text(text).font(Typo.body2).foregroundStyle(Palette.ink)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(number). \(text), \(status.name)")
    }
}

private struct LegendKey: View {
    let status: AuthStatus
    let text: String
    var body: some View {
        HStack(spacing: 4) {
            NumberBadge(number: 1, status: status)
            Text(text).font(Typo.caption).foregroundStyle(Palette.ink2)
        }
    }
}

private struct NumberBadge: View {
    let number: Int
    let status: AuthStatus
    var body: some View {
        Text("\(number)")
            .font(.system(size: 10, weight: .bold))
            .monospacedDigit()
            .foregroundStyle(status == .core ? Palette.onBrand : (status == .borrowed ? Palette.hungry : Palette.brand))
            .frame(width: 20, height: 20)
            .background(status == .core ? Palette.brandFill : Color.clear, in: Circle())
            .overlay(Circle().strokeBorder(status == .core ? Color.clear : (status == .borrowed ? Palette.hungry : Palette.brand),
                                           style: StrokeStyle(lineWidth: 1.5, dash: status == .borrowed ? [3, 2] : [])))
    }
}

private struct BalanceBar: View {
    let title: String
    let parts: [(label: String, count: Int, strength: Double)]
    var body: some View {
        let total = max(1, parts.reduce(0) { $0 + $1.count })
        VStack(alignment: .leading, spacing: Space.xxs) {
            Text(title).font(Typo.body2Strong).foregroundStyle(Palette.ink)
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(parts.indices, id: \.self) { i in
                        if parts[i].count > 0 {
                            Rectangle()
                                .fill(Palette.brand.opacity(parts[i].strength))
                                .frame(width: max(4, (geo.size.width - 4) * CGFloat(parts[i].count) / CGFloat(total)))
                        }
                    }
                }
            }
            .frame(height: 10)
            .clipShape(Capsule())
            .background(Palette.surfaceSunken, in: Capsule())
            HStack(spacing: Space.s) {
                ForEach(parts.indices, id: \.self) { i in
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2).fill(Palette.brand.opacity(parts[i].strength)).frame(width: 10, height: 10)
                        Text("\(parts[i].label) \(parts[i].count)").font(Typo.caption).foregroundStyle(Palette.ink2)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(parts.map { "\($0.label) \($0.count)" }.joined(separator: ", "))
    }
}

private struct PulseHistoryPanel: View {
    @EnvironmentObject private var store: AtlasStore
    @EnvironmentObject private var router: AppRouter
    @State private var flash: String?

    var body: some View {
        let history = Array(store.atlas.pulseHistory.suffix(6).reversed())
        Panel {
            Eyebrow(text: "Pulse over time")
            if history.isEmpty {
                Text("Save a pulse today and again at your review date to see how your ikigai-kan changes.")
                    .font(Typo.body2)
                    .foregroundStyle(Palette.ink2)
            } else {
                Grid(alignment: .leading, horizontalSpacing: Space.m, verticalSpacing: Space.xs) {
                    GridRow {
                        Text("Saved").font(Typo.captionStrong)
                        Text("Life /10").font(Typo.captionStrong)
                        Text("Needs /5").font(Typo.captionStrong)
                        Text("Hungriest").font(Typo.captionStrong)
                    }
                    .foregroundStyle(Palette.ink2)
                    ForEach(history) { h in
                        GridRow {
                            Text(h.date.formatted(date: .abbreviated, time: .omitted))
                            Text(h.overall.map { "\($0)" } ?? "–").monospacedDigit()
                            Text(h.needsAverage.map { String(format: "%.1f", $0) } ?? "–").monospacedDigit()
                            Text(h.hungriest?.shortName ?? "–")
                        }
                        .font(Typo.body2)
                        .foregroundStyle(Palette.ink)
                    }
                }
            }
            HStack(spacing: Space.s) {
                Button("Save today’s pulse") {
                    flash = store.atlas.recordPulse() ? "Today’s pulse is saved." : "Take the pulse in stage 1 first."
                }
                .atlasButton(.primary, size: .small)
                Button("Retake the pulse") { router.open(.pulse) }
                    .atlasButton(.secondary, size: .small)
            }
            if let flash {
                Text(flash).font(Typo.caption).foregroundStyle(Palette.ink2)
            }
        }
    }
}

/// A light-mode, full-length version of the atlas for the PDF.
struct PrintableAtlas: View {
    let atlas: Atlas
    var body: some View {
        AtlasContent(atlas: atlas, isExample: false, forPrint: true)
            .padding(32)
            .background(Color(white: 0.96))
    }
}
