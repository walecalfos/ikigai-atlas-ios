import SwiftUI
import FluentUI
import IkigaiCore

// Fluent's iOS library exports UIKit types named `Button` and `Label`, so this file
// spells out `SwiftUI.Button` and `SwiftUI.Label`. Feature files don't import FluentUI
// and use these wrappers instead.

// MARK: - Buttons (Fluent 2)

enum AtlasButtonKind {
    case primary, secondary, subtle, danger

    fileprivate var fluent: FluentUI.ButtonStyle {
        switch self {
        case .primary: return .accent
        case .secondary: return .outlineNeutral
        case .subtle: return .subtle
        case .danger: return .dangerOutline
        }
    }
}

extension View {
    /// Applies Fluent 2's button style for the given role.
    func atlasButton(_ kind: AtlasButtonKind = .primary, size: ControlSize = .regular) -> some View {
        buttonStyle(FluentButtonStyle(style: kind.fluent))
            .controlSize(size)
    }
}

// MARK: - Chips (Fluent 2 pill buttons)

/// A selectable pill, built on Fluent's `FluentPillButtonStyle`.
struct ChoiceChip: View {
    let title: String
    let isSelected: Bool
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        SwiftUI.Button(action: action) {
            Text(title)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .buttonStyle(FluentPillButtonStyle(style: .primary,
                                           isSelected: isSelected,
                                           isUnread: false,
                                           leadingImage: systemImage.map { Image(systemName: $0) }))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A pill that adds something when tapped.
struct AddChip: View {
    let title: String
    let action: () -> Void

    var body: some View {
        SwiftUI.Button(action: action) {
            Text(title)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .buttonStyle(FluentPillButtonStyle(style: .primary, isSelected: false, isUnread: false,
                                           leadingImage: Image(systemName: "plus")))
        .accessibilityHint("Adds it to your atlas")
    }
}

/// A read-only pill.
struct TagChip: View {
    let title: String
    var body: some View {
        Text(title)
            .font(Typo.body2)
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, Space.s)
            .padding(.vertical, Space.xs - 2)
            .background(Palette.surfaceSunken, in: Capsule())
    }
}

// MARK: - Fluent progress and activity

struct AtlasProgressBar: View {
    let value: Double
    var body: some View {
        ProgressBar()
            .progress(min(max(value, 0), 1))
            .accessibilityLabel("Progress")
            .accessibilityValue("\(Int(value * 100)) percent")
    }
}

struct BusyIndicator: View {
    var body: some View {
        ActivityIndicator(size: .medium)
            .isAnimating(true)
            .hidesWhenStopped(false)
    }
}

// MARK: - Surfaces

/// A content card: Fluent background1 on the canvas, hairline stroke, 12pt corners.
struct Panel<Content: View>: View {
    var padding: CGFloat = Space.m
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.line, lineWidth: Stroke.hairline))
    }
}

/// The mother-of-pearl tablet used for the hero kanji and the ikigai statement.
struct NacreTablet<Content: View>: View {
    var padding: CGFloat = Space.l
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(Palette.nacre, in: RoundedRectangle(cornerRadius: Radius.sheet, style: .continuous))
            .applyFluentShadow(shadowInfo: FluentTheme.shared.shadow(.shadow02))
    }
}

// MARK: - Text blocks

struct Eyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(Typo.captionStrong)
            .tracking(1.2)
            .foregroundStyle(Palette.ink2)
    }
}

struct SectionHeading: View {
    let title: String
    var hint: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: Space.xxs) {
            Text(title).font(Typo.title3).foregroundStyle(Palette.ink)
            if let hint { Text(hint).font(Typo.body2).foregroundStyle(Palette.ink2) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// "Why this step": the research behind each stage.
struct WhyNote: View {
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: Space.xxs) {
            Text("WHY THIS STEP").font(Typo.captionStrong).tracking(1.2).foregroundStyle(Palette.brand)
            Text(text).font(Typo.body2).foregroundStyle(Palette.ink2)
        }
        .padding(.top, Space.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { Rectangle().fill(Palette.line).frame(height: Stroke.hairline) }
    }
}

struct StatusPill: View {
    let status: AuthStatus
    var body: some View {
        Text(status.name.uppercased())
            .font(Typo.caption2)
            .fontWeight(.semibold)
            .tracking(0.5)
            .foregroundStyle(color)
            .padding(.horizontal, Space.xs)
            .padding(.vertical, 2)
            .overlay(Capsule().strokeBorder(color, style: StrokeStyle(lineWidth: Stroke.hairline, dash: dash)))
    }
    private var color: Color {
        switch status {
        case .core: return Palette.brand
        case .growing: return Palette.ink2
        case .borrowed: return Palette.hungry
        case .untested: return Palette.ink3
        }
    }
    private var dash: [CGFloat] {
        switch status {
        case .borrowed: return [3, 2]
        case .untested: return [1, 2]
        default: return []
        }
    }
}

// MARK: - Inputs

/// A labelled multi-line text field in a Fluent surface.
struct FieldBlock: View {
    let label: String
    var hint: String? = nil
    var prompt: String = ""
    @Binding var text: String
    var lines: ClosedRange<Int> = 2...8

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(label).font(Typo.bodyStrong).foregroundStyle(Palette.ink)
            if let hint { Text(hint).font(Typo.body2).foregroundStyle(Palette.ink2) }
            TextField(prompt, text: $text, axis: .vertical)
                .lineLimit(lines)
                .font(Typo.body)
                .foregroundStyle(Palette.ink)
                .padding(Space.s)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.control, style: .continuous).strokeBorder(Palette.line, lineWidth: Stroke.hairline))
                .accessibilityLabel(label)
        }
    }
}

/// A single-line text field in a Fluent surface.
struct LineField: View {
    let prompt: String
    @Binding var text: String
    var label: String? = nil
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        TextField(prompt, text: $text)
            .font(Typo.body)
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, Space.s)
            .padding(.vertical, Space.xs + 2)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.control, style: .continuous).strokeBorder(Palette.line, lineWidth: Stroke.hairline))
            .submitLabel(onSubmit == nil ? .done : .return)
            .onSubmit { onSubmit?() }
            .accessibilityLabel(label ?? prompt)
    }
}

/// A row of numbered circles for rating on a scale.
struct RatingScale: View {
    @Binding var value: Int?
    let range: ClosedRange<Int>
    let lowLabel: String
    let highLabel: String
    let accessibilityName: String

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xxs) {
            FlowLayout(spacing: Space.xs) {
                ForEach(Array(range), id: \.self) { n in
                    let on = value == n
                    SwiftUI.Button {
                        value = n
                    } label: {
                        Text("\(n)")
                            .font(on ? Typo.bodyStrong : Typo.body)
                            .monospacedDigit()
                            .frame(width: 40, height: 40)
                            .foregroundStyle(on ? Palette.onBrand : Palette.ink)
                            .background(on ? Palette.brandFill : Palette.surface, in: Circle())
                            .overlay(Circle().strokeBorder(on ? Color.clear : Palette.line, lineWidth: Stroke.hairline))
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: on)
                    .accessibilityLabel("\(n)")
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            HStack {
                Text(lowLabel)
                Spacer()
                Text(highLabel)
            }
            .font(Typo.caption)
            .foregroundStyle(Palette.ink3)
            .frame(maxWidth: CGFloat(range.count) * 48)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityName)
    }
}

/// Choose one value from a small set, rendered as Fluent pills.
struct PillPicker<Value: Hashable>: View {
    let options: [(value: Value, label: String)]
    @Binding var selection: Value?
    var allowsDeselect = false

    var body: some View {
        FlowLayout(spacing: Space.xs) {
            ForEach(options.indices, id: \.self) { i in
                let option = options[i]
                ChoiceChip(title: option.label, isSelected: selection == option.value) {
                    selection = (allowsDeselect && selection == option.value) ? nil : option.value
                }
            }
        }
    }
}

/// Multi-select of Kamiya's seven needs.
struct NeedChips: View {
    @Binding var selection: [Need]
    var body: some View {
        FlowLayout(spacing: Space.xs) {
            ForEach(Need.allCases) { need in
                ChoiceChip(title: need.name, isSelected: selection.contains(need)) {
                    if let i = selection.firstIndex(of: need) { selection.remove(at: i) } else { selection.append(need) }
                }
            }
        }
    }
}

// MARK: - Layout

/// Wraps children onto new lines, like chips in a tag cloud.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            if x > 0 && x + size.width > maxWidth {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: min(widest, maxWidth), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
            if x > bounds.minX && x + size.width > bounds.maxX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: min(size.width, bounds.width), height: size.height))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Screen scaffolding

extension View {
    /// The canvas background and side gutters shared by every scrolling screen.
    func atlasScreen() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Palette.canvas.ignoresSafeArea())
    }
}
