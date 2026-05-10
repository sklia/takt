import AppKit

final class HUDPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = false
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func mouseDown(with event: NSEvent) {
        NotificationCenter.default.post(name: .hudPanelClicked, object: self)
    }

    override func mouseEntered(with event: NSEvent) {
        NotificationCenter.default.post(name: .hudPanelMouseEntered, object: self)
    }

    override func mouseExited(with event: NSEvent) {
        NotificationCenter.default.post(name: .hudPanelMouseExited, object: self)
    }

    func installTrackingArea() {
        guard let contentView else { return }
        let area = NSTrackingArea(
            rect: contentView.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        contentView.addTrackingArea(area)
    }
}

extension Notification.Name {
    static let hudPanelClicked = Notification.Name("HUDPanelClicked")
    static let hudPanelMouseEntered = Notification.Name("HUDPanelMouseEntered")
    static let hudPanelMouseExited = Notification.Name("HUDPanelMouseExited")
}
