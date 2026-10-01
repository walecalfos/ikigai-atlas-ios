import SwiftUI
import IkigaiCore

struct RememberStage: View {
    @EnvironmentObject private var store: AtlasStore

    var body: some View {
        StageScreen(stage: .remember) {
            VStack(alignment: .leading, spacing: Space.m) {
                ForEach(Array(store.atlas.moments.enumerated()), id: \.element.id) { index, moment in
                    MomentCard(moment: store.binding(\.moments, id: moment.id, fallback: moment),
                               index: index,
                               canRemove: store.atlas.moments.count > 1) {
                        store.atlas.moments.removeAll { $0.id == moment.id }
                    }
                }
                if store.atlas.moments.count < 5 {
                    Button("Add another moment") {
                        store.atlas.moments.append(Moment())
                    }
                    .atlasButton(.secondary)
                }
            }

            FieldBlock(label: "As a child, what could you do for hours without anyone asking?",
                       hint: "Before other people’s expectations arrived. Think of what absorbed you, not what you were good at.",
                       prompt: "Drawing maps of imaginary countries, taking things apart…",
                       text: $store.atlas.childhood)
            FieldBlock(label: "In your hardest season, what kept you going?",
                       hint: "Optional, and skip it if it’s too much today. Kamiya developed her ideas among people who had lost almost everything; what remains in hard times often shows ikigai most clearly.",
                       prompt: "A person, a routine, a hope, a place, a belief…",
                       text: $store.atlas.anchor)
            FieldBlock(label: "If it all disappeared tomorrow, what would you miss most?",
                       prompt: "List a few, separated by commas.",
                       text: $store.atlas.missing)
        }
    }
}

private struct MomentCard: View {
    @Binding var moment: Moment
    let index: Int
    let canRemove: Bool
    let onRemove: () -> Void

    var body: some View {
        Panel {
            HStack {
                Eyebrow(text: "Moment \(index + 1)")
                Spacer()
                if canRemove {
                    Button("Remove", role: .destructive, action: onRemove)
                        .font(Typo.body2)
                        .tint(Palette.alert)
                }
            }
            VStack(alignment: .leading, spacing: Space.xs) {
                Text("Give it a short name").font(Typo.bodyStrong).foregroundStyle(Palette.ink)
                LineField(prompt: index == 0 ? "e.g. The night the power went out at the cabin" : "A few words you’d recognise it by",
                          text: $moment.title, label: "Moment name")
            }
            FieldBlock(label: "What happened, and what were you doing?",
                       prompt: "Where you were, what you did, what it was like.",
                       text: $moment.what)
            FieldBlock(label: "Who was there?", prompt: "Or nobody, which is telling too.", text: $moment.who, lines: 1...4)
            FieldBlock(label: "What exactly made it matter?", prompt: "The heart of it, in a sentence or two.", text: $moment.why)
            VStack(alignment: .leading, spacing: Space.xs) {
                Text("Which needs did it feed?").font(Typo.bodyStrong).foregroundStyle(Palette.ink)
                NeedChips(selection: $moment.needs)
            }
        }
    }
}
