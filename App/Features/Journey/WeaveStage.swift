import SwiftUI
import IkigaiCore

struct WeaveStage: View {
    @EnvironmentObject private var store: AtlasStore
    @State private var newLens = ""

    var body: some View {
        let words = store.atlas.recurringWords()
        StageScreen(stage: .weave) {
            VStack(alignment: .leading, spacing: Space.s) {
                SectionHeading(title: "Words that keep coming back",
                               hint: "Found across your answers. The number shows how many separate answers each appears in. Tap one to start a thread from it.")
                if words.isEmpty {
                    Text("Write a little more in stages 2 to 4 and your recurring words will appear here.")
                        .font(Typo.body2)
                        .foregroundStyle(Palette.ink3)
                } else {
                    FlowLayout(spacing: Space.xs) {
                        ForEach(words) { w in
                            ChoiceChip(title: "\(w.word)  \(w.answers)", isSelected: false) {
                                store.atlas.threads.append(AtlasThread(name: w.word))
                            }
                            .accessibilityLabel("\(w.word), in \(w.answers) answers")
                            .accessibilityHint("Starts a thread")
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: Space.s) {
                SectionHeading(title: "Your threads",
                               hint: "Two to four is typical. Use verbs where you can: “teaching”, “making order”, “being outdoors with others”.")
                ForEach(Array(store.atlas.threads.enumerated()), id: \.element.id) { index, thread in
                    ThreadCard(thread: store.binding(\.threads, id: thread.id, fallback: thread), index: index) {
                        store.atlas.threads.removeAll { $0.id == thread.id }
                    }
                }
                Button("Add a thread") { store.atlas.threads.append(AtlasThread()) }
                    .atlasButton(.secondary)
            }

            ReadingPanel()

            VStack(alignment: .leading, spacing: Space.s) {
                SectionHeading(title: "Your ikigai, in a sentence",
                               hint: "Not a job title and not the whole of your ikigai: a way of recognising what makes life worth living for you. Use the builder, or write freely.")
                Panel {
                    VStack(alignment: .leading, spacing: Space.xs) {
                        Text("Life feels most worth living when I…").font(Typo.bodyStrong).foregroundStyle(Palette.ink)
                        LineField(prompt: "turn confusion into clarity", text: $store.atlas.parts.doing, label: "Life feels most worth living when I")
                    }
                    VStack(alignment: .leading, spacing: Space.xs) {
                        Text("With or for whom?").font(Typo.bodyStrong).foregroundStyle(Palette.ink)
                        LineField(prompt: "with my family / for people who feel stuck", text: $store.atlas.parts.whom, label: "With or for whom")
                    }
                    VStack(alignment: .leading, spacing: Space.xs) {
                        Text("Especially…").font(Typo.bodyStrong).foregroundStyle(Palette.ink)
                        LineField(prompt: "outdoors / slowly, with care", text: $store.atlas.parts.how, label: "Especially")
                    }
                    Text(store.atlas.parts.sentence ?? "Your sentence will appear here.")
                        .font(Typo.body)
                        .foregroundStyle(store.atlas.parts.sentence == nil ? Palette.ink3 : Palette.ink)
                    Button("Use this sentence") {
                        if let s = store.atlas.parts.sentence { store.atlas.statement = s }
                    }
                    .atlasButton(.secondary)
                    .disabled(store.atlas.parts.sentence == nil)
                }
                FieldBlock(label: "Your statement",
                           hint: "Edit until it sounds like you. Read it aloud; you should recognise yourself.",
                           prompt: "Life feels most worth living when…",
                           text: $store.atlas.statement)
            }

            Panel {
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: Space.s) {
                        Text("This is the popular Western purpose diagram, not the Japanese concept. It’s still useful for career questions. Add roles or activities and mark which circles each sits in.")
                            .font(Typo.body2)
                            .foregroundStyle(Palette.ink2)
                        ForEach(store.atlas.lens) { item in
                            LensRow(item: store.binding(\.lens, id: item.id, fallback: item)) {
                                store.atlas.lens.removeAll { $0.id == item.id }
                            }
                        }
                        HStack(spacing: Space.xs) {
                            LineField(prompt: "e.g. Teaching, data analysis", text: $newLens, label: "Add a work lens item", onSubmit: addLens)
                            Button("Add", action: addLens).atlasButton(.primary).disabled(!newLens.hasText)
                        }
                    }
                    .padding(.top, Space.s)
                } label: {
                    Text("Optional: the work lens (the four circles)")
                        .font(Typo.bodyStrong)
                        .foregroundStyle(Palette.ink)
                }
                .tint(Palette.brand)
            }
        }
    }

    private func addLens() {
        let text = newLens.trimmed
        guard !text.isEmpty else { return }
        store.atlas.lens.append(LensItem(text: text))
        newLens = ""
    }
}

private struct ThreadCard: View {
    @Binding var thread: AtlasThread
    let index: Int
    let onRemove: () -> Void

    var body: some View {
        Panel {
            HStack {
                Eyebrow(text: "Thread \(index + 1)")
                Spacer()
                Button("Remove", role: .destructive, action: onRemove).font(Typo.body2).tint(Palette.alert)
            }
            LineField(prompt: "e.g. Making the complicated clear", text: $thread.name, label: "Thread name")
            FieldBlock(label: "Where does it show up?", prompt: "Which moments, joys and sources carry this thread?", text: $thread.note, lines: 1...5)
        }
    }
}

private struct LensRow: View {
    @Binding var item: LensItem
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            HStack {
                TextField("Role or activity", text: $item.text).font(Typo.bodyStrong)
                Button(role: .destructive, action: onRemove) { Image(systemName: "minus.circle") }
                    .tint(Palette.ink3)
                    .accessibilityLabel("Remove \(item.text)")
            }
            FlowLayout(spacing: Space.xs) {
                ChoiceChip(title: "Love", isSelected: item.love) { item.love.toggle() }
                ChoiceChip(title: "Good at", isSelected: item.good) { item.good.toggle() }
                ChoiceChip(title: "World needs", isSelected: item.needed) { item.needed.toggle() }
                ChoiceChip(title: "Paid for", isSelected: item.paid) { item.paid.toggle() }
            }
            Text(item.label).font(Typo.caption).foregroundStyle(Palette.ink2)
        }
        .padding(.vertical, Space.xs)
    }
}

/// The optional on-device pattern reading.
struct ReadingPanel: View {
    @EnvironmentObject private var store: AtlasStore
    @EnvironmentObject private var reader: PatternReader

    var body: some View {
        let availability = reader.availability
        VStack(alignment: .leading, spacing: Space.s) {
            SectionHeading(title: "A second pair of eyes", hint: "Optional")
            Panel {
                if reader.isRunning {
                    HStack(spacing: Space.s) {
                        BusyIndicator()
                        Text("Reading your answers on this iPhone. This usually takes under a minute.")
                            .font(Typo.body2)
                            .foregroundStyle(Palette.ink2)
                    }
                    Button("Stop") { reader.cancel() }.atlasButton(.secondary, size: .small)
                } else if let reading = store.atlas.reading, !reading.isEmpty {
                    ReadingResults(reading: reading)
                    if availability == .available {
                        Button("Read again with my latest answers") { run() }
                            .atlasButton(.subtle, size: .small)
                    }
                } else if availability == .available {
                    Text("Apple Intelligence reads only what you’ve written here and suggests threads, statements and experiments in your own words. It runs entirely on your iPhone. You decide what to keep.")
                        .font(Typo.body2)
                        .foregroundStyle(Palette.ink2)
                    Button("Look for patterns") { run() }
                        .atlasButton(.primary)
                        .disabled(!store.atlas.hasEnoughForReading)
                    if !store.atlas.hasEnoughForReading {
                        Text("Answer a few more questions in stages 2 to 4 first.").font(Typo.caption).foregroundStyle(Palette.ink3)
                    }
                } else {
                    Text(availability.explanation)
                        .font(Typo.body2)
                        .foregroundStyle(Palette.ink2)
                }
                if let message = reader.errorMessage {
                    Text(message).font(Typo.body2).foregroundStyle(Palette.hungry)
                }
            }
        }
    }

    private func run() {
        let store = self.store
        reader.read(store.atlas) { reading in
            store.atlas.reading = reading
        }
    }
}

private struct ReadingResults: View {
    @EnvironmentObject private var store: AtlasStore
    let reading: Reading

    var body: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            if !reading.pattern.isEmpty {
                (Text("A pattern you may not have noticed. ").font(Typo.bodyStrong) + Text(reading.pattern).font(Typo.body))
                    .foregroundStyle(Palette.ink)
            }
            if !reading.tension.isEmpty {
                (Text("A tension. ").font(Typo.bodyStrong) + Text(reading.tension).font(Typo.body))
                    .foregroundStyle(Palette.ink)
            }
            if !reading.threads.isEmpty {
                VStack(alignment: .leading, spacing: Space.xs) {
                    Eyebrow(text: "Suggested threads")
                    ForEach(reading.threads) { t in
                        let added = store.atlas.threads.contains { $0.name.normalizedKey == t.name.normalizedKey }
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t.name).font(Typo.bodyStrong).foregroundStyle(Palette.ink)
                                Text(t.why + (t.evidence.isEmpty ? "" : " Seen in: " + t.evidence.map { "“\($0)”" }.joined(separator: ", ") + "."))
                                    .font(Typo.body2)
                                    .foregroundStyle(Palette.ink2)
                            }
                            Spacer()
                            Button(added ? "Added" : "Add") {
                                store.atlas.threads.append(AtlasThread(name: t.name, note: t.evidence.joined(separator: ", ")))
                            }
                            .atlasButton(.secondary, size: .small)
                            .disabled(added)
                        }
                    }
                }
            }
            if !reading.statements.isEmpty {
                VStack(alignment: .leading, spacing: Space.xs) {
                    Eyebrow(text: "Draft statements")
                    ForEach(reading.statements, id: \.self) { s in
                        HStack(alignment: .top) {
                            Text(s).font(Typo.body).foregroundStyle(Palette.ink)
                            Spacer()
                            Button("Use") { store.atlas.statement = s }
                                .atlasButton(.secondary, size: .small)
                        }
                    }
                }
            }
            if !reading.question.isEmpty {
                VStack(alignment: .leading, spacing: Space.xs) {
                    Eyebrow(text: "A question to sit with")
                    Text(reading.question).font(Typo.title1).foregroundStyle(Palette.ink)
                }
            }
        }
    }
}
