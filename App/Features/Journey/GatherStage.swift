import SwiftUI
import IkigaiCore

struct GatherStage: View {
    @EnvironmentObject private var store: AtlasStore
    @State private var newSource = ""
    @State private var editing: EditingSource?

    var body: some View {
        let suggestions = store.atlas.sourceSuggestions()
        let sources = store.atlas.sources
        let areas = Set(sources.compactMap(\.domain)).count
        StageScreen(stage: .gather) {
            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: Space.s) {
                    SectionHeading(title: "From what you’ve written",
                                   hint: "Tap any that are genuine sources of ikigai for you. You can rename them after.")
                    FlowLayout(spacing: Space.xs) {
                        ForEach(suggestions) { s in
                            AddChip(title: s.text) { add(s.text) }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: Space.s) {
                SectionHeading(title: "Your sources",
                               hint: sources.isEmpty
                                   ? "Aim for six to twelve. Add one below or tap a suggestion above."
                                   : "\(sources.count) named across \(areas) of 8 areas. Tap a source to place it and test it.")
                ForEach(Array(sources.enumerated()), id: \.element.id) { index, source in
                    Button {
                        editing = EditingSource(id: source.id)
                    } label: {
                        SourceRow(source: source, number: index + 1)
                    }
                    .buttonStyle(.plain)
                }
                HStack(spacing: Space.xs) {
                    LineField(prompt: "e.g. My grandmother’s recipes, the sea", text: $newSource, label: "Add a source of ikigai") {
                        add(newSource)
                    }
                    Button("Add") { add(newSource) }
                        .atlasButton(.primary)
                        .disabled(!newSource.hasText)
                }
                Text("Stuck? Look across the eight areas: " + Domain.allCases.map { "\($0.name) (\($0.hint.lowercased()))" }.joined(separator: ", ") + ".")
                    .font(Typo.body2)
                    .foregroundStyle(Palette.ink2)
            }
        }
        .onAppear {
            if ScreenshotMode.current == .source, editing == nil, let first = store.atlas.sources.first {
                editing = EditingSource(id: first.id)
            }
        }
        .sheet(item: $editing) { item in
            SourceEditor(source: store.binding(\.sources, id: item.id, fallback: Source(id: item.id, text: ""))) {
                store.atlas.sources.removeAll { $0.id == item.id }
                editing = nil
            }
            .themed()
        }
    }

    private func add(_ raw: String) {
        let text = raw.trimmed
        guard !text.isEmpty else { return }
        let source = Source(text: text)
        store.atlas.sources.append(source)
        newSource = ""
        editing = EditingSource(id: source.id)
    }
}

private struct EditingSource: Identifiable {
    let id: String
}

private struct SourceRow: View {
    let source: Source
    let number: Int

    var body: some View {
        HStack(alignment: .top, spacing: Space.s) {
            Text("\(number)")
                .font(Typo.captionStrong)
                .monospacedDigit()
                .foregroundStyle(Palette.brand)
                .frame(width: 28, height: 28)
                .background(Palette.brandTint, in: Circle())
            VStack(alignment: .leading, spacing: Space.xxs) {
                Text(source.text.hasText ? source.text : "Untitled source")
                    .font(Typo.bodyStrong)
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.leading)
                FlowLayout(spacing: Space.xs) {
                    if let domain = source.domain {
                        Text(domain.name).font(Typo.caption).foregroundStyle(Palette.ink2)
                    } else {
                        Text("Choose an area").font(Typo.caption).foregroundStyle(Palette.hungry)
                    }
                    Text(String(repeating: "●", count: source.strength) + String(repeating: "○", count: 5 - source.strength))
                        .font(Typo.caption2)
                        .foregroundStyle(Palette.brand)
                        .accessibilityLabel("Strength \(source.strength) of 5")
                    StatusPill(status: source.authStatus)
                    if !source.needs.isEmpty {
                        Text("feeds \(source.needs.count) \(source.needs.count == 1 ? "need" : "needs")").font(Typo.caption).foregroundStyle(Palette.ink2)
                    }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(Typo.caption).foregroundStyle(Palette.ink3).padding(.top, 6)
        }
        .padding(Space.s)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.line, lineWidth: Stroke.hairline))
        .contentShape(Rectangle())
    }
}

/// A native form for placing and testing one source.
struct SourceEditor: View {
    @Binding var source: Source
    let onRemove: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingRemove = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Source of ikigai", text: $source.text, axis: .vertical)
                        .font(Typo.bodyStrong)
                } footer: {
                    HStack(spacing: Space.xs) {
                        Text("Status")
                        StatusPill(status: source.authStatus)
                    }
                }

                Section("Area of life") {
                    Picker("Area of life", selection: $source.domain) {
                        Text("Not chosen").tag(Domain?.none)
                        ForEach(Domain.allCases) { domain in
                            VStack(alignment: .leading) {
                                Text(domain.name)
                                Text(domain.hint).font(Typo.caption).foregroundStyle(Palette.ink2)
                            }
                            .tag(Domain?.some(domain))
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section {
                    Picker("Strength", selection: $source.strength) {
                        ForEach(1...5, id: \.self) { Text("\($0)").tag($0) }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("How much worth does it give your life?")
                } footer: {
                    Text("1 is a little, 5 is a great deal. Stronger sources sit nearer the centre of your map.")
                }

                Section("Which needs does it feed?") {
                    ForEach(Need.allCases) { need in
                        Button {
                            if let i = source.needs.firstIndex(of: need) { source.needs.remove(at: i) } else { source.needs.append(need) }
                        } label: {
                            HStack {
                                Text(need.name).foregroundStyle(Palette.ink)
                                Spacer()
                                if source.needs.contains(need) {
                                    Image(systemName: "checkmark").foregroundStyle(Palette.brand).fontWeight(.semibold)
                                }
                            }
                        }
                        .accessibilityAddTraits(source.needs.contains(need) ? .isSelected : [])
                    }
                }

                Section {
                    Picker("Belonging or becoming", selection: $source.mode) {
                        ForEach(Mode.allCases) { Text($0.name).tag(Mode?.some($0)) }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Belonging or becoming?")
                } footer: {
                    Text(source.mode?.hint ?? "Belonging: a role or group you are part of. Becoming: expressing who you are.")
                }

                Section {
                    Picker("When does it live", selection: $source.time) {
                        ForEach(TimeTag.allCases) { Text($0.name).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("When does it live?")
                } footer: {
                    Text("Memories and hopes count as sources too.")
                }

                Section {
                    ForEach(AuthenticityTest.allCases) { test in
                        VStack(alignment: .leading, spacing: Space.xs) {
                            Text(test.statement).font(Typo.body2)
                            Picker(test.statement, selection: $source.auth.at(\.[test])) {
                                ForEach(Answer.allCases) { Text($0.label).tag(Answer?.some($0)) }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }
                        .padding(.vertical, Space.xxs)
                    }
                } header: {
                    Text("Is it truly yours?")
                } footer: {
                    Text("Mieko Kamiya found that true ikigai is done freely, is entirely your own, and brings the felt sense that life is worth living.")
                }

                Section {
                    Button("Remove this source", role: .destructive) { confirmingRemove = true }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.canvas)
            .navigationTitle("Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
            .confirmationDialog("Remove “\(source.text)”?", isPresented: $confirmingRemove, titleVisibility: .visible) {
                Button("Remove", role: .destructive) { onRemove() }
            }
        }
        .presentationDetents([.large])
    }
}
