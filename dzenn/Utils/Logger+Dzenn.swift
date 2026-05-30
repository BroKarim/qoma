import Foundation
import OSLog

extension Logger {
    static let dzennSubsystem = Bundle.main.bundleIdentifier ?? "com.personal.dzenn"

    static let analytics = Logger(subsystem: dzennSubsystem, category: "Analytics")
    static let tracking = Logger(subsystem: dzennSubsystem, category: "Tracking")
    static let session = Logger(subsystem: dzennSubsystem, category: "Session")
    static let ui = Logger(subsystem: dzennSubsystem, category: "UI")
    static let sound = Logger(subsystem: dzennSubsystem, category: "Sound")
    static let browser = Logger(subsystem: dzennSubsystem, category: "Browser")
    static let permissions = Logger(subsystem: dzennSubsystem, category: "Permissions")
    static let store = Logger(subsystem: dzennSubsystem, category: "Store")
}
