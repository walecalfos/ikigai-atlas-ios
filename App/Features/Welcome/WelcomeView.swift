import SwiftUI
import IkigaiCore

struct WelcomeView: View {
    enum Destination { case begin, example, learn }
    let onFinish: (Destination) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.xl) {
                HStack(alignment: .top, spacing: Space.l) {
                    NacreTablet(padding: Space.m) {
                        VStack(spacing: 0) {
                            ForEach(["生", "き", "甲", "斐"], id: \.self) { ch in
                                Text(ch)
                                    .font(.custom("ShipporiMinchoB1-ExtraBold", size: 46, relativeTo: .largeTitle))
                                    .foregroundStyle(Palette.ink)
                            }
                        }
                    }
                    .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: Space.s) {
                        Eyebrow(text: "A framework anyone can use")
                        (Text("生き ").font(.custom("ShipporiMinchoB1-Bold", size: 17, relativeTo: .body)).foregroundStyle(Palette.ink)
                         + Text("iki, living").font(Typo.body2).foregroundStyle(Palette.ink2))
                        (Text("甲斐 ").font(.custom("ShipporiMinchoB1-Bold", size: 17, relativeTo: .body)).foregroundStyle(Palette.ink)
                         + Text("gai, worth").font(Typo.body2).foregroundStyle(Palette.ink2))
                    }
                    .padding(.top, Space.xs)
                }

                Text("Map what makes your life worth living.")
                    .font(Typo.display)
                    .foregroundStyle(Palette.ink)
                    .accessibilityAddTraits(.isHeader)

                Text("In Japan, ikigai is not one grand purpose at the centre of a diagram. It is the people, pursuits and small moments that make life feel worth living, and the felt sense that it is. Ikigai Atlas finds yours from the evidence of your own life.")
                    .font(Typo.body)
                    .foregroundStyle(Palette.ink2)

                VStack(alignment: .leading, spacing: Space.s) {
                    WelcomePoint(symbol: "square.stack.3d.up", title: "Plural, not singular",
                                 text: "You’ll map many sources of ikigai, large and small, rather than hunt for one answer.")
                    WelcomePoint(symbol: "circle.grid.cross", title: "All of life, not only work",
                                 text: "Eight areas of life sit side by side. The famous four-circle career diagram is there as an optional lens.")
                    WelcomePoint(symbol: "text.book.closed", title: "Evidence before insight",
                                 text: "You start from real memories and real weeks, because people guess poorly about purpose in the abstract.")
                    WelcomePoint(symbol: "lock", title: "Private by design",
                                 text: "Your answers stay on your iPhone and in your own iCloud. No accounts, no tracking.")
                }

                VStack(spacing: Space.s) {
                    Button { onFinish(.begin) } label: {
                        Text("Begin your atlas").frame(maxWidth: .infinity)
                    }
                    .atlasButton(.primary, size: .large)
                    HStack(spacing: Space.s) {
                        Button { onFinish(.example) } label: { Text("See an example").frame(maxWidth: .infinity) }
                            .atlasButton(.secondary)
                        Button { onFinish(.learn) } label: { Text("What is ikigai?").frame(maxWidth: .infinity) }
                            .atlasButton(.secondary)
                    }
                    Text("Six stages · about 75 minutes · saves as you go")
                        .font(Typo.caption)
                        .foregroundStyle(Palette.ink3)
                }
            }
            .padding(.horizontal, Space.l)
            .padding(.vertical, Space.xl)
        }
        .background(Palette.canvas.ignoresSafeArea())
    }
}

private struct WelcomePoint: View {
    let symbol: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Space.s) {
            Image(systemName: symbol)
                .font(Typo.bodyStrong)
                .foregroundStyle(Palette.brand)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Typo.bodyStrong).foregroundStyle(Palette.ink)
                Text(text).font(Typo.body2).foregroundStyle(Palette.ink2)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
