import SwiftUI
import IkigaiCore

struct LiveStage: View {
    @EnvironmentObject private var store: AtlasStore

    var body: some View {
        let hungry = store.atlas.hungryNeeds()
        let existing = Set(store.atlas.experiments.map { $0.text.normalizedKey })
        let suggested = (store.atlas.reading?.experiments ?? []).filter { !existing.contains($0.text.normalizedKey) }
        StageScreen(stage: .live) {
            if !hungry.isEmpty {
                VStack(alignment: .leading, spacing: Space.s) {
                    SectionHeading(title: "Ideas for your hungriest needs", hint: "Based on your pulse. Tap to add, then make it your own.")
                    ForEach(hungry) { need in
                        Panel {
                            HStack(alignment: .firstTextBaseline) {
                                Text(need.name).font(Typo.bodyStrong).foregroundStyle(Palette.ink)
                                Text("\(store.atlas.pulse[need] ?? 0) of 5").font(Typo.body2Strong).foregroundStyle(Palette.hungry)
                            }
                            FlowLayout(spacing: Space.xs) {
                                ForEach(need.experimentIdeas.filter { !existing.contains($0.normalizedKey) }, id: \.self) { idea in
                                    AddChip(title: idea) { store.atlas.experiments.append(Experiment(text: idea, need: need)) }
                                }
                            }
                        }
                    }
                }
            }

            if !suggested.isEmpty {
                VStack(alignment: .leading, spacing: Space.s) {
                    SectionHeading(title: "Suggested by Apple Intelligence")
                    FlowLayout(spacing: Space.xs) {
                        ForEach(suggested) { e in
                            AddChip(title: e.text) { store.atlas.experiments.append(Experiment(text: e.text, need: e.need)) }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: Space.s) {
                SectionHeading(title: "Your experiments",
                               hint: "One to three. Each should take a week or less and touch a thread or a hungry need.")
                ForEach(Array(store.atlas.experiments.enumerated()), id: \.element.id) { index, experiment in
                    ExperimentCard(experiment: store.binding(\.experiments, id: experiment.id, fallback: experiment), index: index) {
                        store.atlas.experiments.removeAll { $0.id == experiment.id }
                    }
                }
                Button("Add an experiment") { store.atlas.experiments.append(Experiment()) }
                    .atlasButton(.secondary)
            }

            VStack(alignment: .leading, spacing: Space.s) {
                SectionHeading(title: "Your rhythm",
                               hint: "Two short questions, morning and evening, keep ikigai in view. Use these or write your own.")
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text("Morning question").font(Typo.bodyStrong).foregroundStyle(Palette.ink)
                    LineField(prompt: Framework.defaultMorningQuestion, text: $store.atlas.rhythm.morning, label: "Morning question")
                }
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text("Evening question").font(Typo.bodyStrong).foregroundStyle(Palette.ink)
                    LineField(prompt: Framework.defaultEveningQuestion, text: $store.atlas.rhythm.evening, label: "Evening question")
                }
                Panel { ReminderControls() }.id("reminders")
                ReviewDateControl()
            }
        }
        .onAppear {
            if !store.atlas.rhythm.morning.hasText && !store.atlas.rhythm.evening.hasText && store.atlas.hasStarted {
                store.atlas.rhythm.morning = Framework.defaultMorningQuestion
                store.atlas.rhythm.evening = Framework.defaultEveningQuestion
            }
        }
    }
}

private struct ExperimentCard: View {
    @Binding var experiment: Experiment
    let index: Int
    let onRemove: () -> Void

    var body: some View {
        Panel {
            HStack {
                Eyebrow(text: "Experiment \(index + 1)")
                Spacer()
                Button("Remove", role: .destructive, action: onRemove).font(Typo.body2).tint(Palette.alert)
            }
            VStack(alignment: .leading, spacing: Space.xs) {
                Text("What small thing will you try?").font(Typo.bodyStrong).foregroundStyle(Palette.ink)
                FieldBlock(label: "", prompt: "Small enough to start this week", text: $experiment.text, lines: 1...4)
            }
            VStack(alignment: .leading, spacing: Space.xs) {
                Text("When?").font(Typo.bodyStrong).foregroundStyle(Palette.ink)
                LineField(prompt: "e.g. Thursday evening", text: $experiment.when, label: "When")
            }
            Picker("Status", selection: $experiment.status) {
                ForEach(ExperimentStatus.allCases) { Text($0.name).tag($0) }
            }
            .pickerStyle(.segmented)
            HStack {
                Text("Feeds").font(Typo.bodyStrong).foregroundStyle(Palette.ink)
                Spacer()
                Picker("Need it feeds", selection: $experiment.need) {
                    Text("Choose a need").tag(Need?.none)
                    ForEach(Need.allCases) { Text($0.name).tag(Need?.some($0)) }
                }
                .pickerStyle(.menu)
                .tint(Palette.brand)
            }
        }
    }
}

/// Daily reminder switches. Settings live on this device only.
struct ReminderControls: View {
    @EnvironmentObject private var store: AtlasStore
    @AppStorage("morningOn") private var morningOn = false
    @AppStorage("morningMinutes") private var morningMinutes = 8 * 60
    @AppStorage("eveningOn") private var eveningOn = false
    @AppStorage("eveningMinutes") private var eveningMinutes = 21 * 60
    @State private var morningTime = Date()
    @State private var eveningTime = Date()
    @State private var permissionDenied = false

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Toggle(isOn: $morningOn) {
                Text("Remind me each morning").font(Typo.body).foregroundStyle(Palette.ink)
            }
            if morningOn {
                DatePicker("Morning time", selection: $morningTime, displayedComponents: .hourAndMinute)
                    .font(Typo.body2)
            }
            Toggle(isOn: $eveningOn) {
                Text("Remind me each evening").font(Typo.body).foregroundStyle(Palette.ink)
            }
            if eveningOn {
                DatePicker("Evening time", selection: $eveningTime, displayedComponents: .hourAndMinute)
                    .font(Typo.body2)
            }
            if permissionDenied {
                Text("Notifications are off for Ikigai Atlas. Turn them on in the Settings app to get reminders.")
                    .font(Typo.caption)
                    .foregroundStyle(Palette.hungry)
            }
        }
        .tint(Palette.brand)
        .onAppear {
            morningTime = Self.date(fromMinutes: morningMinutes)
            eveningTime = Self.date(fromMinutes: eveningMinutes)
        }
        .onChange(of: morningOn) { _, on in toggled(on) { morningOn = false } }
        .onChange(of: eveningOn) { _, on in toggled(on) { eveningOn = false } }
        .onChange(of: morningTime) { _, t in morningMinutes = Self.minutes(from: t); reschedule() }
        .onChange(of: eveningTime) { _, t in eveningMinutes = Self.minutes(from: t); reschedule() }
    }

    private func toggled(_ on: Bool, revert: @escaping () -> Void) {
        guard on else { reschedule(); return }
        Task { @MainActor in
            let granted = await Reminders.requestPermission()
            permissionDenied = !granted
            if !granted { revert() }
            reschedule()
        }
    }

    private func reschedule() {
        let settings = Reminders.Settings(morningOn: morningOn, morningMinutes: morningMinutes,
                                          eveningOn: eveningOn, eveningMinutes: eveningMinutes)
        let atlas = store.atlas
        Task { await Reminders.reschedule(settings, atlas: atlas) }
    }

    static func date(fromMinutes minutes: Int) -> Date {
        Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()) ?? Date()
    }

    static func minutes(from date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
}

/// When to come back and retake the pulse.
private struct ReviewDateControl: View {
    @EnvironmentObject private var store: AtlasStore
    @State private var date = Date()

    var body: some View {
        Panel {
            Text("When will you retake the pulse?").font(Typo.bodyStrong).foregroundStyle(Palette.ink)
            if store.atlas.rhythm.review != nil {
                DatePicker("Review date", selection: $date, in: Date()..., displayedComponents: .date)
                    .tint(Palette.brand)
                HStack {
                    Text("You’ll get a reminder that morning if reminders are allowed.").font(Typo.caption).foregroundStyle(Palette.ink2)
                    Spacer()
                    Button("Clear") { store.atlas.rhythm.review = nil }.atlasButton(.subtle, size: .small)
                }
            } else {
                Text("Ikigai changes with life. Researchers suggest checking in every few months.").font(Typo.body2).foregroundStyle(Palette.ink2)
                Button("In 90 days") {
                    store.atlas.rhythm.review = Calendar.current.date(byAdding: .day, value: 90, to: Date())
                }
                .atlasButton(.secondary)
            }
        }
        .onAppear { date = store.atlas.rhythm.review ?? Date() }
        .onChange(of: store.atlas.rhythm.review) { _, new in if let new, new != date { date = new } }
        .onChange(of: date) { _, new in
            if store.atlas.rhythm.review != nil && store.atlas.rhythm.review != new { store.atlas.rhythm.review = new }
        }
    }
}
