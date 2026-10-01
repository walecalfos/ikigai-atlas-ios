import SwiftUI
import IkigaiCore

// The three atlas charts, drawn with SwiftUI Canvas so they follow the theme in light and dark.
// Each one carries a plain-language accessibility summary; the lists beside them hold the detail.

// MARK: - Source map

struct SourceMapChart: View {
    let sources: [Source]

    var body: some View {
        let dots = SourceMap.layout(sources)
        let placedAreas = Set(sources.compactMap(\.domain)).count
        Canvas { ctx, size in
            let side: CGFloat = min(size.width, size.height)
            let k: CGFloat = side / CGFloat(SourceMap.size)
            let origin = CGPoint(x: (size.width - side) / 2, y: (size.height - side) / 2)
            func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: origin.x + CGFloat(x) * k, y: origin.y + CGFloat(y) * k) }
            func polar(_ r: Double, _ deg: Double) -> CGPoint {
                let p = SourceMap.point(radius: r, degrees: deg)
                return pt(p.x, p.y)
            }
            let c = pt(SourceMap.center, SourceMap.center)

            // Wedges
            for (i, domain) in Domain.allCases.enumerated() {
                let mid = SourceMap.angle(for: domain)
                var wedge = Path()
                wedge.addArc(center: c, radius: CGFloat(SourceMap.outerRadius) * k, startAngle: .degrees(mid - 22.5), endAngle: .degrees(mid + 22.5), clockwise: false)
                wedge.addArc(center: c, radius: CGFloat(SourceMap.innerRadius) * k, startAngle: .degrees(mid + 22.5), endAngle: .degrees(mid - 22.5), clockwise: true)
                wedge.closeSubpath()
                ctx.fill(wedge, with: .color(i.isMultiple(of: 2) ? Palette.canvas : Palette.brandTint.opacity(0.45)))
            }
            // Strength rings
            for strength in 1...5 {
                let r: CGFloat = CGFloat(SourceMap.radius(forStrength: strength)) * k
                ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(Palette.line), lineWidth: 1)
            }
            let edge: CGFloat = CGFloat(SourceMap.outerRadius) * k
            ctx.stroke(Path(ellipseIn: CGRect(x: c.x - edge, y: c.y - edge, width: edge * 2, height: edge * 2)), with: .color(Palette.line), lineWidth: 1)
            // Spokes
            for domain in Domain.allCases {
                let a = SourceMap.angle(for: domain) - 22.5
                var spoke = Path()
                spoke.move(to: polar(SourceMap.innerRadius, a))
                spoke.addLine(to: polar(SourceMap.outerRadius, a))
                ctx.stroke(spoke, with: .color(Palette.line), lineWidth: 1)
            }
            // Area names in the outer band
            let labelSize: CGFloat = max(9, min(12, 11 * k * 1.5))
            for domain in Domain.allCases {
                let name = domain.name.replacingOccurrences(of: " & ", with: " &\n")
                ctx.draw(Text(name)
                            .font(.system(size: labelSize, weight: .semibold))
                            .foregroundStyle(Palette.ink2),
                         at: polar(SourceMap.labelRadius, SourceMap.angle(for: domain)),
                         anchor: .center)
            }
            // Dots
            let dotR: CGFloat = CGFloat(SourceMap.dotRadius) * k
            for dot in dots {
                let p = pt(dot.x, dot.y)
                let rect = CGRect(x: p.x - dotR, y: p.y - dotR, width: dotR * 2, height: dotR * 2)
                let circle = Path(ellipseIn: rect)
                switch dot.status {
                case .core:
                    ctx.fill(circle, with: .color(Palette.brandFill))
                case .borrowed:
                    ctx.fill(circle, with: .color(Palette.surface))
                    ctx.stroke(circle, with: .color(Palette.hungry), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                case .growing, .untested:
                    ctx.fill(circle, with: .color(Palette.surface))
                    ctx.stroke(circle, with: .color(Palette.brand), lineWidth: 1.5)
                }
                let color: Color = dot.status == .core ? Palette.onBrand : (dot.status == .borrowed ? Palette.hungry : Palette.brand)
                ctx.draw(Text("\(dot.number)").font(.system(size: max(8, dotR * 0.95), weight: .bold)).foregroundStyle(color), at: p, anchor: .center)
            }
            // Hub
            let hubR: CGFloat = 20 * k
            let hub = Path(ellipseIn: CGRect(x: c.x - hubR, y: c.y - hubR, width: hubR * 2, height: hubR * 2))
            ctx.fill(hub, with: .color(Palette.surface))
            ctx.stroke(hub, with: .color(Palette.ink3), lineWidth: 1)
            ctx.draw(Text("生").font(.custom("ShipporiMinchoB1-ExtraBold", size: max(10, 20 * k))).foregroundStyle(Palette.ink), at: c, anchor: .center)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Map of \(dots.count) sources of ikigai across \(placedAreas) of 8 areas of life. Sources nearer the centre give more worth.")
    }
}

// MARK: - Needs radar

struct NeedsRadarChart: View {
    let pulse: Pulse
    /// How many sources feed each need, drawn as a dashed outline (0 to 3 or more).
    var coverage: [Need: Int]? = nil

    var body: some View {
        Canvas { ctx, size in
            let labelRoom: CGFloat = 54
            let r: CGFloat = max(40, min(size.width / 2 - labelRoom, size.height / 2 - 30))
            let c = CGPoint(x: size.width / 2, y: size.height / 2 + 4)
            let needs = Need.allCases
            func angle(_ i: Int) -> Double { (-90 + Double(i) * 360 / Double(needs.count)) * .pi / 180 }
            func pt(_ i: Int, _ v: Double) -> CGPoint {
                let a: Double = angle(i)
                let length: Double = Double(r) * v
                return CGPoint(x: c.x + CGFloat(length * cos(a)), y: c.y + CGFloat(length * sin(a)))
            }
            func polygon(_ values: [Double]) -> Path {
                var p = Path()
                for (i, v) in values.enumerated() {
                    if i == 0 { p.move(to: pt(i, v)) } else { p.addLine(to: pt(i, v)) }
                }
                p.closeSubpath()
                return p
            }
            for ring in 1...5 { ctx.stroke(polygon(Array(repeating: Double(ring) / 5, count: needs.count)), with: .color(Palette.line), lineWidth: 1) }
            for i in needs.indices {
                var spoke = Path()
                spoke.move(to: c)
                spoke.addLine(to: pt(i, 1))
                ctx.stroke(spoke, with: .color(Palette.line), lineWidth: 1)
            }
            if let coverage {
                let values = needs.map { Double(min(coverage[$0] ?? 0, 3)) / 3 }
                ctx.stroke(polygon(values), with: .color(Palette.fed), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
            }
            if needs.contains(where: { pulse[$0] != nil }) {
                let values = needs.map { Double(pulse[$0] ?? 0) / 5 }
                let shape = polygon(values)
                ctx.fill(shape, with: .color(Palette.brand.opacity(0.22)))
                ctx.stroke(shape, with: .color(Palette.brand), lineWidth: 2)
                for (i, v) in values.enumerated() where pulse[needs[i]] != nil {
                    let p = pt(i, v)
                    ctx.fill(Path(ellipseIn: CGRect(x: p.x - 3.5, y: p.y - 3.5, width: 7, height: 7)), with: .color(Palette.brand))
                }
            }
            for (i, need) in needs.enumerated() {
                let p = pt(i, 1.14)
                let a: Double = angle(i)
                let cx: Double = cos(a)
                let cy: Double = sin(a)
                let ax: CGFloat = abs(cx) < 0.25 ? 0.5 : (cx > 0 ? 0 : 1)
                let ay: CGFloat = cy < -0.6 ? 1 : (cy > 0.6 ? 0 : 0.5)
                let anchor = UnitPoint(x: ax, y: ay)
                let value = pulse[need].map { String($0) } ?? "–"
                let name = need.shortName.replacingOccurrences(of: " ", with: "\n")
                let label = Text(name).font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.ink)
                    + Text(" \(value)").font(.system(size: 12)).foregroundStyle(Palette.ink2)
                ctx.draw(label, at: p, anchor: anchor)
            }
        }
        .aspectRatio(1.1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Needs chart")
        .accessibilityValue(Need.allCases.map { "\($0.name) \(pulse[$0].map { "\($0) of 5" } ?? "not rated")" }.joined(separator: ", "))
    }
}

// MARK: - Energy map

struct EnergyMapChart: View {
    let activities: [Activity]

    var body: some View {
        let named = activities.filter { $0.name.hasText }
        Canvas { ctx, size in
            let plot = CGRect(x: 22, y: 6, width: size.width - 28, height: size.height - 34)
            func x(_ e: Int) -> CGFloat { plot.minX + 18 + CGFloat(e + 2) / 4 * (plot.width - 36) }
            func y(_ m: Int) -> CGFloat { plot.maxY - 16 - CGFloat(m - 1) / 4 * (plot.height - 46) }

            // Energising-and-meaningful zone
            ctx.fill(Path(roundedRect: CGRect(x: x(0), y: plot.minY, width: plot.maxX - x(0), height: y(3) - plot.minY), cornerRadius: 6),
                     with: .color(Palette.brandTint.opacity(0.7)))
            ctx.stroke(Path(roundedRect: plot, cornerRadius: 6), with: .color(Palette.line), lineWidth: 1)
            for m in 1...5 {
                var line = Path()
                line.move(to: CGPoint(x: plot.minX, y: y(m)))
                line.addLine(to: CGPoint(x: plot.maxX, y: y(m)))
                ctx.stroke(line, with: .color(Palette.line), lineWidth: m == 3 ? 1.2 : 0.6)
                ctx.draw(Text("\(m)").font(.system(size: 11)).foregroundStyle(Palette.ink3), at: CGPoint(x: plot.minX - 8, y: y(m)), anchor: .center)
            }
            var axis = Path()
            axis.move(to: CGPoint(x: x(0), y: plot.minY))
            axis.addLine(to: CGPoint(x: x(0), y: plot.maxY))
            ctx.stroke(axis, with: .color(Palette.ink3), lineWidth: 1)

            let q = Font.system(size: 9, weight: .bold)
            ctx.draw(Text("DRAINING BUT\nMEANINGFUL").font(q).foregroundStyle(Palette.ink3), at: CGPoint(x: plot.minX + 8, y: plot.minY + 8), anchor: .topLeading)
            ctx.draw(Text("ENERGISING AND\nMEANINGFUL").font(q).foregroundStyle(Palette.brand), at: CGPoint(x: plot.maxX - 8, y: plot.minY + 8), anchor: .topTrailing)
            ctx.draw(Text("DRIFT").font(q).foregroundStyle(Palette.ink3), at: CGPoint(x: plot.minX + 8, y: plot.maxY - 6), anchor: .bottomLeading)
            ctx.draw(Text("LIGHT").font(q).foregroundStyle(Palette.ink3), at: CGPoint(x: plot.maxX - 8, y: plot.maxY - 6), anchor: .bottomTrailing)
            ctx.draw(Text("drains you  ←  energy  →  fills you").font(.system(size: 11)).foregroundStyle(Palette.ink2),
                     at: CGPoint(x: plot.midX, y: size.height - 4), anchor: .bottom)

            var stacked: [String: Int] = [:]
            for a in named {
                let e = min(2, max(-2, a.energy)), m = min(5, max(1, a.meaning))
                let key = "\(e):\(m)"
                let k = stacked[key, default: 0]
                stacked[key] = k + 1
                let p = CGPoint(x: x(e), y: y(m) + CGFloat(k) * 15)
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - 5, y: p.y - 5, width: 10, height: 10)), with: .color(Palette.brandFill))
                let name = a.name.trimmed.count > 18 ? String(a.name.trimmed.prefix(17)) + "…" : a.name.trimmed
                let right = p.x < plot.maxX - 110
                ctx.draw(Text(name).font(.system(size: 11)).foregroundStyle(Palette.ink),
                         at: CGPoint(x: right ? p.x + 9 : p.x - 9, y: p.y), anchor: right ? .leading : .trailing)
            }
        }
        .frame(height: 300)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Energy map of \(named.count) activities")
        .accessibilityValue(named.map { "\($0.name): energy \($0.energy), meaning \($0.meaning)" }.joined(separator: "; "))
    }
}
