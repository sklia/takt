import Foundation
import Observation

@MainActor
@Observable
final class PermissionStateStore {
    var state: PermissionState = .unknown
}
