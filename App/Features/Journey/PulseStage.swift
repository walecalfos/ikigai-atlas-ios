import SwiftUI
import IkigaiCore

struct PulseStage: View {
    @EnvironmentObject private var store: AtlasStore

    var body: some View {
        let pulse = store.atlas.pulse
        StageScreen(stage: .pulse) {
            VStack(alignment: .leading, spacing: Space.xs) {
                Text("What should your atlas call you?").font(Typo.bodyStrong).foregroundStyle(Palette.ink)
                Text("Optional. A first name or nickname is enough.").font(Typo.body2).foregroundStyle(Palette.ink2)
                LineField(prompt: "Your name", text: $store.atlas.name, label: "Your name")
                    .textContentType(.givenName)
            }

            VStack(alignment: .leading, spacing: Space.s) {
                Text("These days, how worth living does your life feel?")
                    .font(Typo.bodyStrong)
                    .foregroundStyle(Palette.ink)
                RatingScale(value: $store.atlas.pulse.overall, range: 0...10,
                            lowLabel: "Barely", highLabel: "Deeply",
                            accessibilityName: "How worth living does your life feel, from 0 to 10")
            }

            if let overall = pulse.overall, overall <= 2 {
                SupportCard()
            }

            VStack(alignment: .leading, spacing: 0) {
                SectionHeading(title: "The seven needs", hint: "How true is each statement for you right now?")
                    .padding(.bottom, Space.xs)
                    .id("needs")
                ForEach(Need.allCases) { need in
                    VStack(alignment: .leading, spacing: Space.xs) {
                        HStack(alignment: .firstTextBaseline, spacing: Space.xs) {
                            Text(need.name).font(Typo.bodyStrong).foregroundStyle(Palette.ink)
                            Text(need.japanese).font(.custom("ShipporiMinchoB1-Bold", size: 14, relativeTo: .footnote)).foregroundStyle(Palette.ink3)
                                .accessibilityHidden(true)
                        }
                        Text(need.statement).font(Typo.body).foregroundStyle(Palette.ink2)
                        RatingScale(value: $store.atlas.pulse.at(\.[need]), range: 1...5,
                                    lowLabel: "Not true", highLabel: "Very true",
                                    accessibilityName: need.name)
                    }
                    .padding(.vertical, Space.m)
                    .overlay(alignment: .bottom) {
                        if need != .meaning { Rectangle().fill(Palette.line).frame(height: Stroke.hairline) }
                    }
                }
            }

            if store.atlas.ratedNeeds.count >= 4, let average = store.atlas.pulseAverage {
                Panel {
                    Eyebrow(text: "Your baseline").id("baseline")
                    HStack(alignment: .firstTextBaseline, spacing: Space.xs) {
                        Text(String(format: "%.1f", average)).font(Typo.display).monospacedDigit().foregroundStyle(Palette.ink)
                        Text("average of \(store.atlas.ratedNeeds.count) needs, out of 5").font(Typo.body2).foregroundStyle(Palette.ink2)
                    }
                    NeedsRadarChart(pulse: pulse)
                    baselineSummary
                    Text("You’ll come back to these in stage 6. Hungry needs are where small experiments pay off most.")
                        .font(Typo.body2)
                        .foregroundStyle(Palette.ink2)
                }
            }
        }
    }

    @ViewBuilder private var baselineSummary: some View {
        let rated = store.atlas.ratedNeeds
        let values = rated.compactMap { store.atlas.pulse[$0] }
        if let high = values.max(), let low = values.min() {
            let fed = rated.filter { store.atlas.pulse[$0] == high && high >= 4 }.map(\.name)
            let hungry = rated.filter { store.atlas.pulse[$0] == low && low <= 3 }.map(\.name)
            VStack(alignment: .leading, spacing: Space.xxs) {
                if !fed.isEmpty {
                    (Text("Most fed: ").font(Typo.bodyStrong).foregroundStyle(Palette.fed) + Text(TextTools.plainList(fed)).font(Typo.body).foregroundStyle(Palette.ink))
                }
                if !hungry.isEmpty {
                    (Text("Hungriest: ").font(Typo.bodyStrong).foregroundStyle(Palette.hungry) + Text(TextTools.plainList(hungry)).font(Typo.body).foregroundStyle(Palette.ink))
                }
            }
        }
    }
}

/// Shown when someone rates life as barely worth living. Calm, specific, and never in the way.
struct SupportCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Text("If life feels hard to live right now")
                .font(Typo.bodyStrong)
                .foregroundStyle(Palette.alert)
            Text("You don’t have to work through it alone. Talking to someone you trust helps, and so can a free, confidential helpline.")
                .font(Typo.body)
                .foregroundStyle(Palette.ink)
            VStack(alignment: .leading, spacing: Space.xs) {
                Link(destination: URL(string: "tel:116123")!) {
                    Label("Samaritans (UK and Ireland): 116 123", systemImage: "phone")
                }
                Link(destination: URL(string: "tel:988")!) {
                    Label("988 Suicide & Crisis Lifeline (US)", systemImage: "phone")
                }
                Link(destination: URL(string: "https://findahelpline.com")!) {
                    Label("Find a helpline in another country", systemImage: "globe")
                }
            }
            .font(Typo.body2Strong)
            .tint(Palette.brand)
            Text("This framework will be here whenever you want to continue.")
                .font(Typo.body2)
                .foregroundStyle(Palette.ink2)
        }
        .padding(Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.alert, lineWidth: Stroke.hairline))
    }
}
