import Foundation
import IkigaiCore
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Optional pattern reading with Apple's on-device language model.
/// Nothing leaves the phone. Devices without Apple Intelligence keep the built-in insights.
@MainActor
final class PatternReader: ObservableObject {
    enum Availability: Equatable {
        case available
        case appleIntelligenceOff
        case deviceNotEligible
        case modelNotReady
        case needsNewerOS

        var explanation: String {
            switch self {
            case .available: return ""
            case .appleIntelligenceOff: return "Turn on Apple Intelligence in Settings to use this. It runs entirely on your iPhone."
            case .deviceNotEligible: return "This iPhone doesn’t support Apple Intelligence, so this optional step isn’t available. Everything else works without it."
            case .modelNotReady: return "Apple Intelligence is still getting ready on this iPhone. Try again a little later."
            case .needsNewerOS: return "Pattern reading needs iOS 26 or later with Apple Intelligence. Everything else works without it."
            }
        }
    }

    @Published private(set) var isRunning = false
    @Published var errorMessage: String?
    private var task: Task<Void, Never>?

    var availability: Availability {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let availability = SystemLanguageModel.default.availability
            if case .available = availability { return .available }
            if case .unavailable(let reason) = availability {
                switch reason {
                case .appleIntelligenceNotEnabled: return .appleIntelligenceOff
                case .deviceNotEligible: return .deviceNotEligible
                case .modelNotReady: return .modelNotReady
                @unknown default: return .modelNotReady
                }
            }
            return .modelNotReady
        }
        #endif
        return .needsNewerOS
    }

    /// Reads the atlas and hands back suggestions. The person decides what to keep.
    func read(_ atlas: Atlas, completion: @escaping (Reading) -> Void) {
        guard !isRunning else { return }
        errorMessage = nil
        isRunning = true
        task = Task { [weak self] in
            let result = await Self.generate(from: atlas)
            guard let self, !Task.isCancelled else { return }
            self.isRunning = false
            switch result {
            case .success(let reading): completion(reading)
            case .failure(let message): self.errorMessage = message
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        isRunning = false
    }

    private enum Outcome {
        case success(Reading)
        case failure(String)
    }

    private static func generate(from atlas: Atlas) async -> Outcome {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let session = LanguageModelSession {
                """
                You help a person understand their ikigai, the Japanese idea of what makes life worth living. \
                Follow the Japanese understanding: ikigai is plural, often found in small daily things, spans all of life and is not only work. \
                Use only the person's own material. Echo their own words. Give no generic advice and no clichés. \
                Never diagnose and give no medical, legal or financial advice. Be warm, plain and specific. \
                Write in the language the person wrote in. Every experiment must be small and doable within one week.
                """
            }
            let prompt = """
            Here is everything this person wrote in their Ikigai Atlas. Find patterns they may not have noticed.

            \(atlas.readingDigest(maxCharacters: 4_500))
            """
            do {
                let response = try await session.respond(to: prompt, generating: GeneratedReading.self)
                return .success(response.content.reading)
            } catch let error as LanguageModelSession.GenerationError {
                switch error {
                case .exceededContextWindowSize:
                    return .failure("Your atlas is too long to read in one go on this iPhone. Try shortening a few long answers.")
                case .guardrailViolation:
                    return .failure("Apple Intelligence couldn’t respond to this. Everything else in the app still works.")
                default:
                    return .failure("The reading didn’t complete. Try again.")
                }
            } catch {
                return .failure("The reading didn’t complete. Try again.")
            }
        }
        #endif
        return .failure(Availability.needsNewerOS.explanation)
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct GeneratedThread {
    @Guide(description: "A thread that runs through their answers, named in 2 to 6 words, ideally starting with a verb")
    let name: String
    @Guide(description: "One sentence on why this thread fits them")
    let why: String
    @Guide(description: "Two or three short phrases quoted from their answers that show the thread")
    let evidence: [String]
}

@available(iOS 26.0, *)
@Generable
struct GeneratedExperiment {
    @Guide(description: "A small, concrete action they can take within one week")
    let text: String
    @Guide(description: "The need it feeds, exactly one of: fulfilment, growth, future, resonance, freedom, selfhood, meaning")
    let need: String
}

@available(iOS 26.0, *)
@Generable
struct GeneratedReading {
    @Guide(description: "One or two sentences about a pattern across their answers that they may not have noticed")
    let pattern: String
    @Guide(description: "Three or four threads")
    let threads: [GeneratedThread]
    @Guide(description: "One sentence about a tension or trade-off visible in their answers, or an empty string")
    let tension: String
    @Guide(description: "Three first-person statements of their ikigai, each under 35 words, starting 'Life feels most worth living when I'")
    let statements: [String]
    @Guide(description: "Three experiments")
    let experiments: [GeneratedExperiment]
    @Guide(description: "One open question for them to sit with")
    let question: String
}

@available(iOS 26.0, *)
extension GeneratedReading {
    var reading: Reading {
        Reading(
            createdAt: Date(),
            threads: threads.prefix(5).compactMap { (t: GeneratedThread) -> Reading.ThreadSuggestion? in
                let name = t.name.trimmed
                guard !name.isEmpty else { return nil }
                return Reading.ThreadSuggestion(name: String(name.prefix(80)), why: t.why.trimmed, evidence: t.evidence.map(\.trimmed).filter { !$0.isEmpty }.prefix(4).map { String($0) })
            },
            pattern: pattern.trimmed,
            tension: tension.trimmed,
            statements: statements.map(\.trimmed).filter { !$0.isEmpty }.prefix(4).map { String($0) },
            experiments: experiments.prefix(4).compactMap { (e: GeneratedExperiment) -> Reading.ExperimentSuggestion? in
                let text = e.text.trimmed
                guard !text.isEmpty else { return nil }
                return Reading.ExperimentSuggestion(text: text, need: Need(rawValue: e.need.trimmed.lowercased()))
            },
            question: question.trimmed
        )
    }
}
#endif
