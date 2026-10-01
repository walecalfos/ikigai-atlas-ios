import Foundation

public extension Atlas {
    /// A fully worked atlas for a fictional nurse, shown so people can see where the framework leads.
    static let example: Atlas = {
        var a = Atlas()
        a.name = "Sam"
        a.updatedAt = Date(timeIntervalSince1970: 1_790_000_000)
        a.pulse = Pulse(overall: 6, needs: ["fulfilment": 3, "growth": 2, "future": 3, "resonance": 4, "freedom": 2, "selfhood": 2, "meaning": 4])
        a.moments = [
            Moment(id: "m1", title: "3am in A&E with a frightened boy",
                   what: "A boy with an asthma attack and his panicking dad. I talked them through every step until they were both laughing.",
                   who: "A patient and his father",
                   why: "I was completely useful and completely myself. Explaining things until the fear goes away.",
                   needs: [.meaning, .resonance, .selfhood]),
            Moment(id: "m2", title: "Rebuilding the allotment shed",
                   what: "A whole weekend rebuilding the shed with my sister from salvaged wood.",
                   who: "My sister",
                   why: "Making something real with my hands, and unhurried time with her.",
                   needs: [.fulfilment, .selfhood, .resonance]),
            Moment(id: "m3", title: "Running the induction for new starters",
                   what: "I redesigned the handover checklist and taught it to six new nurses.",
                   who: "New nurses on the ward",
                   why: "Watching people get less scared and more capable. Turning chaos into a clear system.",
                   needs: [.growth, .meaning])
        ]
        a.childhood = "Taking radios apart and explaining to my little sister how they worked. Building dens in the woods."
        a.anchor = "The allotment, and Sunday phone calls with my sister."
        a.missing = "My sister, the allotment, feeling useful at work."
        a.joys = ["First coffee on the back step", "Soil on my hands", "A thank-you card from a patient", "The radio while cooking", "Rain on the shed roof", "Explaining something and seeing it click"]
        a.activities = [
            Activity(id: "a1", name: "Night shifts", energy: -1, meaning: 5),
            Activity(id: "a2", name: "Paperwork", energy: -2, meaning: 2),
            Activity(id: "a3", name: "Training new staff", energy: 2, meaning: 5),
            Activity(id: "a4", name: "Allotment", energy: 2, meaning: 4),
            Activity(id: "a5", name: "Scrolling my phone", energy: -1, meaning: 1),
            Activity(id: "a6", name: "Cooking", energy: 1, meaning: 3),
            Activity(id: "a7", name: "Gym", energy: 0, meaning: 3)
        ]
        a.flow = "Fixing things. Planning next season at the allotment. Redesigning a messy process at work."
        a.seekYouFor = "Explaining medical things calmly, fixing things, sorting out chaos."
        func src(_ id: String, _ text: String, _ domain: Domain, _ strength: Int, _ needs: [Need], _ mode: Mode, _ time: TimeTag, _ free: Answer, _ mine: Answer, _ alive: Answer) -> Source {
            Source(id: id, text: text, domain: domain, strength: strength, needs: needs, mode: mode, time: time, auth: Authenticity(free: free, mine: mine, alive: alive))
        }
        a.sources = [
            src("s1", "My sister", .people, 5, [.resonance, .fulfilment], .belonging, .present, .yes, .yes, .yes),
            src("s2", "The allotment", .body, 5, [.fulfilment, .selfhood, .freedom], .becoming, .present, .yes, .yes, .yes),
            src("s3", "Calming frightened patients", .craft, 4, [.meaning, .resonance], .both, .present, .yes, .yes, .yes),
            src("s4", "Teaching new starters", .contribution, 5, [.growth, .meaning], .both, .present, .yes, .yes, .yes),
            src("s5", "Explaining things until they click", .curiosity, 4, [.selfhood, .resonance], .becoming, .present, .yes, .yes, .partly),
            src("s6", "Being seen as a “good nurse” by my manager", .craft, 3, [.resonance], .belonging, .present, .no, .no, .partly),
            src("s7", "First coffee on the back step", .ritual, 3, [.fulfilment], .becoming, .present, .yes, .yes, .yes),
            src("s8", "Building dens as a kid", .body, 2, [.freedom, .selfhood], .becoming, .past, .yes, .yes, .partly),
            src("s9", "Starting a community repair café", .contribution, 3, [.future, .meaning, .growth], .both, .future, .yes, .yes, .partly)
        ]
        a.threads = [
            AtlasThread(id: "t1", name: "Turning fear into understanding", note: "3am in A&E, teaching new starters, explaining radios to my sister"),
            AtlasThread(id: "t2", name: "Making real things with my hands", note: "The shed, the allotment, taking radios apart"),
            AtlasThread(id: "t3", name: "Order out of chaos", note: "The handover checklist, planning the allotment")
        ]
        a.statement = "Life feels most worth living when I turn fear and chaos into understanding for the people around me, and when my hands are in soil or wood."
        a.lens = [
            LensItem(id: "l1", text: "Teaching and training", love: true, good: true, needed: true, paid: true),
            LensItem(id: "l2", text: "Nursing care", love: false, good: true, needed: true, paid: true),
            LensItem(id: "l3", text: "Carpentry and repair", love: true, good: true, needed: false, paid: false),
            LensItem(id: "l4", text: "A repair café", love: true, good: false, needed: true, paid: false)
        ]
        a.experiments = [
            Experiment(id: "e1", text: "Block Sunday mornings for the allotment, phone off", need: .freedom, when: "This Sunday"),
            Experiment(id: "e2", text: "Sign up for a beginner woodworking evening class", need: .growth, when: "By Friday"),
            Experiment(id: "e3", text: "Ask the library about hosting one repair café morning", need: .future, when: "Next week")
        ]
        a.rhythm = Rhythm(morning: Framework.defaultMorningQuestion, evening: Framework.defaultEveningQuestion)
        return a
    }()
}
