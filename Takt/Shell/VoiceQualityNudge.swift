import AppKit
import Observation

@MainActor
final class VoiceQualityNudge {
    private let settings: SettingsStore
    private let voiceCatalog: VoiceCatalog
    private let openSettings: () -> Void

    init(
        settings: SettingsStore,
        voiceCatalog: VoiceCatalog,
        openSettings: @escaping () -> Void
    ) {
        self.settings = settings
        self.voiceCatalog = voiceCatalog
        self.openSettings = openSettings
        observe()
    }

    private func observe() {
        withObservationTracking {
            _ = settings.narratorEnabled
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.checkOnEnable()
                self.observe()
            }
        }
    }

    private func checkOnEnable() {
        guard settings.narratorEnabled else { return }
        guard !settings.hasShownVoiceQualityNudge else { return }
        guard isCurrentVoiceBelowPremium() else { return }
        presentAlert()
    }

    private func isCurrentVoiceBelowPremium() -> Bool {
        let tier: VoiceTier
        if let id = settings.selectedVoiceID {
            tier = voiceCatalog.tier(for: id)
        } else {
            tier = voiceCatalog.defaultVoice(for: .current)?.tier ?? .standard
        }
        return tier != .siri && tier != .premium
    }

    private func presentAlert() {
        let alert = NSAlert()
        alert.messageText = "Use a Siri voice for clearer narration"
        alert.informativeText = "Takt is using a standard voice. " +
            "Install a Siri voice via System Settings > Spoken Content for better announcements."
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Use anyway")
        NSApp.activate()
        let response = alert.runModal()
        settings.hasShownVoiceQualityNudge = true
        if response == .alertFirstButtonReturn {
            openSettings()
        }
    }
}
