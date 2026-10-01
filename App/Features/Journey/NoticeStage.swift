import SwiftUI
import IkigaiCore

struct NoticeStage: View {
    @EnvironmentObject private var store: AtlasStore
    @State private var newJoy = ""
    @State private var newActivity = ""

    var body: some View {
        let quick = Framework.quickActivities.filter { q in !store.atlas.activities.contains { $0.name.normalizedKey == q.normalizedKey } }
        StageScreen(stage: .notice) {
            VStack(alignment: .leading, spacing: Space.s) {
                SectionHeading(title: "Small joys",
                               hint: "Little things that make an ordinary day worth it. Aim for seven or more. The smaller and more specific, the better.")
                if !store.atlas.joys.isEmpty {
                    FlowLayout(spacing: Space.xs) {
                        ForEach(Array(store.atlas.joys.enumerated()), id: \.offset) { index, joy in
                            RemovableChip(title: joy) { store.atlas.joys.remove(at: index) }
                        }
                    }
                }
                HStack(spacing: Space.xs) {
                    LineField(prompt: "e.g. The first sip of tea", text: $newJoy, label: "Add a small joy", onSubmit: addJoy)
                    Button("Add", action: addJoy).atlasButton(.primary).disabled(!newJoy.hasText)
                }
            }

            VStack(alignment: .leading, spacing: Space.s) {
                SectionHeading(title: "Energy audit",
                               hint: "List what fills a typical week. Rate how each leaves your energy, from −2 (drains a lot) to +2 (fills a lot), and how meaningful it feels, from 1 to 5.")
                if !store.atlas.activities.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(store.atlas.activities) { activity in
                            ActivityRow(activity: store.binding(\.activities, id: activity.id, fallback: activity)) {
                                store.atlas.activities.removeAll { $0.id == activity.id }
                            }
                            if activity.id != store.atlas.activities.last?.id {
                                Rectangle().fill(Palette.line).frame(height: Stroke.hairline)
                            }
                        }
                    }
                    .padding(.horizontal, Space.m)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.line, lineWidth: Stroke.hairline))
                }
                if !quick.isEmpty {
                    FlowLayout(spacing: Space.xs) {
                        ForEach(quick, id: \.self) { name in
                            AddChip(title: name) { store.atlas.activities.append(Activity(name: name)) }
                        }
                    }
                }
                HStack(spacing: Space.xs) {
                    LineField(prompt: "Add your own activity", text: $newActivity, label: "Add an activity", onSubmit: addActivity)
                    Button("Add", action: addActivity).atlasButton(.primary).disabled(!newActivity.hasText)
                }
                if store.atlas.namedActivities.count >= 2 {
                    Panel { EnergyMapChart(activities: store.atlas.activities) }
                }
            }

            FieldBlock(label: "When do you lose track of time?",
                       hint: "Flow: fully absorbed, challenged but not overwhelmed.",
                       prompt: "Fixing a tricky spreadsheet, gardening, long conversations…",
                       text: $store.atlas.flow)
            FieldBlock(label: "What do people come to you for?",
                       hint: "Advice, help, a particular kind of company. Separate with commas.",
                       prompt: "Calm in a crisis, fixing things, honest feedback…",
                       text: $store.atlas.seekYouFor)

            Panel {
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: Space.s) {
                        Text("Others often see our ikigai before we do. Send these three questions to people who know you well, then note what they say.")
                            .font(Typo.body2)
                            .foregroundStyle(Palette.ink2)
                        Text(Framework.askOthersMessage)
                            .font(Typo.body2)
                            .foregroundStyle(Palette.ink)
                            .padding(Space.s)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Palette.canvas, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
                            .textSelection(.enabled)
                        ShareLink(item: Framework.askOthersMessage) {
                            Label("Send the questions", systemImage: "square.and.arrow.up")
                        }
                        .atlasButton(.secondary)
                        FieldBlock(label: "What did they say?", prompt: "Their words, as close as you can get.", text: $store.atlas.others)
                    }
                    .padding(.top, Space.s)
                } label: {
                    Text("Optional: ask three people who know you")
                        .font(Typo.bodyStrong)
                        .foregroundStyle(Palette.ink)
                }
                .tint(Palette.brand)
            }
        }
    }

    private func addJoy() {
        let text = newJoy.trimmed
        guard !text.isEmpty else { return }
        if !store.atlas.joys.contains(where: { $0.normalizedKey == text.normalizedKey }) {
            store.atlas.joys.append(text)
        }
        newJoy = ""
    }

    private func addActivity() {
        let text = newActivity.trimmed
        guard !text.isEmpty else { return }
        store.atlas.activities.append(Activity(name: text))
        newActivity = ""
    }
}

private struct ActivityRow: View {
    @Binding var activity: Activity
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            HStack {
                TextField("Activity", text: $activity.name)
                    .font(Typo.bodyStrong)
                    .foregroundStyle(Palette.ink)
                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "minus.circle")
                }
                .tint(Palette.ink3)
                .accessibilityLabel("Remove \(activity.name)")
            }
            HStack(spacing: Space.s) {
                Text("Energy").font(Typo.caption).foregroundStyle(Palette.ink3).frame(width: 56, alignment: .leading)
                Picker("Energy", selection: $activity.energy) {
                    ForEach(-2...2, id: \.self) { e in Text(e > 0 ? "+\(e)" : (e < 0 ? "−\(-e)" : "0")).tag(e) }
                }
                .pickerStyle(.segmented)
            }
            HStack(spacing: Space.s) {
                Text("Meaning").font(Typo.caption).foregroundStyle(Palette.ink3).frame(width: 56, alignment: .leading)
                Picker("Meaning", selection: $activity.meaning) {
                    ForEach(1...5, id: \.self) { m in Text("\(m)").tag(m) }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(.vertical, Space.s)
    }
}

/// A small joy with a remove button.
struct RemovableChip: View {
    let title: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: Space.xxs) {
            Text(title).font(Typo.body2).foregroundStyle(Palette.ink)
            Button(action: onRemove) {
                Image(systemName: "xmark").font(Typo.caption2).foregroundStyle(Palette.ink3)
            }
            .accessibilityLabel("Remove \(title)")
        }
        .padding(.leading, Space.s)
        .padding(.trailing, Space.xs)
        .padding(.vertical, Space.xs - 2)
        .background(Palette.surface, in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.line, lineWidth: Stroke.hairline))
    }
}
