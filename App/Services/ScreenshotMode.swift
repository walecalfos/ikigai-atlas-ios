import SwiftUI
import IkigaiCore

/// Launch the app with `-uiScreenshot <screen>` to open a screen filled with the example atlas.
/// Used by CI to check the design, and for App Store screenshots. Never touches real data.
enum ScreenshotMode: String {
    case welcome, journey, pulse, remember, notice, gather, source, weave, live, atlas, example, learn, settings, render

    static let current: ScreenshotMode? = {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-uiScreenshot"), i + 1 < args.count else { return nil }
        return ScreenshotMode(rawValue: args[i + 1])
    }()

    /// Optional `-uiScrollTo <anchor>` to scroll a screen to a named section.
    static let scrollTarget: String? = {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-uiScrollTo"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }()

    var stage: Stage? {
        switch self {
        case .pulse: return .pulse
        case .remember: return .remember
        case .notice: return .notice
        case .gather, .source: return .gather
        case .weave: return .weave
        case .live: return .live
        default: return nil
        }
    }

    @MainActor
    func configure(_ router: AppRouter) {
        UserDefaults.standard.set(self != .welcome, forKey: "hasSeenWelcome")
        UserDefaults.standard.set(false, forKey: "appLockEnabled")
        switch self {
        case .atlas, .render: router.tab = .atlas
        case .example: router.tab = .atlas; router.showingExample = true
        case .learn: router.tab = .learn
        case .settings: router.tab = .journey; router.showingSettings = true
        default:
            router.tab = .journey
            if let stage { router.journeyPath = [stage] }
        }
    }

    /// Checks the export path: renders the example atlas to PDF and images in Documents,
    /// with a log of what worked, for CI to collect.
    @MainActor
    static func renderAtlas() {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        var log: [String] = []
        let atlas = Atlas.example

        func attempt<V: View>(_ name: String, width: CGFloat = 370, _ view: V) {
            let renderer = ImageRenderer(content: view.frame(width: width).background(Palette.canvas).themed())
            renderer.proposedSize = ProposedViewSize(width: width, height: nil)
            renderer.scale = 2
            var measured = CGSize.zero
            renderer.render { size, _ in measured = size }
            if let image = renderer.uiImage, let data = image.pngData() {
                try? data.write(to: docs.appendingPathComponent("render-\(name).png"))
                log.append("\(name): ok \(Int(measured.width))x\(Int(measured.height))")
            } else {
                log.append("\(name): no image, measured \(Int(measured.width))x\(Int(measured.height))")
            }
        }

        attempt("statement", NacreTablet { Text(atlas.statement).font(Typo.statement).foregroundStyle(Palette.ink) })
        attempt("map", SourceMapChart(sources: atlas.liveSources))
        attempt("radar", NeedsRadarChart(pulse: atlas.pulse, coverage: atlas.needCoverage().mapValues(\.count)))
        attempt("energy", EnergyMapChart(activities: atlas.activities))
        attempt("atlas", width: 402, AtlasContent(atlas: atlas, isExample: false, forPrint: true).padding(16))

        if let url = Exporter.pdfFile(named: "Ikigai Atlas", content: { PrintableAtlas(atlas: atlas) }) {
            try? FileManager.default.removeItem(at: docs.appendingPathComponent("export.pdf"))
            do {
                try FileManager.default.copyItem(at: url, to: docs.appendingPathComponent("export.pdf"))
                log.append("pdf: ok")
            } catch {
                log.append("pdf: copy failed \(error)")
            }
        } else {
            log.append("pdf: export returned nil")
        }
        try? log.joined(separator: "\n").write(to: docs.appendingPathComponent("render-log.txt"), atomically: true, encoding: .utf8)
    }
}

extension View {
    /// Scrolls to a named section when launched for screenshots with `-uiScrollTo`.
    func screenshotScroll(_ proxy: ScrollViewProxy) -> some View {
        onAppear {
            guard let target = ScreenshotMode.scrollTarget else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { proxy.scrollTo(target, anchor: .top) }
        }
    }
}
