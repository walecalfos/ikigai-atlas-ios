import Foundation

public extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    var hasText: Bool { !trimmed.isEmpty }

    var droppingTrailingPeriod: String { hasSuffix(".") ? String(dropLast()) : self }

    /// Lowercased key for de-duplication: letters, digits and single spaces only.
    var normalizedKey: String {
        var out = ""
        var lastWasSpace = false
        for scalar in trimmed.lowercased().unicodeScalars {
            if TextTools.isWordScalar(scalar) || (scalar.value >= 48 && scalar.value <= 57) {
                out.unicodeScalars.append(scalar)
                lastWasSpace = false
            } else if scalar == " " {
                if !lastWasSpace { out.append(" ") }
                lastWasSpace = true
            }
        }
        return out
    }
}

public enum TextTools {
    /// a–z plus the Latin-1 accented range à–ÿ.
    static func isWordScalar(_ s: Unicode.Scalar) -> Bool {
        (s.value >= 97 && s.value <= 122) || (s.value >= 0xE0 && s.value <= 0xFF)
    }

    /// “A”, “B” and “C”, or “A”, “B”, “C” and 2 more.
    public static func quoteList(_ items: [String], max: Int = 3) -> String {
        let names = items.prefix(max).map { "“" + $0.trimmed + "”" }
        let more = items.count > max ? " and \(items.count - max) more" : ""
        if names.count <= 1 { return names.joined() + more }
        if !more.isEmpty { return names.joined(separator: ", ") + more }
        return names.dropLast().joined(separator: ", ") + " and " + names[names.count - 1]
    }

    /// A, B and C.
    public static func plainList(_ items: [String]) -> String {
        if items.count <= 1 { return items.joined() }
        return items.dropLast().joined(separator: ", ") + " and " + items[items.count - 1]
    }

    /// Splits free text like “my niece, the lake and teaching” into short phrases.
    public static func splitList(_ text: String) -> [String] {
        let source = text.trimmed
        guard !source.isEmpty,
              let regex = try? NSRegularExpression(pattern: ",|;|\\n|\\s+and\\s+|\\.\\s", options: [.caseInsensitive]) else { return [] }
        let ns = source as NSString
        var pieces: [String] = []
        var cursor = 0
        for match in regex.matches(in: source, range: NSRange(location: 0, length: ns.length)) {
            pieces.append(ns.substring(with: NSRange(location: cursor, length: match.range.location - cursor)))
            cursor = match.range.location + match.range.length
        }
        pieces.append(ns.substring(from: cursor))
        return pieces
            .map { $0.trimmed.droppingTrailingPeriod }
            .filter { $0.count >= 3 && $0.count <= 60 }
    }

    /// Lowercase words of three or more letters, apostrophes removed.
    static func words(in text: String) -> [String] {
        var words: [String] = []
        var current = ""
        for scalar in text.lowercased().unicodeScalars {
            if scalar == "’" || scalar == "'" { continue }
            if isWordScalar(scalar) {
                current.unicodeScalars.append(scalar)
            } else if !current.isEmpty {
                words.append(current)
                current = ""
            }
        }
        if !current.isEmpty { words.append(current) }
        return words
    }

    /// A light English stemmer, enough to group “teach”, “teaches” and “teaching”.
    static func stem(_ w: String) -> String {
        let n = w.count
        if n > 5 && w.hasSuffix("ing") { return String(w.dropLast(3)) }
        if n > 4 && w.hasSuffix("ies") { return String(w.dropLast(3)) + "y" }
        if n > 4 && (w.hasSuffix("shes") || w.hasSuffix("ches") || w.hasSuffix("xes") || w.hasSuffix("sses")) { return String(w.dropLast(2)) }
        if n > 3 && w.hasSuffix("s") && !(w.hasSuffix("ss") || w.hasSuffix("us") || w.hasSuffix("is")) { return String(w.dropLast()) }
        return w
    }

    static let stopWords: Set<String> = Set("a about above after again against all almost also always am an and any anyone anything are around as at away back be because been before being below between big bit both but by came can cant come could couldnt day days did didnt do does doesnt doing done dont down during each else even ever every everyone everything feel feeling felt few first for from full get gets getting give gave go goes going gone good got great had has have having he her here him his how i id if ill im in into is isnt it its ive just keep kept kind know knew last least less let lets like little lot lots made make makes many may me might more most much must my myself need needed never new no none not nothing now of off often old on once one only or other others our out over own part people pretty put quite rather really right said same saw say see seen she should since so some someone something sometimes sort still such take than that thats the their them then there theres these they thing things think this those though thought three through time times to too took two under until up us use used usually very want wanted was wasnt way ways we week weeks well went were what when where which while who whole why will with without would year years yes yet you your youre yourself completely whenever".split(separator: " ").map(String.init))
}
