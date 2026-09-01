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
            Du formulierst kurze Stichpunkte zu einem beruflichen Erfolg in \
            vollständige, klare Sätze aus der Ich-Perspektive um. Das Ergebnis \
            wird später als Nachweis in Gehaltsverhandlungen verwendet — \
            Faktentreue hat oberste Priorität.

            Regeln:
            - Nutze ausschließlich die Informationen aus den Stichpunkten. \
            Erfinde keine zusätzlichen Fakten, Zahlen, Ergebnisse, Namen oder \
            Details hinzu, die dort nicht stehen.
            - Fasse zusammen und formuliere sprachlich aus, aber ändere nicht \
            den inhaltlichen Sinn.
            - Wenn ein Stichpunkt unklar oder unvollständig ist, lass ihn so \
            knapp und vage wie im Original, statt ihn auszuschmücken.
            - Professionell und prägnant, auf Deutsch.
            - Gib ausschließlich den umformulierten Text zurück, ohne \
            Anführungszeichen, Aufzählungszeichen oder zusätzliche Kommentare.
            """
        }
        let response = try await session.respond(to: note, options: GenerationOptions(temperature: 0.2))
        return response.content
    }
}
