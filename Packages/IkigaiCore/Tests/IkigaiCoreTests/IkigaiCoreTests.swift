import XCTest
@testable import IkigaiCore

/// Expected values come from the web version of the framework, which was tested end to end.
/// The Swift port must produce the same results for the same answers.
final class ExampleAtlasTests: XCTestCase {
    let atlas = Atlas.example

    func testAllStagesComplete() {
        for stage in Stage.allCases { XCTAssertTrue(atlas.isComplete(stage), stage.name) }
        XCTAssertNil(atlas.firstIncompleteStage)
        XCTAssertEqual(atlas.completedStageCount, 6)
    }

    func testPulseAverage() throws {
        XCTAssertEqual(try XCTUnwrap(atlas.pulseAverage), 2.857142857142857, accuracy: 0.000001)
    }

    func testAuthenticity() {
        XCTAssertEqual(atlas.sources.map(\.authStatus),
                       [.core, .core, .core, .core, .growing, .borrowed, .core, .growing, .growing])
    }

    func testLensLabels() {
        XCTAssertEqual(atlas.lens.map(\.label),
                       ["All four circles", "Comfortable, but may feel empty", "Passion", "Mission"])
    }

    func testInsights() {
        let found = atlas.insights()
        XCTAssertEqual(found.map(\.tone), [.hungry, .hungry, .hungry, .good, .good, .good, .note, .note, .note])
        XCTAssertEqual(found.map(\.title), [
            "Change & growth: hungry, even though you have sources",
            "Freedom: hungry, even though you have sources",
            "Being myself: hungry, even though you have sources",
            "Well fed: Resonance and Meaning & value",
            "5 core sources",
            "Energising and meaningful",
            "1 borrowed source",
            "Draining but meaningful",
            "Drift"
        ])
        XCTAssertEqual(found[2].body, "“The allotment”, “Explaining things until they click” and “Building dens as a kid” feed it, yet it sits at 2 out of 5. Ask whether they get enough of your time.")
        XCTAssertEqual(found[3].body, "Mostly through “My sister”, “Calming frightened patients”, “Explaining things until they click” and 3 more.")
        XCTAssertEqual(found[6].body, "“Being seen as a “good nurse” by my manager” did not pass the “this is mine” test. Kamiya held that ikigai cannot be borrowed or imitated. Notice whose expectations it serves.")
        XCTAssertEqual(found[8].body, "“Paperwork” and “Scrolling my phone” drain you and give little back. These are the easiest hours to reclaim.")
    }

    func testRecurringWords() {
        let words = atlas.recurringWords()
        XCTAssertEqual(words.map(\.word), ["allotment", "sister", "explaining", "step", "patient", "shed", "nurses", "frightened",
                                           "useful", "wood", "hands", "starters", "chaos", "radios", "building", "dens"])
        XCTAssertEqual(words.map(\.answers), [6, 5, 5, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2])
    }

    func testSourceSuggestions() {
        let suggestions = atlas.sourceSuggestions()
        XCTAssertEqual(suggestions.map(\.text), [
            "3am in A&E with a frightened boy", "Rebuilding the allotment shed", "Running the induction for new starters",
            "Soil on my hands", "A thank-you card from a patient", "The radio while cooking", "Rain on the shed roof",
            "Explaining something and seeing it click", "Training new staff", "Allotment", "feeling useful at work",
            "Sunday phone calls with my sister", "Explaining medical things calmly", "fixing things", "sorting out chaos"
        ])
        XCTAssertEqual(suggestions.last?.origin, "your words")
    }

    func testRoundTripEncoding() throws {
        let data = try atlas.encoded()
        let decoded = try Atlas.decode(data)
        XCTAssertEqual(decoded, atlas)
    }

    func testMarkdownExport() {
        let md = atlas.markdown()
        XCTAssertTrue(md.hasPrefix("# Ikigai Atlas of Sam"))
        XCTAssertTrue(md.contains("> Life feels most worth living when I turn fear and chaos"))
        XCTAssertTrue(md.contains("- **My sister** (strength 5/5 · core · belonging · present · feeds resonance, fulfilment)"))
        XCTAssertTrue(md.contains("| Night shifts | -1 | 5 |"))
        XCTAssertTrue(md.contains("- [ ] Block Sunday mornings for the allotment, phone off (This Sunday), feeds freedom"))
    }

    func testReadingDigestFitsBudget() {
        let digest = atlas.readingDigest(maxCharacters: 1_500)
        XCTAssertLessThanOrEqual(digest.count, 1_500)
        XCTAssertTrue(digest.hasPrefix("Life feels worth living: 6/10."))
        XCTAssertTrue(atlas.hasEnoughForReading)
    }
}

final class WorkHeavyAtlasTests: XCTestCase {
    func makeAtlas() -> Atlas {
        var a = Atlas()
        a.pulse = Pulse(overall: 3, needs: ["fulfilment": 1, "growth": 2, "future": 4, "resonance": 3])
        a.sources = [
            Source(id: "b1", text: "My job", domain: .craft, strength: 5, needs: [.growth], mode: .belonging, time: .past, auth: Authenticity(free: .no, mine: .yes, alive: .no)),
            Source(id: "b2", text: "Leading the team", domain: .craft, strength: 4, needs: [], mode: .belonging, time: .past, auth: Authenticity(free: .partly, mine: .yes, alive: .yes)),
            Source(id: "b3", text: "Client praise", domain: .craft, strength: 3, needs: [.resonance], mode: .belonging, time: .past),
            Source(id: "b4", text: "My dog", domain: .people, strength: 2, needs: [.future], mode: .belonging, time: .present, auth: Authenticity(free: .yes, mine: .yes, alive: .yes))
        ]
        a.joys = ["Tea", "Rain"]
        a.missing = "my dog; the team and long walks. Coffee"
        return a
    }

    func testInsights() {
        let found = makeAtlas().insights()
        XCTAssertEqual(found.map(\.title), [
            "Fulfilment: hungry and unfed",
            "Change & growth: hungry, even though you have sources",
            "Well fed: A future to look toward",
            "1 core source",
            "1 borrowed source",
            "Work carries 86% of the weight",
            "6 areas are empty",
            "All belonging, little becoming",
            "Much of it lives in memory",
            "Nothing yet to look toward",
            "Few small joys noticed"
        ])
        XCTAssertEqual(found[1].body, "“My job” feeds it, yet it sits at 2 out of 5. Ask whether it gets enough of your time.")
        XCTAssertEqual(found[6].body, "Curiosity, Contribution, Body & nature, Beauty & senses, Ritual and Belief. Not every area needs a source. These are simply places to look if you want more.")
    }

    func testAuthenticity() {
        XCTAssertEqual(makeAtlas().sources.map(\.authStatus), [.borrowed, .growing, .untested, .core])
    }

    func testSuggestionsSplitFreeText() {
        XCTAssertEqual(makeAtlas().sourceSuggestions().map(\.text), ["Tea", "Rain", "the team", "long walks", "Coffee"])
    }

    func testHungryNeedsOrder() {
        XCTAssertEqual(makeAtlas().hungryNeeds(), [.fulfilment, .growth, .resonance])
    }
}

final class BasicsTests: XCTestCase {
    func testBlankAtlas() {
        let a = Atlas()
        XCTAssertFalse(a.hasStarted)
        XCTAssertEqual(a.firstIncompleteStage, .pulse)
        XCTAssertTrue(a.insights().isEmpty)
        XCTAssertTrue(a.recurringWords().isEmpty)
    }

    func testStatementBuilder() {
        var p = StatementParts()
        XCTAssertNil(p.sentence)
        p.doing = "teach someone something."
        p.whom = "with my family"
        p.how = "outdoors"
        XCTAssertEqual(p.sentence, "Life feels most worth living when I teach someone something with my family, especially outdoors.")
    }

    func testDecodingToleratesMissingKeys() throws {
        let json = #"{"name":"Kai","sources":[{"text":"Swimming"}]}"#
        let a = try Atlas.decode(Data(json.utf8))
        XCTAssertEqual(a.name, "Kai")
        XCTAssertEqual(a.sources.first?.strength, 3)
        XCTAssertEqual(a.sources.first?.time, .present)
        XCTAssertEqual(a.moments.count, 1)
    }

    func testRecordPulseReplacesSameDay() {
        var a = Atlas()
        a.pulse.overall = 5
        let day = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertTrue(a.recordPulse(on: day))
        a.pulse.overall = 7
        XCTAssertTrue(a.recordPulse(on: day.addingTimeInterval(60)))
        XCTAssertEqual(a.pulseHistory.count, 1)
        XCTAssertEqual(a.pulseHistory.first?.overall, 7)
    }

    func testTextTools() {
        XCTAssertEqual(TextTools.quoteList(["A"]), "“A”")
        XCTAssertEqual(TextTools.quoteList(["A", "B"]), "“A” and “B”")
        XCTAssertEqual(TextTools.quoteList(["A", "B", "C", "D"]), "“A”, “B”, “C” and 1 more")
        XCTAssertEqual(TextTools.plainList(["A", "B", "C"]), "A, B and C")
        XCTAssertEqual(TextTools.stem("teaching"), "teach")
        XCTAssertEqual(TextTools.stem("stories"), "story")
        XCTAssertEqual(TextTools.stem("boxes"), "box")
        XCTAssertEqual(TextTools.stem("glass"), "glass")
        XCTAssertEqual("  Hello,  World! ".normalizedKey, "hello world")
    }
}
