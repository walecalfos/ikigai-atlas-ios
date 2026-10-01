import Foundation

// MARK: - Results

public struct Insight: Identifiable, Hashable, Sendable {
    public enum Tone: Int, Comparable, Sendable {
        case hungry = 0, good = 1, note = 2
        public static func < (a: Tone, b: Tone) -> Bool { a.rawValue < b.rawValue }
    }

    public var id: String { title }
    public let tone: Tone
    public let title: String
    public let body: String

    public init(tone: Tone, title: String, body: String) {
        self.tone = tone
        self.title = title
        self.body = body
    }
}

public struct RecurringWord: Identifiable, Hashable, Sendable {
    public var id: String { word }
    /// The most common spelling of the word.
    public let word: String
    /// How many separate answers it appears in.
    public let answers: Int
}

public struct SourceSuggestion: Identifiable, Hashable, Sendable {
    public var id: String { text }
    public let text: String
    public let origin: String
}

// MARK: - Progress

public extension Atlas {
    func isComplete(_ stage: Stage) -> Bool {
        switch stage {
        case .pulse:
            return pulse.overall != nil && Need.allCases.allSatisfy { pulse[$0] != nil }
        case .remember:
            return moments.contains { $0.what.hasText || $0.why.hasText }
        case .notice:
            return joys.count >= 3 || activities.filter { $0.name.hasText }.count >= 3
        case .gather:
            return liveSources.count >= 3
        case .weave:
            return statement.hasText || threads.contains { $0.name.hasText }
        case .live:
            return experiments.contains { $0.text.hasText }
        }
    }

    var completedStageCount: Int { Stage.allCases.filter { isComplete($0) }.count }

    /// The first stage still to do, or nil when all six are complete.
    var firstIncompleteStage: Stage? { Stage.allCases.first { !isComplete($0) } }

    var liveSources: [Source] { sources.filter { $0.text.hasText } }
    var namedActivities: [Activity] { activities.filter { $0.name.hasText } }
    var namedThreads: [AtlasThread] { threads.filter { $0.name.hasText } }
    var namedLens: [LensItem] { lens.filter { $0.text.hasText } }
    var namedExperiments: [Experiment] { experiments.filter { $0.text.hasText } }
}

// MARK: - Pulse and coverage

public extension Atlas {
    var ratedNeeds: [Need] { Need.allCases.filter { pulse[$0] != nil } }

    var pulseAverage: Double? {
        let values = ratedNeeds.compactMap { pulse[$0] }
        guard !values.isEmpty else { return nil }
        return Double(values.reduce(0, +)) / Double(values.count)
    }

    /// Up to three needs rated 3 or lower, hungriest first.
    func hungryNeeds(limit: Int = 3) -> [Need] {
        let candidates = ratedNeeds.filter { (pulse[$0] ?? 5) <= 3 }
        return Array(stableSorted(candidates) { (pulse[$0] ?? 0) < (pulse[$1] ?? 0) }.prefix(limit))
    }

    /// Which sources feed each need.
    func needCoverage() -> [Need: [Source]] {
        var out: [Need: [Source]] = [:]
        for need in Need.allCases { out[need] = [] }
        for source in liveSources {
            for need in source.needs { out[need, default: []].append(source) }
        }
        return out
    }

    /// Total strength per area, in the order areas first appear among the sources.
    func domainWeights() -> (weights: [(Domain, Int)], total: Int) {
        var order: [Domain] = []
        var sums: [Domain: Int] = [:]
        var total = 0
        for source in liveSources {
            guard let domain = source.domain else { continue }
            if sums[domain] == nil { order.append(domain) }
            sums[domain, default: 0] += source.strength
            total += source.strength
        }
        return (order.map { ($0, sums[$0] ?? 0) }, total)
    }
}

public extension Atlas {
    /// Saves today's pulse into the history, replacing any snapshot from the same day.
    /// Returns false when there is nothing to save yet.
    @discardableResult
    mutating func recordPulse(on date: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard pulse.overall != nil || !ratedNeeds.isEmpty else { return false }
        pulseHistory.removeAll { calendar.isDate($0.date, inSameDayAs: date) }
        pulseHistory.append(PulseSnapshot(date: date, overall: pulse.overall, needs: pulse.needs))
        if pulseHistory.count > 24 { pulseHistory.removeFirst(pulseHistory.count - 24) }
        return true
    }
}

// MARK: - Insights

public extension Atlas {
    /// Plain-language observations drawn only from this person's own answers.
    func insights() -> [Insight] {
        var out: [Insight] = []
        let srcs = liveSources
        let cov = needCoverage()
        let rated = ratedNeeds
        let q = TextTools.quoteList
        let plain = TextTools.plainList

        if rated.count >= 4 {
            let low = stableSorted(rated.filter { pulse[$0]! <= 2 }) { pulse[$0]! < pulse[$1]! }
            for need in low {
                let fed = cov[need] ?? []
                let v = pulse[need]!
                if fed.isEmpty {
                    out.append(Insight(tone: .hungry,
                                       title: "\(need.name): hungry and unfed",
                                       body: "You rated it \(v) out of 5 and none of your sources feed it yet. This is the most useful place to experiment."))
                } else {
                    let many = fed.count > 1
                    out.append(Insight(tone: .hungry,
                                       title: "\(need.name): hungry, even though you have sources",
                                       body: "\(q(fed.map(\.text), 3)) \(many ? "feed" : "feeds") it, yet it sits at \(v) out of 5. Ask whether \(many ? "they get" : "it gets") enough of your time."))
                }
            }
            let high = rated.filter { pulse[$0]! >= 4 }
            if !high.isEmpty {
                var feeders: [Source] = []
                for need in high {
                    for s in cov[need] ?? [] where !feeders.contains(where: { $0.id == s.id }) { feeders.append(s) }
                }
                out.append(Insight(tone: .good,
                                   title: "Well fed: \(plain(high.map(\.name)))",
                                   body: feeders.isEmpty
                                       ? "You feel these strongly. Tag which sources feed them in stage 4 to see where that comes from."
                                       : "Mostly through \(q(feeders.map(\.text), 3))."))
            }
        }

        let core = srcs.filter { $0.authStatus == .core }
        if !core.isEmpty {
            let many = core.count > 1
            out.append(Insight(tone: .good,
                               title: "\(core.count) core \(many ? "sources" : "source")",
                               body: "\(q(core.map(\.text), 3)) passed all three authenticity tests. Protect time for \(many ? "them" : "it") first."))
        }
        let borrowed = srcs.filter { $0.authStatus == .borrowed }
        if !borrowed.isEmpty {
            let many = borrowed.count > 1
            out.append(Insight(tone: .note,
                               title: "\(borrowed.count) borrowed \(many ? "sources" : "source")",
                               body: "\(q(borrowed.map(\.text), 3)) did not pass the “this is mine” test. Kamiya held that ikigai cannot be borrowed or imitated. Notice whose expectations \(many ? "they serve" : "it serves")."))
        }

        let (weights, total) = domainWeights()
        if srcs.count >= 3 && total > 0 {
            let top = stableSorted(weights) { $0.1 > $1.1 }.first
            let craft = weights.first { $0.0 == .craft }?.1 ?? 0
            let craftShare = Double(craft) / Double(total)
            if craftShare >= 0.4 {
                out.append(Insight(tone: .note,
                                   title: "Work carries \(Int((craftShare * 100).rounded()))% of the weight",
                                   body: "In a 2010 survey of 2,000 Japanese adults, only 31% named work as their ikigai. Sources outside work keep your ikigai steady through job changes and retirement."))
            } else if let top, Double(top.1) / Double(total) >= 0.5 {
                out.append(Insight(tone: .note,
                                   title: "Concentrated in \(top.0.name)",
                                   body: "\(Int((Double(top.1) / Double(total) * 100).rounded()))% of your ikigai’s weight sits in one area. Ikigai shifts with life stages, so a second strong area makes it more resilient."))
            }
            let empty = Domain.allCases.filter { d in !weights.contains { $0.0 == d } }
            if empty.count >= 4 {
                out.append(Insight(tone: .note,
                                   title: "\(empty.count) areas are empty",
                                   body: "\(plain(empty.map(\.name))). Not every area needs a source. These are simply places to look if you want more."))
            }
        }

        let moded = srcs.filter { $0.mode != nil }
        if moded.count >= 3 {
            let belong = moded.filter { $0.mode == .belonging || $0.mode == .both }.count
            let becoming = moded.filter { $0.mode == .becoming || $0.mode == .both }.count
            if becoming == 0 {
                out.append(Insight(tone: .note, title: "All belonging, little becoming",
                                   body: "Every source is a role or group. Anthropologist Gordon Mathews found Japanese ikigai splits between commitment to a group (ittaikan) and self-realisation (jiko jitsugen). Add something that is only yours."))
            } else if belong == 0 {
                out.append(Insight(tone: .note, title: "All becoming, little belonging",
                                   body: "Every source is about expressing yourself. Mathews found ikigai also lives in commitment to a group or role (ittaikan). Consider where you belong, or could."))
            }
        }

        if srcs.count >= 3 {
            let past = srcs.filter { $0.time == .past }.count
            let future = srcs.filter { $0.time == .future }.count
            if Double(past) / Double(srcs.count) >= 0.5 {
                out.append(Insight(tone: .note, title: "Much of it lives in memory",
                                   body: "Psychologist Akihiro Hasegawa found remembered sources genuinely produce ikigai-kan. Still, add one source you can touch this week."))
            }
            if future == 0 {
                out.append(Insight(tone: .note, title: "Nothing yet to look toward",
                                   body: "None of your sources point ahead. A future to look toward is one of Kamiya’s seven needs. Add one thing ahead of you, however small."))
            }
        }

        let acts = namedActivities
        let zone = acts.filter { $0.energy > 0 && $0.meaning >= 4 }
        let duty = acts.filter { $0.energy < 0 && $0.meaning >= 4 }
        let drift = acts.filter { $0.energy < 0 && $0.meaning <= 2 }
        if !zone.isEmpty {
            out.append(Insight(tone: .good, title: "Energising and meaningful",
                               body: "\(q(zone.map(\.name), 3)). This is ikigai in action. Guard its place in your week."))
        }
        if !duty.isEmpty {
            let many = duty.count > 1
            out.append(Insight(tone: .note, title: "Draining but meaningful",
                               body: "\(q(duty.map(\.name), 3)) \(many ? "matter" : "matters") to you but \(many ? "cost" : "costs") energy. Look for the part you could do with more craft, or with more rest around it, before dropping anything."))
        }
        if !drift.isEmpty {
            let many = drift.count > 1
            out.append(Insight(tone: .note, title: "Drift",
                               body: "\(q(drift.map(\.name), 3)) \(many ? "drain" : "drains") you and \(many ? "give" : "gives") little back. These are the easiest hours to reclaim."))
        }
        if !joys.isEmpty && joys.count < 5 {
            out.append(Insight(tone: .note, title: "Few small joys noticed",
                               body: "Neuroscientist Ken Mogi counts the joy of little things as a pillar of ikigai. Try noting three a day for a week."))
        }

        return stableSorted(out) { $0.tone < $1.tone }
    }
}

// MARK: - Recurring words and suggestions

public extension Atlas {
    /// Every free-text answer, one entry per answer.
    var answerCorpus: [String] {
        var docs: [String] = moments.map { [$0.title, $0.what, $0.who, $0.why].joined(separator: " ") }
        docs += [childhood, anchor, missing, flow, seekYouFor, others]
        docs += joys
        docs += activities.filter { $0.energy > 0 }.map(\.name)
        docs += sources.map(\.text)
        return docs.filter { $0.hasText }
    }

    /// Words that appear in two or more separate answers.
    func recurringWords(limit: Int = 16) -> [RecurringWord] {
        var order: [String] = []
        var documentFrequency: [String: Int] = [:]
        var termFrequency: [String: Int] = [:]
        var formOrder: [String: [String]] = [:]
        var formCounts: [String: [String: Int]] = [:]

        for doc in answerCorpus {
            var seen = Set<String>()
            for word in TextTools.words(in: doc) {
                if word.count < 3 || TextTools.stopWords.contains(word) { continue }
                let stem = TextTools.stem(word)
                if TextTools.stopWords.contains(stem) || stem.count < 3 { continue }
                termFrequency[stem, default: 0] += 1
                if formCounts[stem]?[word] == nil { formOrder[stem, default: []].append(word) }
                formCounts[stem, default: [:]][word, default: 0] += 1
                if !seen.contains(stem) {
                    seen.insert(stem)
                    if documentFrequency[stem] == nil { order.append(stem) }
                    documentFrequency[stem, default: 0] += 1
                }
            }
        }

        let candidates = order.filter { (documentFrequency[$0] ?? 0) >= 2 }
        let ranked = stableSorted(candidates) { a, b in
            let da = documentFrequency[a] ?? 0, db = documentFrequency[b] ?? 0
            if da != db { return da > db }
            return (termFrequency[a] ?? 0) > (termFrequency[b] ?? 0)
        }
        return ranked.prefix(limit).map { stem in
            let forms = formOrder[stem] ?? [stem]
            let counts = formCounts[stem] ?? [:]
            let best = stableSorted(forms) { (counts[$0] ?? 0) > (counts[$1] ?? 0) }.first ?? stem
            return RecurringWord(word: best, answers: documentFrequency[stem] ?? 0)
        }
    }

    /// Candidate sources pulled from earlier answers, not yet added.
    func sourceSuggestions(limit: Int = 18) -> [SourceSuggestion] {
        var existing = Set(sources.map { $0.text.normalizedKey })
        var out: [SourceSuggestion] = []
        func push(_ raw: String, _ origin: String) {
            let text = raw.trimmed
            guard !text.isEmpty, text.count <= 70 else { return }
            let key = text.normalizedKey
            guard !key.isEmpty, !existing.contains(key) else { return }
            existing.insert(key)
            out.append(SourceSuggestion(text: text, origin: origin))
        }
        for m in moments where m.title.hasText { push(m.title, "a moment") }
        for j in joys { push(j, "a small joy") }
        for a in activities where a.name.hasText && a.energy > 0 && a.meaning >= 4 { push(a.name, "your energy audit") }
        for text in [missing, anchor, seekYouFor] {
            for piece in TextTools.splitList(text) { push(piece, "your words") }
        }
        return Array(out.prefix(limit))
    }
}

// MARK: - Helpers

/// Swift's sort is not guaranteed stable; ties must keep their original order.
func stableSorted<T>(_ items: [T], by areInIncreasingOrder: (T, T) -> Bool) -> [T] {
    items.enumerated()
        .sorted { a, b in
            if areInIncreasingOrder(a.element, b.element) { return true }
            if areInIncreasingOrder(b.element, a.element) { return false }
            return a.offset < b.offset
        }
        .map(\.element)
}
