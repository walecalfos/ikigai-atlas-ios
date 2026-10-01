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

    /// Writes full-length renders of the example atlas, in light and dark, to Documents.
    @MainActor
    static func renderAtlas() {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        for scheme in [ColorScheme.light, .dark] {
            let view = AtlasContent(atlas: .example, isExample: false, forPrint: true)
                .padding(16)
                .frame(width: 402)
                .background(Palette.canvas)
                .environment(\.colorScheme, scheme)
                .themed()
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            renderer.proposedSize = ProposedViewSize(width: 402, height: nil)
            let name = "atlas-full-\(scheme == .dark ? "dark" : "light")"
            if let image = renderer.uiImage, let data = image.pngData() {
                do { try data.write(to: docs.appendingPathComponent(name + ".png")) }
                catch { try? "write failed: \(error)".write(to: docs.appendingPathComponent(name + ".txt"), atomically: true, encoding: .utf8) }
            } else {
                try? "renderer returned no image".write(to: docs.appendingPathComponent(name + ".txt"), atomically: true, encoding: .utf8)
            }
        }
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
