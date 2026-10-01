import SwiftUI
import IkigaiCore

struct JourneyView: View {
    @EnvironmentObject private var store: AtlasStore
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        NavigationStack(path: $router.journeyPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.l) {
                    JourneyHeader()
                    VStack(alignment: .leading, spacing: Space.xs) {
                        Eyebrow(text: "Six stages")
                        VStack(spacing: 0) {
                            ForEach(Stage.allCases) { stage in
                                NavigationLink(value: stage) {
                                    StageRow(stage: stage, isDone: store.atlas.isComplete(stage),
                                             isNext: stage == store.atlas.firstIncompleteStage)
                                }
                                .buttonStyle(.plain)
                                if stage != .live {
                                    Rectangle().fill(Palette.line).frame(height: Stroke.hairline).padding(.leading, 60)
                                }
                            }
                        }
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.line, lineWidth: Stroke.hairline))
                    }
                    Text("Your answers stay on this iPhone\(store.syncsWithICloud ? " and in your own iCloud" : ""). Nobody else can read them.")
                        .font(Typo.caption)
                        .foregroundStyle(Palette.ink3)
                }
                .padding(.horizontal, Space.m)
                .padding(.vertical, Space.m)
            }
            .atlasScreen()
            .navigationTitle("Ikigai Atlas")
            .navigationDestination(for: Stage.self) { stage in
                StageView(stage: stage)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        router.showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
        }
    }
}

private struct JourneyHeader: View {
    @EnvironmentObject private var store: AtlasStore
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        let atlas = store.atlas
        let done = atlas.completedStageCount
        let next = atlas.firstIncompleteStage
        Panel(padding: Space.l) {
            Text(greeting(atlas))
                .font(Typo.largeTitle)
                .foregroundStyle(Palette.ink)
            Text(atlas.hasStarted
                 ? "\(done) of 6 stages complete. Take it in one sitting or several; everything saves as you go."
                 : "Six stages, about 75 minutes in all. The result is built only from your own stories, ratings and words.")
                .font(Typo.body)
                .foregroundStyle(Palette.ink2)
            AtlasProgressBar(value: Double(done) / 6)
                .padding(.vertical, Space.xxs)
            HStack(spacing: Space.s) {
                if let next {
                    Button(atlas.hasStarted ? "Continue with \(next.name)" : "Begin with the pulse") {
                        router.journeyPath = [next]
                    }
                    .atlasButton(.primary)
                } else {
                    Button("Open your atlas") { router.openAtlas() }
                        .atlasButton(.primary)
                }
            }
        }
    }

    private func greeting(_ atlas: Atlas) -> String {
        let name = atlas.name.trimmed
        if !atlas.hasStarted { return "Map what makes your life worth living." }
        if atlas.firstIncompleteStage == nil { return name.isEmpty ? "Your atlas is complete." : "\(name), your atlas is complete." }
        return name.isEmpty ? "Welcome back." : "Welcome back, \(name)."
    }
}

private struct StageRow: View {
    let stage: Stage
    let isDone: Bool
    let isNext: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Space.s) {
            ZStack {
                Circle()
                    .fill(isDone ? Palette.brandTint : (isNext ? Palette.brandFill : Palette.canvas))
                    .overlay(Circle().strokeBorder(isDone || isNext ? Palette.brand : Palette.line, lineWidth: Stroke.hairline))
                if isDone {
                    Image(systemName: "checkmark").font(Typo.captionStrong).foregroundStyle(Palette.brand)
                } else {
                    Text("\(stage.number)").font(Typo.captionStrong).monospacedDigit()
                        .foregroundStyle(isNext ? Palette.onBrand : Palette.ink2)
                }
            }
            .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(stage.name).font(Typo.bodyStrong).foregroundStyle(Palette.ink)
                    Spacer()
                    Text("\(stage.minutes) min").font(Typo.caption).foregroundStyle(Palette.ink3)
                }
                Text(stage.question).font(Typo.body2).foregroundStyle(Palette.ink2)
            }
            Image(systemName: "chevron.right")
                .font(Typo.caption)
                .foregroundStyle(Palette.ink3)
                .padding(.top, 4)
        }
        .padding(.horizontal, Space.m)
        .padding(.vertical, Space.s)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Stage \(stage.number), \(stage.name). \(stage.question)\(isDone ? ". Done" : "")")
    }
}

/// Routes a stage to its screen.
struct StageView: View {
    let stage: Stage
    var body: some View {
        switch stage {
        case .pulse: PulseStage()
        case .remember: RememberStage()
        case .notice: NoticeStage()
        case .gather: GatherStage()
        case .weave: WeaveStage()
        case .live: LiveStage()
        }
    }
}

/// Shared layout for every stage: header, the research behind it, the content, and the way on.
struct StageScreen<Content: View>: View {
    let stage: Stage
    @ViewBuilder var content: Content
    @EnvironmentObject private var store: AtlasStore
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(alignment: .leading, spacing: Space.xl) {
                VStack(alignment: .leading, spacing: Space.s) {
                    Eyebrow(text: "Stage \(stage.number) of 6 · about \(stage.minutes) minutes")
                    Text(stage.question)
                        .font(Typo.largeTitle)
                        .foregroundStyle(Palette.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text(stage.lede)
                        .font(Typo.body)
                        .foregroundStyle(Palette.ink2)
                    WhyNote(text: stage.why)
                        .padding(.top, Space.xs)
                }
                content
                continueButton.id("end")
            }
            .padding(.horizontal, Space.m)
            .padding(.top, Space.s)
            .padding(.bottom, Space.xxl)
        }
        .screenshotScroll(proxy)
        }
        .atlasScreen()
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(stage.name)
        .navigationBarTitleDisplayMode(.inline)
        .keyboardDoneButton()
    }

    @ViewBuilder private var continueButton: some View {
        VStack(spacing: Space.s) {
            Rectangle().fill(Palette.line).frame(height: Stroke.hairline)
            if let next = stage.next {
                Button("Continue to \(next.name)") {
                    router.journeyPath.append(next)
                }
                .atlasButton(.primary, size: .large)
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Button("Open your atlas") {
                    store.atlas.recordPulse()
                    router.openAtlas()
                }
                .atlasButton(.primary, size: .large)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}
