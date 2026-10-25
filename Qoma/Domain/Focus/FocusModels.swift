import Foundation

// MARK: - Focus Policy

enum FocusPolicyMode: String, Codable, CaseIterable, Sendable {
    case allowing
    case blocking
    case timerOnly
}

struct SessionPolicy: Codable, Equatable, Sendable {
    var mode: FocusPolicyMode
    var allowedApps: Set<String> = []
    var blockedApps: Set<String> = []
    var allowedDomains: Set<String> = []
    var blockedDomains: Set<String> = []

    static let timerOnly = SessionPolicy(mode: .timerOnly)
}

struct ForegroundActivity: Equatable, Sendable {
    let bundleID: String
    let appName: String
    let domain: String?
    let browserBundleID: String?
}

struct PolicyDecision: Equatable, Sendable {
    let isDistraction: Bool
    let reason: Reason

    enum Reason: String, Codable, Equatable, Sendable {
        case timerOnly
        case allowedExplicitly
        case allowedBrowser
        case allowedDomain
        case safeByDefault
        case blockedExplicitly
        case blockedBrowser
        case blockedDomain
        case unsupportedBrowser
        case permissionUnavailable
        case noDomainRead
    }
}

// MARK: - Session Draft & Snapshot

struct SessionDraft: Codable, Equatable, Sendable {
    var taskTitle: String
    var plannedMinutes: Int
    var policy: SessionPolicy
    var domainBrowserBundleID: String

    init(
        taskTitle: String = "",
        plannedMinutes: Int = 10,
        policy: SessionPolicy = .timerOnly,
        domainBrowserBundleID: String = "com.apple.Safari"
    ) {
        self.taskTitle = taskTitle
        self.plannedMinutes = plannedMinutes
        self.policy = policy
        self.domainBrowserBundleID = domainBrowserBundleID
    }

    private enum CodingKeys: String, CodingKey {
        case taskTitle, plannedMinutes, policy, domainBrowserBundleID
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        taskTitle = try values.decode(String.self, forKey: .taskTitle)
        plannedMinutes = try values.decode(Int.self, forKey: .plannedMinutes)
        policy = try values.decode(SessionPolicy.self, forKey: .policy)
        // Sessions saved before browser selection used Safari implicitly.
        domainBrowserBundleID = try values.decodeIfPresent(String.self, forKey: .domainBrowserBundleID)
            ?? "com.apple.Safari"
    }

    var displayTitle: String {
        taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Focus session"
            : taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct ActiveSessionSnapshot: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let accountID: String
    let startedAt: Date
    var deadline: Date
    var pausedAt: Date?
    var accumulatedActiveSeconds: TimeInterval
    var activeSegmentStartedAt: Date?
    var draft: SessionDraft
    var status: SessionStatus
    var endedAt: Date?
    var interruptedReason: String?

    init(
        id: UUID = UUID(),
        accountID: String,
        startedAt: Date = Date(),
        deadline: Date,
        pausedAt: Date? = nil,
        accumulatedActiveSeconds: TimeInterval = 0,
        activeSegmentStartedAt: Date? = nil,
        draft: SessionDraft,
        status: SessionStatus = .active,
        endedAt: Date? = nil,
        interruptedReason: String? = nil
    ) {
        self.id = id
        self.accountID = accountID
        self.startedAt = startedAt
        self.deadline = deadline
        self.pausedAt = pausedAt
        self.accumulatedActiveSeconds = accumulatedActiveSeconds
        self.activeSegmentStartedAt = status == .active
            ? (activeSegmentStartedAt ?? startedAt)
            : activeSegmentStartedAt
        self.draft = draft
        self.status = status
        self.endedAt = endedAt
        self.interruptedReason = interruptedReason
    }
}

enum SessionStatus: String, Codable, Equatable, Sendable {
    case active
    case paused
    case completed
    case interrupted
}

// MARK: - Session History

struct FocusSession: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let accountID: String
    let startedAt: Date
    var endedAt: Date
    var plannedMinutes: Int
    var actualActiveSeconds: TimeInterval
    var status: SessionStatus
    var draftSnapshot: SessionDraft
    var taskTitle: String
    var interruptedReason: String?

    init(
        id: UUID = UUID(),
        accountID: String,
        startedAt: Date,
        endedAt: Date,
        plannedMinutes: Int,
        actualActiveSeconds: TimeInterval,
        status: SessionStatus,
        draftSnapshot: SessionDraft,
        taskTitle: String,
        interruptedReason: String? = nil
    ) {
        self.id = id
        self.accountID = accountID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.plannedMinutes = plannedMinutes
        self.actualActiveSeconds = actualActiveSeconds
        self.status = status
        self.draftSnapshot = draftSnapshot
        self.taskTitle = taskTitle
        self.interruptedReason = interruptedReason
    }
}

// MARK: - Catch Ledger

struct CatchEvent: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let sessionID: UUID
    let accountID: String
    let kindID: String
    let depositedAt: Date
    var bankedAt: Date?

    var isBanked: Bool { bankedAt != nil }

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        accountID: String,
        kindID: String,
        depositedAt: Date,
        bankedAt: Date? = nil
    ) {
        self.id = id
        self.sessionID = sessionID
        self.accountID = accountID
        self.kindID = kindID
        self.depositedAt = depositedAt
        self.bankedAt = bankedAt
    }
}

// MARK: - Access / Entitlement

enum AccessState: Equatable, Sendable {
    case signedOut
    case trialing(expiresAt: Date)
    case paid
    case expired
    case unknown
}

// MARK: - Permission

enum MonitoringPermissionStatus: Equatable, Sendable {
    case notDetermined
    case granted
    case denied
    case restricted
}

enum AppMonitoringCapability: Equatable, Sendable {
    case available
    case needsPermission
    case unsupported
}
