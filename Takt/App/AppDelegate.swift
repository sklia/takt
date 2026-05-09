import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var engine: NarratorEngine?
    private var observer: PlaybackObserver?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Takt")
        statusItem = item

        let engine = NarratorEngine(
            speaker: AVSpeechSpeaker(),
            ducker: NoOpDucker()
        )
        let observer = PlaybackObserver()
        observer.start { event in
            engine.handle(event)
        }

        self.engine = engine
        self.observer = observer
    }
}
