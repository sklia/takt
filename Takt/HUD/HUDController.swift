import AppKit
import SwiftUI

@MainActor
final class HUDController {
    typealias StyleProvider = () -> HUDStyle
    typealias PositionProvider = () -> HUDPosition
    typealias ScreenProvider = () -> NSScreen?

    private let artFetcher: AlbumArtFetcher
    private let dismissDelay: TimeInterval
    private let styleProvider: StyleProvider
    private let positionProvider: PositionProvider
    private let screenProvider: ScreenProvider
    private let debounce: Duration
    private let model = HUDModel()
    private var panel: HUDPanel?
    private var activeStyle: HUDStyle?
    private var lastShownURI: String?
    private var dismissTask: Task<Void, Never>?
    private var showTask: Task<Void, Never>?
    private var clickObserver: Any?
    private var enterObserver: Any?
    private var exitObserver: Any?

    init(
        artFetcher: AlbumArtFetcher = AlbumArtFetcher(),
        debounce: Duration = .milliseconds(250),
        dismissDelay: TimeInterval = 4,
        style: @escaping StyleProvider = { .standard },
        position: @escaping PositionProvider = { .topCenter },
        screen: @escaping ScreenProvider = { .main }
    ) {
        self.artFetcher = artFetcher
        self.debounce = debounce
        self.dismissDelay = dismissDelay
        self.styleProvider = style
        self.positionProvider = position
        self.screenProvider = screen
    }

    func show(_ event: PlaybackEvent) {
        guard event.uri != lastShownURI else { return }
        lastShownURI = event.uri
        dismissTask?.cancel()
        showTask?.cancel()
        panel?.orderOut(nil)

        showTask = Task { [weak self, artFetcher, debounce] in
            async let art = artFetcher.fetch(uri: event.uri)
            do { try await Task.sleep(for: debounce) } catch { return }
            guard let self else { return }
            self.model.update(from: event)
            self.model.albumArt = await art
            self.presentPanel()
            self.scheduleDismiss()
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        showTask?.cancel()
        panel?.orderOut(nil)
        removeObservers()
    }

    private func presentPanel() {
        let panel = ensurePanel()
        positionPanel(panel)
        panel.orderFrontRegardless()
        panel.installTrackingArea()
        observePanelEvents(on: panel)
    }

    private func ensurePanel() -> HUDPanel {
        let currentStyle = styleProvider()
        if let existing = panel, activeStyle == currentStyle { return existing }
        panel?.orderOut(nil)
        let hostingView = NSHostingView(rootView: HUDView(model: model, style: currentStyle))
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = .clear
        hostingView.setFrameSize(hostingView.fittingSize)
        let p = HUDPanel(contentRect: NSRect(origin: .zero, size: hostingView.fittingSize))
        p.contentView = hostingView
        self.panel = p
        self.activeStyle = currentStyle
        return p
    }

    private func positionPanel(_ panel: HUDPanel) {
        guard let screen = screenProvider() ?? NSScreen.screens.first else { return }
        let frame = screen.visibleFrame
        let size = panel.frame.size
        let margin: CGFloat = 16
        let position = positionProvider()

        let x: CGFloat = switch position {
        case .topLeft, .bottomLeft:
            frame.minX + margin
        case .topCenter, .bottomCenter:
            frame.midX - size.width / 2
        case .topRight, .bottomRight:
            frame.maxX - size.width - margin
        }

        let y: CGFloat = switch position {
        case .topLeft, .topCenter, .topRight:
            frame.maxY - size.height - margin
        case .bottomLeft, .bottomCenter, .bottomRight:
            frame.minY + margin
        }

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func scheduleDismiss() {
        dismissTask?.cancel()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(self?.dismissDelay ?? 4))
            guard !Task.isCancelled else { return }
            self?.dismiss()
        }
    }

    private func observePanelEvents(on panel: HUDPanel) {
        removeObservers()
        clickObserver = NotificationCenter.default.addObserver(
            forName: .hudPanelClicked, object: panel, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.dismiss() }
        }
        enterObserver = NotificationCenter.default.addObserver(
            forName: .hudPanelMouseEntered, object: panel, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.dismissTask?.cancel() }
        }
        exitObserver = NotificationCenter.default.addObserver(
            forName: .hudPanelMouseExited, object: panel, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.scheduleDismiss() }
        }
    }

    private func removeObservers() {
        for observer in [clickObserver, enterObserver, exitObserver] {
            if let observer { NotificationCenter.default.removeObserver(observer) }
        }
        clickObserver = nil
        enterObserver = nil
        exitObserver = nil
    }
}
