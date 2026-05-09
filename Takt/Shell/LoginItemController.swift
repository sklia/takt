import Foundation
import Observation
import ServiceManagement

@MainActor
@Observable
final class LoginItemController {
    var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            do {
                if isEnabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Revert on failure; suppress further didSet via the guard above.
                isEnabled = oldValue
            }
        }
    }

    init() {
        let initialStatus = SMAppService.mainApp.status
        if initialStatus == .notRegistered {
            try? SMAppService.mainApp.register()
        }
        self.isEnabled = SMAppService.mainApp.status == .enabled
    }
}
