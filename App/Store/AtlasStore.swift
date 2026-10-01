import Foundation
import SwiftUI
import SwiftData
import CoreData
import Combine
import IkigaiCore

/// One saved atlas. The whole atlas is stored as JSON in a single record, which keeps
/// iCloud sync simple and robust: the newest copy wins.
///
/// CloudKit-backed SwiftData models need default values and no unique constraints.
@Model
final class AtlasRecord {
    var key: String = "primary"
    var payload: Data = Data()
    var updatedAt: Date = Date.distantPast

    init(key: String = "primary", payload: Data, updatedAt: Date) {
        self.key = key
        self.payload = payload
        self.updatedAt = updatedAt
    }
}

@MainActor
final class AtlasStore: ObservableObject {
    /// The person's atlas. Every edit stamps `updatedAt` and is saved shortly after.
    @Published var atlas: Atlas {
        didSet {
            guard !isApplying, atlas != oldValue else { return }
            isApplying = true
            atlas.updatedAt = Date()
            isApplying = false
            scheduleSave()
        }
    }

    @Published private(set) var lastSaveFailed = false
    let syncsWithICloud: Bool

    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }
    private var isApplying = false
    private var saveTask: Task<Void, Never>?
    private var remoteChanges: AnyCancellable?

    init(container: ModelContainer, syncsWithICloud: Bool) {
        self.container = container
        self.syncsWithICloud = syncsWithICloud
        self.atlas = Atlas()
        loadFromStore(force: true)
        remoteChanges = NotificationCenter.default
            .publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor in self?.loadFromStore(force: false) }
            }
    }

    /// Whether this build was made with iCloud sync switched on (`IKIGAI_ICLOUD_SYNC` in Config/App.xcconfig).
    /// iCloud needs a paid Apple Developer Program membership, so it's off by default.
    static var iCloudSyncInBuild: Bool {
        (Bundle.main.object(forInfoDictionaryKey: "IkigaiICloudSync") as? String)?.uppercased() == "YES"
    }

    /// Builds the store, using iCloud sync when the build allows it, falling back to on-device
    /// storage, then to memory, so the app always opens.
    static func makeDefault() -> AtlasStore {
        let schema = Schema([AtlasRecord.self])
        if iCloudSyncInBuild,
           let cloud = try? ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)]) {
            return AtlasStore(container: cloud, syncsWithICloud: FileManager.default.ubiquityIdentityToken != nil)
        }
        if let local = try? ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, cloudKitDatabase: .none)]) {
            return AtlasStore(container: local, syncsWithICloud: false)
        }
        let memory = try! ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        return AtlasStore(container: memory, syncsWithICloud: false)
    }

    static func preview(_ atlas: Atlas = .example) -> AtlasStore {
        let schema = Schema([AtlasRecord.self])
        let memory = try! ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let store = AtlasStore(container: memory, syncsWithICloud: false)
        store.replace(with: atlas)
        return store
    }

    // MARK: Loading and saving

    /// Reads the newest saved atlas. Unless forced, only replaces the in-memory atlas
    /// when the saved copy is newer, for example after a sync from another device.
    func loadFromStore(force: Bool) {
        let records = (try? context.fetch(FetchDescriptor<AtlasRecord>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]))) ?? []
        guard let newest = records.first else { return }
        // Two devices can each create a record before they first sync; keep the newest.
        for extra in records.dropFirst() { context.delete(extra) }
        if records.count > 1 { try? context.save() }
        guard let decoded = try? Atlas.decode(newest.payload) else { return }
        let localStamp = atlas.updatedAt ?? .distantPast
        let savedStamp = decoded.updatedAt ?? .distantPast
        if force || savedStamp > localStamp {
            apply(decoded)
        }
    }

    func saveNow() {
        saveTask?.cancel()
        persist()
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled else { return }
            self?.persist()
        }
    }

    private func persist() {
        guard atlas.hasStarted, let data = try? atlas.encoded() else { return }
        let stamp = atlas.updatedAt ?? Date()
        do {
            let records = try context.fetch(FetchDescriptor<AtlasRecord>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]))
            if let record = records.first {
                record.payload = data
                record.updatedAt = stamp
                for extra in records.dropFirst() { context.delete(extra) }
            } else {
                context.insert(AtlasRecord(payload: data, updatedAt: stamp))
            }
            try context.save()
            lastSaveFailed = false
        } catch {
            lastSaveFailed = true
        }
    }

    /// Sets the atlas without stamping it as a new edit.
    private func apply(_ value: Atlas) {
        isApplying = true
        atlas = value
        isApplying = false
    }

    /// Replaces the whole atlas (import or reset) and saves it.
    func replace(with value: Atlas) {
        var copy = value
        copy.updatedAt = Date()
        apply(copy)
        saveNow()
    }

    func eraseEverything() {
        saveTask?.cancel()
        let records = (try? context.fetch(FetchDescriptor<AtlasRecord>())) ?? []
        for r in records { context.delete(r) }
        try? context.save()
        apply(Atlas())
    }

    // MARK: Bindings into lists

    /// A binding to one item in a list, found by id, that survives deletions.
    func binding<Item: Identifiable & Sendable>(_ list: WritableKeyPath<Atlas, [Item]>, id: Item.ID, fallback: Item) -> Binding<Item> where Item.ID: Sendable {
        Binding(
            get: { [weak self] in
                MainActor.assumeIsolated {
                    self?.atlas[keyPath: list].first(where: { $0.id == id }) ?? fallback
                }
            },
            set: { [weak self] newValue in
                MainActor.assumeIsolated {
                    guard let self, let i = self.atlas[keyPath: list].firstIndex(where: { $0.id == id }) else { return }
                    self.atlas[keyPath: list][i] = newValue
                }
            }
        )
    }
}

/// Which tab is showing and where the journey is.
@MainActor
final class AppRouter: ObservableObject {
    enum Tab: Hashable { case journey, atlas, learn }
    @Published var tab: Tab = .journey
    @Published var journeyPath: [Stage] = []
    @Published var showingExample = false
    @Published var showingSettings = false

    func open(_ stage: Stage) {
        tab = .journey
        journeyPath = [stage]
    }

    func openAtlas() {
        tab = .atlas
        journeyPath = []
    }
}
