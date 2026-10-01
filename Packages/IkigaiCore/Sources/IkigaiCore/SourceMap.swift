import Foundation

/// Geometry for the radial source map: eight areas of life as wedges, strength as distance
/// from the centre (strongest nearest), with overlapping dots nudged apart.
/// Coordinates are in a 520 × 520 space centred on (260, 260). The outer band, from
/// `labelBandInner` to `outerRadius`, is kept clear for the area names.
public enum SourceMap {
    public static let size: Double = 520
    public static let center: Double = 260
    public static let innerRadius: Double = 26
    public static let outerRadius: Double = 236
    public static let dotRadius: Double = 11.5
    public static let labelBandInner: Double = 204
    public static let labelRadius: Double = 220

    public struct Dot: Identifiable, Hashable, Sendable {
        public let id: String
        public let number: Int
        public let text: String
        public let status: AuthStatus
        public let x: Double
        public let y: Double
    }

    /// Ring radius for a strength from 1 to 5. Strength 5 sits nearest the centre.
    public static func radius(forStrength strength: Int) -> Double {
        56 + Double(5 - min(5, max(1, strength))) * 33
    }

    /// Centre angle of an area's wedge, in degrees, starting at the top and running clockwise.
    public static func angle(for domain: Domain) -> Double {
        -90 + Double(Domain.allCases.firstIndex(of: domain) ?? 0) * 45
    }

    public static func point(radius: Double, degrees: Double) -> (x: Double, y: Double) {
        let a = degrees * .pi / 180
        return (center + radius * cos(a), center + radius * sin(a))
    }

    /// Numbers follow the order of `sources`; sources without an area are left off the map.
    public static func layout(_ sources: [Source]) -> [Dot] {
        struct Placed { var x: Double; var y: Double; let r0: Double; let lo: Double; let hi: Double; let source: Source; let number: Int }
        let numbers = Dictionary(sources.enumerated().map { ($0.element.id, $0.offset + 1) }, uniquingKeysWith: { first, _ in first })
        var placed: [Placed] = []
        for domain in Domain.allCases {
            let inDomain = sources.filter { $0.domain == domain }
            let ordered = inDomain.enumerated().sorted { a, b in
                a.element.strength != b.element.strength ? a.element.strength > b.element.strength : a.offset < b.offset
            }.map(\.element)
            let c = angle(for: domain)
            let n = Double(ordered.count)
            for (j, s) in ordered.enumerated() {
                let a = c - 22.5 + Double(j + 1) * 45 / (n + 1)
                let r = radius(forStrength: s.strength)
                let p = point(radius: r, degrees: a)
                placed.append(Placed(x: p.x, y: p.y, r0: r, lo: c - 19, hi: c + 19, source: s, number: numbers[s.id] ?? 0))
            }
        }
        let minGap = 25.0
        for _ in 0..<60 {
            if placed.count > 1 {
                for a in 0..<(placed.count - 1) {
                    for b in (a + 1)..<placed.count {
                        let dx = placed[b].x - placed[a].x, dy = placed[b].y - placed[a].y
                        let dist = max(0.01, (dx * dx + dy * dy).squareRoot())
                        if dist < minGap {
                            let push = (minGap - dist) / 2, ux = dx / dist, uy = dy / dist
                            placed[a].x -= ux * push; placed[a].y -= uy * push
                            placed[b].x += ux * push; placed[b].y += uy * push
                        }
                    }
                }
            }
            for i in placed.indices {
                let dx = placed[i].x - center, dy = placed[i].y - center
                var r = (dx * dx + dy * dy).squareRoot()
                var ang = atan2(dy, dx) * 180 / .pi
                while ang < placed[i].lo - 180 { ang += 360 }
                while ang > placed[i].hi + 180 { ang -= 360 }
                r = max(placed[i].r0 - 14, min(placed[i].r0 + 14, r))
                ang = max(placed[i].lo, min(placed[i].hi, ang))
                let p = point(radius: r, degrees: ang)
                placed[i].x = p.x
                placed[i].y = p.y
            }
        }
        return placed.map { Dot(id: $0.source.id, number: $0.number, text: $0.source.text, status: $0.source.authStatus, x: $0.x, y: $0.y) }
    }
}
