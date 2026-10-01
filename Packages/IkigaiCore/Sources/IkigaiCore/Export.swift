import Foundation

public extension Atlas {
    /// The whole atlas as Markdown, for notes, documents or email.
    func markdown(date: Date = Date(), locale: Locale = .current) -> String {
        let longDate = Date.FormatStyle(date: .long, time: .omitted).locale(locale)
        var lines: [String] = []
        let who = name.trimmed
        let cov = needCoverage()
        let srcs = liveSources

        lines += ["# Ikigai Atlas" + (who.isEmpty ? "" : " of \(who)"), "", date.formatted(longDate), ""]
        if statement.hasText {
            lines += ["## My ikigai, in a sentence", "", "> " + statement.trimmed, ""]
        }
        if pulse.overall != nil || !ratedNeeds.isEmpty {
            lines += ["## Pulse (ikigai-kan)", ""]
            if let overall = pulse.overall { lines += ["How worth living life feels: **\(overall)/10**", ""] }
            for need in Need.allCases {
                let fed = cov[need]?.count ?? 0
                let rating = pulse[need].map { "\($0)/5" } ?? "not rated"
                lines.append("- \(need.name): \(rating), fed by \(fed) source\(fed == 1 ? "" : "s")")
            }
            lines.append("")
        }
        if !srcs.isEmpty {
            lines += ["## Sources of ikigai", ""]
            let groups: [(String, [Source])] = Domain.allCases.map { d in (d.name, srcs.filter { $0.domain == d }) }
                + [("Not placed yet", srcs.filter { $0.domain == nil })]
            for (title, items) in groups where !items.isEmpty {
                lines.append("### \(title)")
                for s in items {
                    var bits = ["strength \(s.strength)/5", s.authStatus.name.lowercased()]
                    if let mode = s.mode { bits.append(mode.name.lowercased()) }
                    bits.append(s.time.rawValue)
                    if !s.needs.isEmpty { bits.append("feeds " + s.needs.map { $0.name.lowercased() }.joined(separator: ", ")) }
                    lines.append("- **\(s.text.trimmed)** (\(bits.joined(separator: " · ")))")
                }
                lines.append("")
            }
        }
        if !namedThreads.isEmpty {
            lines += ["## Threads", ""]
            for t in namedThreads { lines.append("- **\(t.name.trimmed)**" + (t.note.hasText ? ": \(t.note.trimmed)" : "")) }
            lines.append("")
        }
        let found = insights()
        if !found.isEmpty {
            lines += ["## What my atlas shows", ""]
            for i in found { lines.append("- **\(i.title).** \(i.body)") }
            lines.append("")
        }
        if !joys.isEmpty {
            lines += ["## Small joys", ""] + joys.map { "- " + $0 } + [""]
        }
        if !namedActivities.isEmpty {
            lines += ["## Energy audit", "", "| Activity | Energy (−2 to +2) | Meaning (1 to 5) |", "|---|---|---|"]
            for a in namedActivities {
                lines.append("| \(a.name.trimmed.replacingOccurrences(of: "|", with: "/")) | \(a.energy > 0 ? "+\(a.energy)" : "\(a.energy)") | \(a.meaning) |")
            }
            lines.append("")
        }
        let filledMoments = moments.filter { $0.title.hasText || $0.what.hasText || $0.why.hasText }
        if !filledMoments.isEmpty {
            lines += ["## Moments when life felt most worth living", ""]
            for m in filledMoments {
                lines.append("### " + (m.title.hasText ? m.title.trimmed : "A moment"))
                if m.what.hasText { lines.append(m.what.trimmed) }
                if m.who.hasText { lines += ["", "With: " + m.who.trimmed] }
                if m.why.hasText { lines += ["", "Why it mattered: " + m.why.trimmed] }
                if !m.needs.isEmpty { lines += ["", "Needs fed: " + m.needs.map(\.name).joined(separator: ", ")] }
                lines.append("")
            }
        }
        let prompts: [(String, String)] = [
            (childhood, "As a child I could spend hours"),
            (anchor, "What kept me going in hard times"),
            (missing, "What I would miss most"),
            (flow, "When I lose track of time"),
            (seekYouFor, "What people come to me for"),
            (others, "What others said")
        ]
        for (text, label) in prompts where text.hasText { lines += ["**\(label):** \(text.trimmed)", ""] }
        if !namedLens.isEmpty {
            lines += ["## Work lens", ""]
            for l in namedLens {
                let circles = [l.love ? "love" : nil, l.good ? "good at" : nil, l.needed ? "needed" : nil, l.paid ? "paid" : nil].compactMap { $0 }
                lines.append("- \(l.text.trimmed): \(l.label) (\(circles.isEmpty ? "no circles" : circles.joined(separator: ", ")))")
            }
            lines.append("")
        }
        if !namedExperiments.isEmpty {
            lines += ["## Experiments", ""]
            for e in namedExperiments {
                let box = e.status == .planned ? "[ ]" : "[x]"
                let when = e.when.hasText ? " (\(e.when.trimmed))" : ""
                let need = e.need.map { ", feeds " + $0.name.lowercased() } ?? ""
                lines.append("- \(box) \(e.text.trimmed)\(when)\(need)")
            }
            lines.append("")
        }
        if rhythm.morning.hasText || rhythm.evening.hasText || rhythm.review != nil {
            lines += ["## Rhythm", ""]
            if rhythm.morning.hasText { lines.append("- Morning: " + rhythm.morning.trimmed) }
            if rhythm.evening.hasText { lines.append("- Evening: " + rhythm.evening.trimmed) }
            if let review = rhythm.review { lines.append("- Retake the pulse on: " + review.formatted(longDate)) }
            lines.append("")
        }
        if let r = reading, !r.pattern.isEmpty || !r.question.isEmpty {
            lines += ["## Pattern reading", ""]
            if !r.pattern.isEmpty { lines += [r.pattern, ""] }
            if !r.tension.isEmpty { lines += [r.tension, ""] }
            if !r.question.isEmpty { lines += ["*" + r.question + "*", ""] }
        }
        lines += ["---", "Made with Ikigai Atlas, a framework built on the work of Mieko Kamiya, Gordon Mathews, Ken Mogi and Akihiro Hasegawa."]
        return lines.joined(separator: "\n")
    }

    /// A compact plain-text digest of the atlas for an on-device language model,
    /// trimmed to fit a small context window.
    func readingDigest(maxCharacters: Int = 5_000) -> String {
        func cut(_ s: String, _ n: Int = 240) -> String {
            let t = s.trimmed.replacingOccurrences(of: "\n", with: " ")
            return t.count > n ? String(t.prefix(n)) + "…" : t
        }
        var parts: [String] = []
        if let overall = pulse.overall { parts.append("Life feels worth living: \(overall)/10.") }
        if !ratedNeeds.isEmpty {
            parts.append("Needs (1-5): " + ratedNeeds.map { "\($0.rawValue) \(pulse[$0]!)" }.joined(separator: ", ") + ".")
        }
        for m in moments where m.what.hasText || m.why.hasText || m.title.hasText {
            parts.append("Alive moment: \(cut(m.title, 80)). \(cut(m.what)) Why it mattered: \(cut(m.why))")
        }
        if childhood.hasText { parts.append("As a child, absorbed by: \(cut(childhood))") }
        if anchor.hasText { parts.append("Kept them going in hard times: \(cut(anchor))") }
        if missing.hasText { parts.append("Would miss most: \(cut(missing))") }
        if !joys.isEmpty { parts.append("Small joys: " + joys.prefix(15).map { cut($0, 60) }.joined(separator: "; ") + ".") }
        let acts = namedActivities
        if !acts.isEmpty {
            parts.append("Week (energy -2..+2, meaning 1-5): " + acts.prefix(12).map { "\(cut($0.name, 40)) \($0.energy > 0 ? "+" : "")\($0.energy)/\($0.meaning)" }.joined(separator: "; ") + ".")
        }
        if flow.hasText { parts.append("Flow: \(cut(flow))") }
        if seekYouFor.hasText { parts.append("People come to them for: \(cut(seekYouFor))") }
        if others.hasText { parts.append("What others said: \(cut(others))") }
        let srcs = liveSources
        if !srcs.isEmpty {
            parts.append("Sources of ikigai: " + srcs.prefix(14).map { s in
                "\(cut(s.text, 60)) [\(s.domain?.name ?? "unplaced"), strength \(s.strength), \(s.authStatus.name.lowercased())]"
            }.joined(separator: "; ") + ".")
        }
        if !namedThreads.isEmpty { parts.append("Threads they named: " + namedThreads.map { cut($0.name, 60) }.joined(separator: "; ") + ".") }
        if statement.hasText { parts.append("Draft statement: \(cut(statement, 300))") }

        var out = ""
        for p in parts {
            if out.count + p.count + 1 > maxCharacters { break }
            out += (out.isEmpty ? "" : "\n") + p
        }
        return out
    }

    /// Whether there is enough material for a pattern reading to say anything useful.
    var hasEnoughForReading: Bool { answerCorpus.count >= 4 }
}
