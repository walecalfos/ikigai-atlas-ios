import SwiftUI
import UniformTypeIdentifiers
import IkigaiCore

struct SettingsView: View {
    @EnvironmentObject private var store: AtlasStore
    @EnvironmentObject private var lock: AppLock
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingErase = false
    @State private var importing = false
    @State private var shareItem: ShareItem?
    @State private var message: String?
    @State private var lockOn = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ReminderControls()
                } header: {
                    Text("Reminders")
                } footer: {
                    Text("Your morning and evening questions, sent as notifications from this iPhone. Change the questions in stage 6.")
                }

                Section {
                    Toggle(isOn: $lockOn) {
                        Text("Lock with \(lock.methodName)")
                    }
                    .disabled(!lock.isAvailable)
                    .onAppear { lockOn = lock.isEnabled }
                    .onChange(of: lockOn) { _, on in if on != lock.isEnabled { lock.setEnabled(on) } }
                    .onChange(of: lock.isEnabled) { _, on in lockOn = on }
                } header: {
                    Text("Privacy")
                } footer: {
                    Text(lock.isAvailable
                         ? "Asks for \(lock.methodName) when you open the app, and hides your answers in the app switcher."
                         : "Set a passcode on this iPhone to use the lock.")
                }

                Section {
                    LabeledContent("Saved", value: store.syncsWithICloud ? "On this iPhone and in iCloud" : "On this iPhone")
                    Button("Export a backup") {
                        if let url = Exporter.backupFile(for: store.atlas) { shareItem = ShareItem(url: url) }
                    }
                    .disabled(!store.atlas.hasStarted)
                    Button("Restore from a backup") { importing = true }
                    if let message {
                        Text(message).font(Typo.caption).foregroundStyle(Palette.ink2)
                    }
                } header: {
                    Text("Your data")
                } footer: {
                    Text(store.syncsWithICloud
                         ? "Your atlas syncs privately through your own iCloud account. Nobody else, including the app’s maker, can read it."
                         : "Sign in to iCloud on this iPhone to sync your atlas privately across your devices.")
                }

                Section {
                    Button("Start a fresh atlas", role: .destructive) { confirmingErase = true }
                        .disabled(!store.atlas.hasStarted)
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                    Button("Show the welcome again") {
                        UserDefaults.standard.set(false, forKey: "hasSeenWelcome")
                        dismiss()
                    }
                    Text("Built on the research of Mieko Kamiya, Gordon Mathews, Ken Mogi and Akihiro Hasegawa. Designed with Microsoft’s Fluent 2 design system (MIT licence). Display type: Shippori Mincho B1 (SIL Open Font Licence).")
                        .font(Typo.caption)
                        .foregroundStyle(Palette.ink2)
                    Link("Fluent UI Apple on GitHub", destination: URL(string: "https://github.com/microsoft/fluentui-apple")!)
                    Link("Shippori Mincho on GitHub", destination: URL(string: "https://github.com/fontdasu/ShipporiMincho")!)
                }
            }
            .tint(Palette.brand)
            .scrollContentBackground(.hidden)
            .background(Palette.canvas.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
            .confirmationDialog("Erase your atlas and start again?", isPresented: $confirmingErase, titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) {
                    store.eraseEverything()
                    router.journeyPath = []
                    dismiss()
                }
            } message: {
                Text("This removes every answer from this iPhone\(store.syncsWithICloud ? " and from iCloud" : ""). Export a backup first if you might want it later.")
            }
            .sheet(item: $shareItem) { item in
                ActivityView(items: [item.url]).ignoresSafeArea()
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                    do {
                        let data = try Data(contentsOf: url)
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let atlas = try decoder.decode(Atlas.self, from: data)
                        store.replace(with: atlas)
                        message = "Restored your atlas from the backup."
                    } catch {
                        message = "That file isn’t an Ikigai Atlas backup, so nothing was changed."
                    }
                case .failure:
                    message = "The file couldn’t be opened, so nothing was changed."
                }
            }
        }
    }
}
