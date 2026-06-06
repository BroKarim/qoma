import Foundation
import OSLog

extension Logger {
    static let qomaSubsystem = Bundle.main.bundleIdentifier ?? "com.dzulkiram.qoma"

    static let analytics = Logger(subsystem: qomaSubsystem, category: "Analytics")
    static let tracking = Logger(subsystem: qomaSubsystem, category: "Tracking")
    static let session = Logger(subsystem: qomaSubsystem, category: "Session")
    static let ui = Logger(subsystem: qomaSubsystem, category: "UI")
    static let sound = Logger(subsystem: qomaSubsystem, category: "Sound")
    static let browser = Logger(subsystem: qomaSubsystem, category: "Browser")
    static let permissions = Logger(subsystem: qomaSubsystem, category: "Permissions")
    static let store = Logger(subsystem: qomaSubsystem, category: "Store")
}
