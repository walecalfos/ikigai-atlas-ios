import Foundation

// MARK: - Kamiya's seven needs

/// The seven needs Mieko Kamiya linked to ikigai-kan, the felt sense that life is worth living.
public enum Need: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case fulfilment, growth, future, resonance, freedom, selfhood, meaning

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .fulfilment: return "Fulfilment"
        case .growth: return "Change & growth"
        case .future: return "A future to look toward"
        case .resonance: return "Resonance"
        case .freedom: return "Freedom"
        case .selfhood: return "Being myself"
        case .meaning: return "Meaning & value"
        }
    }

    public var shortName: String {
        switch self {
        case .fulfilment: return "Fulfilment"
        case .growth: return "Growth"
        case .future: return "Future"
        case .resonance: return "Resonance"
        case .freedom: return "Freedom"
        case .selfhood: return "Being myself"
        case .meaning: return "Meaning"
        }
    }

    public var japanese: String {
        switch self {
        case .fulfilment: return "充実"
        case .growth: return "成長"
        case .future: return "未来"
        case .resonance: return "反響"
        case .freedom: return "自由"
        case .selfhood: return "自己実現"
        case .meaning: return "意味"
        }
    }

    /// The statement rated 1 to 5 in the pulse.
    public var statement: String {
        switch self {
        case .fulfilment: return "Day to day, my life feels full rather than empty."
        case .growth: return "I am changing and growing. Life does not feel stuck."
        case .future: return "There is something ahead of me that I look forward to."
        case .resonance: return "People respond to me. I feel seen, needed and cared about."
        case .freedom: return "I have real room to choose how I spend my life."
        case .selfhood: return "I get to use and express what is most truly me."
        case .meaning: return "What I do matters to someone or something beyond me."
        }
    }

    /// Two small experiments per need, offered when the need is hungry.
    public var experimentIdeas: [String] {
        switch self {
        case .fulfilment: return ["Choose one routine task this week and do it slowly, with full attention, as a craft.", "Each evening for a week, write down three moments that were quietly good."]
        case .growth: return ["Spend 20 minutes on something you are a beginner at, three times this week.", "Ask someone more skilled than you for one piece of honest feedback."]
        case .future: return ["Put one thing in your calendar within the next 30 days that you will look forward to.", "Write a short letter from yourself one year from now, describing an ordinary good day."]
        case .resonance: return ["Message one person you have drifted away from and suggest a specific time to meet.", "Offer a skill of yours to someone who would value it, this week."]
        case .freedom: return ["Block a two-hour window this week that belongs to no one but you.", "Say no to one obligation that failed your “this is mine” test."]
        case .selfhood: return ["Spend an hour on the thing you did for hours as a child, in its grown-up form.", "Share something you made or wrote with one person you trust."]
        case .meaning: return ["Do one small kindness this week that no one will know came from you.", "Give two hours to a cause that connects to one of your threads."]
        }
    }
}

// MARK: - Areas of life

public enum Domain: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case people, craft, curiosity, contribution, body, senses, ritual, belief

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .people: return "People"
        case .craft: return "Craft"
        case .curiosity: return "Curiosity"
        case .contribution: return "Contribution"
        case .body: return "Body & nature"
        case .senses: return "Beauty & senses"
        case .ritual: return "Ritual"
        case .belief: return "Belief"
        }
    }

    public var hint: String {
        switch self {
        case .people: return "Family, friends, partner, pets"
        case .craft: return "Work, skills, making things well"
        case .curiosity: return "Learning, ideas, hobbies, exploring"
        case .contribution: return "Helping, community, causes"
        case .body: return "Movement, health, outdoors, seasons"
        case .senses: return "Art, music, food, small pleasures"
        case .ritual: return "Daily routines, home, the everyday"
        case .belief: return "Faith, values, spirit, legacy"
        }
    }
}

// MARK: - The six stages

public enum Stage: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case pulse, remember, notice, gather, weave, live

    public var id: String { rawValue }

    public var number: Int { (Stage.allCases.firstIndex(of: self) ?? 0) + 1 }

    public var name: String {
        switch self {
        case .pulse: return "Pulse"
        case .remember: return "Remember"
        case .notice: return "Notice"
        case .gather: return "Gather"
        case .weave: return "Weave"
        case .live: return "Live"
        }
    }

    public var question: String {
        switch self {
        case .pulse: return "How much ikigai do you feel right now?"
        case .remember: return "When has life felt most worth living?"
        case .notice: return "What gives your ordinary days their worth?"
        case .gather: return "What are your sources of ikigai?"
        case .weave: return "What threads run through it all?"
        case .live: return "How will you tend your ikigai?"
        }
    }

    public var minutes: Int {
        switch self {
        case .pulse: return 5
        case .live: return 10
        default: return 15
        }
    }

    public var lede: String {
        switch self {
        case .pulse: return "Start with where you are. This is a baseline, not a grade. Answer for how things are these days, not how you wish they were."
        case .remember: return "Your past already holds the evidence. Recall three moments, from any time in your life, when you felt most alive or most sure that life was worth living. Big or small both count."
        case .notice: return "Now look at ordinary life, the way it is this month. Ikigai is often hiding in plain sight in small things and in how your days feel."
        case .gather: return "Name the specific people, activities, places, rituals and hopes that make your life worth living. Then look closely at each one."
        case .weave: return "Step back and look for what repeats. Threads are the patterns that run through your moments, joys and sources. They describe how you come alive, whatever the setting."
        case .live: return "Ikigai is tended, not found once. Turn what you have learned into a few small experiments and a daily rhythm, then return in a few months to see what changed."
        }
    }

    /// Why the step exists, grounded in the research.
    public var why: String {
        switch self {
        case .pulse: return "Mieko Kamiya separated ikigai, the sources of worth, from ikigai-kan, the feeling that life is worth living. Her research found the feeling depends on seven needs. Rating them shows which are fed and which are hungry, and gives you a baseline to retake later."
        case .remember: return "People answer “what is my purpose?” poorly in the abstract but recall specific moments vividly, and moments carry the details that reveal patterns. Akihiro Hasegawa also found people feel ikigai-kan when remembering past sources, so memories are ikigai too, not only clues to it."
        case .notice: return "Ken Mogi counts “the joy of little things” and “being in the here and now” among the five pillars of ikigai, and Hasegawa found small daily joys add up to a fulfilling life. Kamiya noticed many people could not name their ikigai because it was woven so deeply into daily life. Noticing makes it visible."
        case .gather: return "This is Kamiya’s first meaning of ikigai: the sources themselves. Most people have several, spread across life, and a 2010 Japanese survey found only 31% named work. Her characteristics of true ikigai (done freely, deeply personal, bringing the felt sense of worth) become three quick tests that separate core sources from borrowed ones."
        case .weave: return "A single answer can mislead; a pattern across many stories rarely does. This is also where your result becomes unmistakably yours: the threads come from your words, and only you can confirm which ones are true. Kamiya’s point that ikigai is deeply individual means nobody else, human or AI, can name it for you."
        case .live: return "“Starting small” is the first of Ken Mogi’s five pillars. Small experiments are low-risk ways to test which sources really feed you. Researchers also stress that ikigai changes with age and life stage, which is why this framework ends with a date to come back."
        }
    }

    public var next: Stage? {
        let all = Stage.allCases
        guard let i = all.firstIndex(of: self), i + 1 < all.count else { return nil }
        return all[i + 1]
    }

    public var previous: Stage? {
        let all = Stage.allCases
        guard let i = all.firstIndex(of: self), i > 0 else { return nil }
        return all[i - 1]
    }
}

// MARK: - Source attributes

/// Kamiya's characteristics of true ikigai, turned into three quick tests.
public enum AuthenticityTest: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case free, mine, alive

    public var id: String { rawValue }

    public var statement: String {
        switch self {
        case .free: return "I would do this with no pay, no praise and no one watching."
        case .mine: return "This is mine, not borrowed from other people’s expectations."
        case .alive: return "It makes life feel worth living, not just busy or pleasant."
        }
    }
}

public enum Answer: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case yes, partly, no
    public var id: String { rawValue }
    public var label: String {
        switch self {
        case .yes: return "Yes"
        case .partly: return "Partly"
        case .no: return "No"
        }
    }
}

/// Gordon Mathews: ittaikan (belonging to a group or role) and jiko jitsugen (self-realisation).
public enum Mode: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case belonging, becoming, both
    public var id: String { rawValue }
    public var name: String {
        switch self {
        case .belonging: return "Belonging"
        case .becoming: return "Becoming"
        case .both: return "Both"
        }
    }
    public var hint: String {
        switch self {
        case .belonging: return "A role or group you are part of."
        case .becoming: return "Expressing who you are."
        case .both: return "A bit of each."
        }
    }
}

/// Hasegawa: ikigai can live in the past, present or future.
public enum TimeTag: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case past, present, future
    public var id: String { rawValue }
    public var name: String {
        switch self {
        case .past: return "Past"
        case .present: return "Present"
        case .future: return "Future"
        }
    }
}

public enum AuthStatus: String, CaseIterable, Hashable, Sendable {
    case core, growing, borrowed, untested
    public var name: String {
        switch self {
        case .core: return "Core"
        case .growing: return "Growing"
        case .borrowed: return "Borrowed"
        case .untested: return "Untested"
        }
    }
}

public enum ExperimentStatus: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case planned, tried, kept
    public var id: String { rawValue }
    public var name: String {
        switch self {
        case .planned: return "Planned"
        case .tried: return "Tried"
        case .kept: return "Keeping it"
        }
    }
}

public enum Framework {
    /// Common weekly activities offered as one-tap additions in the energy audit.
    public static let quickActivities = ["Work", "Commute", "Exercise", "Cooking", "Chores", "Social media", "Time with family", "Time with friends", "A hobby", "Learning"]

    public static let askOthersMessage = "Hi! I’m doing an exercise about what makes life feel worth living for me. Would you answer three quick questions honestly?\n\n1. When have you seen me most alive?\n2. What do people come to me for?\n3. What do you think I’d keep doing even if nobody paid me or noticed?"

    public static let defaultMorningQuestion = "What is one small thing today I am looking forward to?"
    public static let defaultEveningQuestion = "Where did life feel worth living today?"
}
