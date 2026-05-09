@preconcurrency import AppIntents

struct TaktFocusFilter: SetFocusFilterIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Takt"
    nonisolated(unsafe) static var description: IntentDescription? = "Pause track narration during this Focus"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "Takt", subtitle: "Pause track narration")
    }

    @Parameter(title: "Pause Narration", default: false)
    var pauseNarration: Bool

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(pauseNarration, forKey: "focusPauseActive")
        return .result()
    }
}
