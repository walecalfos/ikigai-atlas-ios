import SwiftUI
import IkigaiCore

@main
struct IkigaiAtlasApp: App {
    @StateObject private var store: AtlasStore
    @StateObject private var router: AppRouter
    @StateObject private var lock = AppLock()
    @StateObject private var reader = PatternReader()

    init() {
        AtlasTheme.install()
        if let mode = ScreenshotMode.current {
            let router = AppRouter()
            mode.configure(router)
            _store = StateObject(wrappedValue: AtlasStore.preview(.example))
            _router = StateObject(wrappedValue: router)
        } else {
            _store = StateObject(wrappedValue: AtlasStore.makeDefault())
            _router = StateObject(wrappedValue: AppRouter())
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(router)
                .environmentObject(lock)
                .environmentObject(reader)
                .themed()
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: AtlasStore
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var lock: AppLock
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @State private var showingWelcome = false

    var body: some View {
        TabView(selection: $router.tab) {
            JourneyView()
                .tabItem { Label("Journey", systemImage: "list.number") }
                .tag(AppRouter.Tab.journey)
            AtlasView()
                .tabItem { Label("Atlas", systemImage: "circle.hexagongrid") }
                .tag(AppRouter.Tab.atlas)
            LearnView()
                .tabItem { Label("Learn", systemImage: "book.closed") }
                .tag(AppRouter.Tab.learn)
        }
        .fullScreenCover(isPresented: $showingWelcome) {
            WelcomeView { destination in
                hasSeenWelcome = true
                showingWelcome = false
                switch destination {
                case .begin: router.open(store.atlas.firstIncompleteStage ?? .pulse)
                case .example:
                    router.tab = .atlas
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { router.showingExample = true }
                case .learn: router.tab = .learn
                }
            }
            .themed()
        }
        .sheet(isPresented: $router.showingSettings) {
            SettingsView().themed()
        }
        .overlay {
            if lock.isLocked || scenePhase != .active && lock.isEnabled {
                LockScreen()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                store.saveNow()
                lock.lockIfEnabled()
            case .active:
                store.loadFromStore(force: false)
                if lock.isLocked { lock.unlock() }
            default:
                break
            }
        }
        .onChange(of: hasSeenWelcome) { _, seen in
            if !seen { DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { showingWelcome = true } }
        }
        .onChange(of: store.atlas.rhythm) { _, _ in
            let atlas = store.atlas
            Task { await Reminders.reschedule(Reminders.savedSettings, atlas: atlas) }
        }
        .onAppear {
            if ScreenshotMode.current == .render { ScreenshotMode.renderAtlas() }
            if !hasSeenWelcome { showingWelcome = true }
            if lock.isLocked { lock.unlock() }
        }
    }
}

/// Covers the app when locked, and in the app switcher when the lock is on.
struct LockScreen: View {
    @EnvironmentObject private var lock: AppLock

    var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()
            VStack(spacing: Space.l) {
                NacreTablet(padding: Space.m) {
                    Text("生")
                        .font(Typo.display)
                        .foregroundStyle(Palette.ink)
                }
                .accessibilityHidden(true)
                Text("Ikigai Atlas is locked")
                    .font(Typo.title1)
                    .foregroundStyle(Palette.ink)
                if lock.isLocked {
                    Button("Unlock with \(lock.methodName)") { lock.unlock() }
                        .atlasButton(.primary, size: .large)
                }
            }
            .padding(Space.l)
        }
    }
}
