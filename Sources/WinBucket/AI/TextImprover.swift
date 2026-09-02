import FoundationModels

// On-device Apple Intelligence text expansion — no network, no cloud.
enum TextImprover {
    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }

    static func expand(note: String) async throws -> String {
        let session = LanguageModelSession {
            """
            You turn short bullet points about a professional achievement into \
            complete, clear sentences written in the first person. The result \
            is later used as evidence in salary negotiations — factual \
            accuracy is the top priority.

            Rules:
            - Use only the information given in the bullet points. Do not \
            invent additional facts, numbers, results, names or details that \
            aren't there.
            - Summarize and phrase it fluently, but don't change the meaning.
            - If a bullet point is unclear or incomplete, leave it as brief \
            and vague as the original instead of embellishing it.
            - Professional and concise. Reply in the same language the note \
            is written in.
            - Return only the rewritten text, with no quotation marks, \
            bullet points or extra commentary.
            """
        }
        let response = try await session.respond(to: note, options: GenerationOptions(temperature: 0.2))
        return response.content
    }
}
