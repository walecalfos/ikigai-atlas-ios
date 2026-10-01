import SwiftUI
import IkigaiCore

struct LearnView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.xl) {
                    VStack(alignment: .leading, spacing: Space.s) {
                        Eyebrow(text: "Understand ikigai")
                        Text("What ikigai really means")
                            .font(Typo.largeTitle)
                            .foregroundStyle(Palette.ink)
                            .accessibilityAddTraits(.isHeader)
                        Text("A short, sourced guide to the concept this app is built on.")
                            .font(Typo.body)
                            .foregroundStyle(Palette.ink2)
                    }

                    LearnSection(title: "The word") {
                        Paragraph("生き甲斐 joins iki (生き, living) with kai (甲斐, worth, the effect of an effort), which softens to gai. Clinical psychologist Akihiro Hasegawa traces kai to the word for shell; shells were treasured in Japan’s Heian period (794 to 1185). It is an everyday word, part of a family that includes yarigai (worth doing) and hatarakigai (worth working for).")
                    }

                    LearnSection(title: "Two meanings: the source and the feeling") {
                        Paragraph("Psychiatrist Mieko Kamiya wrote the foundational study, Ikigai ni tsuite (1966), while caring for leprosy patients at the Nagashima Aiseien sanatorium. She saw that the word is used in two ways: for the source of worth (“this child is my ikigai”) and for ikigai-kan, the felt sense that life is worth living. She compared that feeling to Viktor Frankl’s sense of meaning.")
                        Paragraph("She also described what marks a true source of ikigai. It gives you the feeling of ikigai. It need not bring any practical benefit. You do it spontaneously, because you want to. And it is entirely individual: it cannot be borrowed or copied from someone else.")
                        Paragraph("She found the feeling depends on meeting some combination of seven needs:")
                        FlowLayout(spacing: Space.xs) {
                            ForEach(Need.allCases) { need in
                                HStack(spacing: 6) {
                                    Text(need.japanese).font(.custom("ShipporiMinchoB1-Bold", size: 14, relativeTo: .footnote)).foregroundStyle(Palette.ink3)
                                    Text(need.name).font(Typo.body2).foregroundStyle(Palette.ink)
                                }
                                .padding(.horizontal, Space.s)
                                .padding(.vertical, Space.xs)
                                .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.control))
                                .overlay(RoundedRectangle(cornerRadius: Radius.control).strokeBorder(Palette.line, lineWidth: Stroke.hairline))
                            }
                        }
                        Note("Stage 1 measures these seven needs. Stage 4 tests your sources against her characteristics.")
                    }

                    LearnSection(title: "Belonging and becoming") {
                        Paragraph("Anthropologist Gordon Mathews interviewed Japanese adults and found ikigai tends to take two forms: ittaikan (一体感), commitment to a group or role such as family or company, and jiko jitsugen (自己実現), self-realisation. Most people live somewhere between the two. Stage 4 asks which each of your sources is.")
                    }

                    LearnSection(title: "Small things, and time") {
                        Paragraph("Neuroscientist Ken Mogi describes five pillars of ikigai: starting small, releasing yourself (accepting who you are), harmony and sustainability, the joy of little things, and being in the here and now. Hasegawa found that Japanese people see the accumulation of small daily joys as what makes a whole life fulfilling, and that ikigai can come from the past, the present and the future.")
                    }

                    VStack(alignment: .leading, spacing: Space.s) {
                        Text("The diagram you’ve probably seen").font(Typo.title1).foregroundStyle(Palette.ink)
                        Paragraph("The four overlapping circles (what you love, what you’re good at, what the world needs, what you can be paid for) are not Japanese. Spanish author Andrés Zuzunaga drew the diagram in 2011 to illustrate propósito, purpose. In 2014 British blogger Marc Winn, after hearing about Okinawa in a Blue Zones talk, relabelled its centre “ikigai”, and the image spread worldwide. Winn has since said it doesn’t capture the Japanese meaning.")
                        Paragraph("It remains a useful career tool, so this app keeps it as an optional work lens in stage 5. But in a 2010 survey of 2,000 Japanese adults, only 31% named work as their ikigai.")
                    }
                    .padding(Space.m)
                    .overlay(RoundedRectangle(cornerRadius: Radius.card).strokeBorder(Palette.hungry, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))

                    LearnSection(title: "Why it matters") {
                        Paragraph("The Ohsaki Study followed 43,391 Japanese adults aged 40 to 79 for seven years. Those who said they did not have ikigai had a higher risk of death from all causes, mainly cardiovascular disease and external causes, but not cancer, even after adjusting for known risk factors. A 2022 study of older Japanese adults found that having ikigai predicted later happiness, life satisfaction and fewer depressive symptoms.")
                        Paragraph("These are observational studies. They show that ikigai goes with better health and wellbeing, not that it causes it.")
                    }

                    LearnSection(title: "How this app uses it") {
                        Grid(alignment: .leading, horizontalSpacing: Space.s, verticalSpacing: Space.s) {
                            GridRow {
                                Text("Idea").font(Typo.captionStrong)
                                Text("From").font(Typo.captionStrong)
                                Text("Where").font(Typo.captionStrong)
                            }
                            .foregroundStyle(Palette.ink2)
                            ForEach(Self.mapping, id: \.0) { row in
                                GridRow(alignment: .top) {
                                    Text(row.0).font(Typo.body2).foregroundStyle(Palette.ink)
                                    Text(row.1).font(Typo.body2).foregroundStyle(Palette.ink2)
                                    Text(row.2).font(Typo.body2).foregroundStyle(Palette.ink2)
                                }
                            }
                        }
                        .padding(Space.m)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card))
                        .overlay(RoundedRectangle(cornerRadius: Radius.card).strokeBorder(Palette.line, lineWidth: Stroke.hairline))
                    }

                    LearnSection(title: "Sources") {
                        VStack(alignment: .leading, spacing: Space.xs) {
                            ForEach(Self.sources, id: \.0) { item in
                                Link(destination: URL(string: item.1)!) {
                                    HStack(alignment: .top) {
                                        Text(item.0).font(Typo.body2).multilineTextAlignment(.leading)
                                        Spacer(minLength: Space.xs)
                                        Image(systemName: "arrow.up.right").font(Typo.caption)
                                    }
                                }
                                .tint(Palette.brand)
                            }
                        }
                    }
                }
                .padding(.horizontal, Space.m)
                .padding(.vertical, Space.l)
            }
            .atlasScreen()
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    static let mapping: [(String, String, String)] = [
        ("Source and feeling", "Kamiya", "Stage 1 measures the feeling, stage 4 maps the sources"),
        ("Seven needs", "Kamiya", "The pulse, the needs chart, which sources feed which need"),
        ("Free, personal, not for gain", "Kamiya", "The three tests on each source"),
        ("Past, present, future", "Hasegawa", "Memories, ordinary weeks, a time tag on each source"),
        ("Small daily joys", "Mogi, Hasegawa", "The small joys in stage 3"),
        ("Belonging and becoming", "Mathews", "The tag on each source in stage 4"),
        ("Starting small", "Mogi", "One-week experiments in stage 6"),
        ("Four circles", "Zuzunaga, Winn", "The optional work lens in stage 5")
    ]

    static let sources: [(String, String)] = [
        ("Ikigai sources and ikigai-kan (Kamiya’s two meanings and seven needs), Ikigai Tribe", "https://ikigaitribe.com/ikigai/ikigai-sources-ikigai-kan/"),
        ("The characteristics of ikigai according to Mieko Kamiya", "https://ikigai-scholar.medium.com/the-characteristics-of-ikigai-f8a8ef0009b3"),
        ("Gordon Mathews, What Makes Life Worth Living?", "https://ikigaitribe.com/ikigai/what-makes-life-worth-living/"),
        ("Ken Mogi on the five pillars of ikigai", "https://ikigaitribe.com/podcasts/podcast06/"),
        ("The temporal dimension of ikigai (Hasegawa)", "https://ikigaitribe.com/blogpost/the-temporal-dimension-of-ikigai/"),
        ("World Economic Forum on the word’s origins and the 2010 survey", "https://www.weforum.org/stories/wellbeing-and-mental-health/is-this-japanese-concept-the-secret-to-a-long-life/"),
        ("Where the four-circle diagram came from", "https://mindsera.com/frameworks/ikigai"),
        ("Marc Winn on merging ikigai with the purpose diagram", "https://ikigaitribe.com/ikigai/podcast05/"),
        ("Sone et al. (2008), the Ohsaki Study", "https://www.semanticscholar.org/paper/bffe858c706dc4298b8e1e947e2721bb580a6367"),
        ("Okuzono et al. (2022), ikigai and later health and wellbeing", "https://www.thelancet.com/pdfs/journals/lanwpc/PIIS2666-6065(22)00010-4.pdf")
    ]
}

private struct LearnSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Text(title).font(Typo.title1).foregroundStyle(Palette.ink).accessibilityAddTraits(.isHeader)
            content
        }
    }
}

private struct Paragraph: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View { Text(text).font(Typo.body).foregroundStyle(Palette.ink) }
}

private struct Note: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View { Text(text).font(Typo.body2).foregroundStyle(Palette.ink2) }
}
