import Foundation

// Every model decodes missing keys to sensible defaults, so atlases saved by older
// versions of the app keep opening after the schema grows.

private extension KeyedDecodingContainer {
    func value<T: Decodable>(_ key: Key, _ fallback: @autoclosure () -> T) -> T {
        if let decoded = try? decodeIfPresent(T.self, forKey: key) { return decoded }
        return fallback()
    }

    func optional<T: Decodable>(_ key: Key, as type: T.Type = T.self) -> T? {
        if let decoded = try? decodeIfPresent(T.self, forKey: key) { return decoded }
        return nil
    }
}

public func newID() -> String { UUID().uuidString }

// MARK: - Pulse

public struct Pulse: Codable, Equatable, Hashable, Sendable {
    /// 0 to 10: how worth living life feels these days.
    public var overall: Int?
    /// 1 to 5 per need, keyed by `Need.rawValue`.
    public var needs: [String: Int]

    public init(overall: Int? = nil, needs: [String: Int] = [:]) {
        self.overall = overall
        self.needs = needs
    }

    public subscript(need: Need) -> Int? {
        get { needs[need.rawValue] }
        set { needs[need.rawValue] = newValue }
    }

    enum CodingKeys: String, CodingKey { case overall, needs }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        overall = c.optional(.overall, as: Int.self)
        needs = c.value(.needs, [:])
    }
}

public struct PulseSnapshot: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    public var date: Date
    public var overall: Int?
    public var needs: [String: Int]

    public init(id: String = newID(), date: Date, overall: Int?, needs: [String: Int]) {
        self.id = id
        self.date = date
        self.overall = overall
        self.needs = needs
    }

    public var needsAverage: Double? {
        let values = Need.allCases.compactMap { needs[$0.rawValue] }
        guard !values.isEmpty else { return nil }
        return Double(values.reduce(0, +)) / Double(values.count)
    }

    public var hungriest: Need? {
        let rated = Need.allCases.filter { needs[$0.rawValue] != nil }
        guard var low = rated.first else { return nil }
        for n in rated where needs[n.rawValue]! < needs[low.rawValue]! { low = n }
        return low
    }
}

// MARK: - Stage 2

public struct Moment: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var what: String
    public var who: String
    public var why: String
    public var needs: [Need]

    public init(id: String = newID(), title: String = "", what: String = "", who: String = "", why: String = "", needs: [Need] = []) {
        self.id = id
        self.title = title
        self.what = what
        self.who = who
        self.why = why
        self.needs = needs
    }

    enum CodingKeys: String, CodingKey { case id, title, what, who, why, needs }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.value(.id, newID())
        title = c.value(.title, "")
        what = c.value(.what, "")
        who = c.value(.who, "")
        why = c.value(.why, "")
        needs = c.value(.needs, [])
    }
}

// MARK: - Stage 3

public struct Activity: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    public var name: String
    /// -2 (drains a lot) to +2 (fills a lot).
    public var energy: Int
    /// 1 to 5.
    public var meaning: Int

    public init(id: String = newID(), name: String, energy: Int = 0, meaning: Int = 3) {
        self.id = id
        self.name = name
        self.energy = energy
        self.meaning = meaning
    }

    enum CodingKeys: String, CodingKey { case id, name, energy, meaning }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.value(.id, newID())
        name = c.value(.name, "")
        energy = min(2, max(-2, c.value(.energy, 0)))
        meaning = min(5, max(1, c.value(.meaning, 3)))
    }
}

// MARK: - Stage 4

public struct Authenticity: Codable, Equatable, Hashable, Sendable {
    public var free: Answer?
    public var mine: Answer?
    public var alive: Answer?

    public init(free: Answer? = nil, mine: Answer? = nil, alive: Answer? = nil) {
        self.free = free
        self.mine = mine
        self.alive = alive
    }

    public subscript(test: AuthenticityTest) -> Answer? {
        get {
            switch test {
            case .free: return free
            case .mine: return mine
            case .alive: return alive
            }
        }
        set {
            switch test {
            case .free: free = newValue
            case .mine: mine = newValue
            case .alive: alive = newValue
            }
        }
    }
}

public struct Source: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    public var text: String
    public var domain: Domain?
    /// 1 to 5: how much worth it gives life.
    public var strength: Int
    public var needs: [Need]
    public var mode: Mode?
    public var time: TimeTag
    public var auth: Authenticity

    public init(id: String = newID(), text: String, domain: Domain? = nil, strength: Int = 3, needs: [Need] = [], mode: Mode? = nil, time: TimeTag = .present, auth: Authenticity = Authenticity()) {
        self.id = id
        self.text = text
        self.domain = domain
        self.strength = strength
        self.needs = needs
        self.mode = mode
        self.time = time
        self.auth = auth
    }

    enum CodingKeys: String, CodingKey { case id, text, domain, strength, needs, mode, time, auth }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.value(.id, newID())
        text = c.value(.text, "")
        domain = c.optional(.domain, as: Domain.self)
        strength = min(5, max(1, c.value(.strength, 3)))
        needs = c.value(.needs, [])
        mode = c.optional(.mode, as: Mode.self)
        time = c.value(.time, .present)
        auth = c.value(.auth, Authenticity())
    }

    /// Core, growing, borrowed or untested, from Kamiya's three tests.
    public var authStatus: AuthStatus {
        if auth.mine == .no { return .borrowed }
        guard let free = auth.free, let mine = auth.mine, let alive = auth.alive else { return .untested }
        if free == .yes && mine == .yes && alive == .yes { return .core }
        if free == .no && alive == .no { return .borrowed }
        return .growing
    }
}

// MARK: - Stage 5

public struct AtlasThread: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var note: String

    public init(id: String = newID(), name: String = "", note: String = "") {
        self.id = id
        self.name = name
        self.note = note
    }

    enum CodingKeys: String, CodingKey { case id, name, note }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.value(.id, newID())
        name = c.value(.name, "")
        note = c.value(.note, "")
    }
}

public struct StatementParts: Codable, Equatable, Hashable, Sendable {
    public var doing: String
    public var whom: String
    public var how: String

    public init(doing: String = "", whom: String = "", how: String = "") {
        self.doing = doing
        self.whom = whom
        self.how = how
    }

    enum CodingKeys: String, CodingKey { case doing, whom, how }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        doing = c.value(.doing, "")
        whom = c.value(.whom, "")
        how = c.value(.how, "")
    }

    /// "Life feels most worth living when I …", or nil until the first part is filled in.
    public var sentence: String? {
        guard doing.hasText else { return nil }
        var s = "Life feels most worth living when I " + doing.trimmed.droppingTrailingPeriod
        if whom.hasText { s += " " + whom.trimmed.droppingTrailingPeriod }
        if how.hasText { s += ", especially " + how.trimmed.droppingTrailingPeriod }
        return s + "."
    }
}

/// One row in the optional four-circle work lens (the Zuzunaga/Winn diagram).
public struct LensItem: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    public var text: String
    public var love: Bool
    public var good: Bool
    public var needed: Bool
    public var paid: Bool

    public init(id: String = newID(), text: String, love: Bool = false, good: Bool = false, needed: Bool = false, paid: Bool = false) {
        self.id = id
        self.text = text
        self.love = love
        self.good = good
        self.needed = needed
        self.paid = paid
    }

    enum CodingKeys: String, CodingKey { case id, text, love, good, needed, paid }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.value(.id, newID())
        text = c.value(.text, "")
        love = c.value(.love, false)
        good = c.value(.good, false)
        needed = c.value(.needed, false)
        paid = c.value(.paid, false)
    }

    public var circleCount: Int { [love, good, needed, paid].filter { $0 }.count }

    /// The name the four-circle diagram gives this overlap.
    public var label: String {
        switch (love, good, needed, paid) {
        case (true, true, true, true): return "All four circles"
        case (false, true, true, true): return "Comfortable, but may feel empty"
        case (true, false, true, true): return "Exciting, but uncertain"
        case (true, true, false, true): return "Satisfying, but may feel useless"
        case (true, true, true, false): return "Delightful, but not paid"
        case (true, true, false, false): return "Passion"
        case (true, false, true, false): return "Mission"
        case (false, false, true, true): return "Vocation"
        case (false, true, false, true): return "Profession"
        case (true, false, false, true): return "Love and reward"
        case (false, true, true, false): return "Skill and need"
        case (true, false, false, false): return "Love only"
        case (false, true, false, false): return "Skill only"
        case (false, false, true, false): return "Need only"
        case (false, false, false, true): return "Reward only"
        case (false, false, false, false): return "Not sorted yet"
        }
    }
}

// MARK: - Stage 6

public struct Experiment: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    public var text: String
    public var need: Need?
    public var when: String
    public var status: ExperimentStatus

    public init(id: String = newID(), text: String = "", need: Need? = nil, when: String = "", status: ExperimentStatus = .planned) {
        self.id = id
        self.text = text
        self.need = need
        self.when = when
        self.status = status
    }

    enum CodingKeys: String, CodingKey { case id, text, need, when, status }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.value(.id, newID())
        text = c.value(.text, "")
        need = c.optional(.need, as: Need.self)
        when = c.value(.when, "")
        status = c.value(.status, .planned)
    }
}

public struct Rhythm: Codable, Equatable, Hashable, Sendable {
    public var morning: String
    public var evening: String
    /// When to retake the pulse.
    public var review: Date?

    public init(morning: String = "", evening: String = "", review: Date? = nil) {
        self.morning = morning
        self.evening = evening
        self.review = review
    }

    enum CodingKeys: String, CodingKey { case morning, evening, review }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        morning = c.value(.morning, "")
        evening = c.value(.evening, "")
        review = c.optional(.review, as: Date.self)
    }
}

// MARK: - Optional AI reading

public struct Reading: Codable, Equatable, Hashable, Sendable {
    public struct ThreadSuggestion: Codable, Equatable, Hashable, Identifiable, Sendable {
        public var id: String { name }
        public var name: String
        public var why: String
        public var evidence: [String]
        public init(name: String, why: String, evidence: [String]) {
            self.name = name
            self.why = why
            self.evidence = evidence
        }
    }

    public struct ExperimentSuggestion: Codable, Equatable, Hashable, Identifiable, Sendable {
        public var id: String { text }
        public var text: String
        public var need: Need?
        public init(text: String, need: Need?) {
            self.text = text
            self.need = need
        }
    }

    public var createdAt: Date
    public var threads: [ThreadSuggestion]
    public var pattern: String
    public var tension: String
    public var statements: [String]
    public var experiments: [ExperimentSuggestion]
    public var question: String

    public init(createdAt: Date = Date(), threads: [ThreadSuggestion] = [], pattern: String = "", tension: String = "", statements: [String] = [], experiments: [ExperimentSuggestion] = [], question: String = "") {
        self.createdAt = createdAt
        self.threads = threads
        self.pattern = pattern
        self.tension = tension
        self.statements = statements
        self.experiments = experiments
        self.question = question
    }

    public var isEmpty: Bool { pattern.isEmpty && question.isEmpty && threads.isEmpty && statements.isEmpty }
}

// MARK: - The atlas

public struct Atlas: Codable, Equatable, Hashable, Sendable {
    public static let schemaVersion = 1

    public var version: Int
    public var name: String
    public var createdAt: Date
    /// nil until the person first changes something.
    public var updatedAt: Date?
    public var lastStage: Stage?

    public var pulse: Pulse
    public var pulseHistory: [PulseSnapshot]

    public var moments: [Moment]
    public var childhood: String
    public var anchor: String
    public var missing: String

    public var joys: [String]
    public var activities: [Activity]
    public var flow: String
    public var seekYouFor: String
    public var others: String

    public var sources: [Source]

    public var threads: [AtlasThread]
    public var statement: String
    public var parts: StatementParts
    public var lens: [LensItem]

    public var experiments: [Experiment]
    public var rhythm: Rhythm

    public var reading: Reading?

    public init() {
        version = Atlas.schemaVersion
        name = ""
        createdAt = Date()
        updatedAt = nil
        lastStage = nil
        pulse = Pulse()
        pulseHistory = []
        moments = [Moment(), Moment(), Moment()]
        childhood = ""
        anchor = ""
        missing = ""
        joys = []
        activities = []
        flow = ""
        seekYouFor = ""
        others = ""
        sources = []
        threads = []
        statement = ""
        parts = StatementParts()
        lens = []
        experiments = []
        rhythm = Rhythm()
        reading = nil
    }

    enum CodingKeys: String, CodingKey {
        case version, name, createdAt, updatedAt, lastStage, pulse, pulseHistory, moments, childhood, anchor, missing
        case joys, activities, flow, seekYouFor, others, sources, threads, statement, parts, lens, experiments, rhythm, reading
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = c.value(.version, Atlas.schemaVersion)
        name = c.value(.name, "")
        createdAt = c.value(.createdAt, Date())
        updatedAt = c.optional(.updatedAt, as: Date.self)
        lastStage = c.optional(.lastStage, as: Stage.self)
        pulse = c.value(.pulse, Pulse())
        pulseHistory = c.value(.pulseHistory, [])
        let decodedMoments: [Moment] = c.value(.moments, [])
        moments = decodedMoments.isEmpty ? [Moment()] : decodedMoments
        childhood = c.value(.childhood, "")
        anchor = c.value(.anchor, "")
        missing = c.value(.missing, "")
        joys = c.value(.joys, [])
        activities = c.value(.activities, [])
        flow = c.value(.flow, "")
        seekYouFor = c.value(.seekYouFor, "")
        others = c.value(.others, "")
        sources = c.value(.sources, [])
        threads = c.value(.threads, [])
        statement = c.value(.statement, "")
        parts = c.value(.parts, StatementParts())
        lens = c.value(.lens, [])
        experiments = c.value(.experiments, [])
        rhythm = c.value(.rhythm, Rhythm())
        reading = c.optional(.reading, as: Reading.self)
    }

    public var hasStarted: Bool { updatedAt != nil }
}

// MARK: - Encoding

public extension Atlas {
    static func encoder() -> JSONEncoder {
        // Dates use the default numeric encoding, which round-trips exactly.
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        return e
    }

    static func decoder() -> JSONDecoder {
        JSONDecoder()
    }

    func encoded() throws -> Data { try Atlas.encoder().encode(self) }

    static func decode(_ data: Data) throws -> Atlas { try Atlas.decoder().decode(Atlas.self, from: data) }
}
