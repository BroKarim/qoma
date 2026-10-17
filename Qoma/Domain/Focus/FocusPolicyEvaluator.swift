import Foundation

/// Pure policy evaluator. Contains no AppKit / UI state.
enum FocusPolicyEvaluator {
    static let policyDomainBrowsers: Set<String> = [
        "com.google.Chrome",
        "com.apple.Safari",
    ]

    static func evaluate(_ activity: ForegroundActivity, against policy: SessionPolicy) -> PolicyDecision {
        switch policy.mode {
        case .timerOnly:
            return PolicyDecision(isDistraction: false, reason: .timerOnly)
        case .allowing:
            return evaluateAllowing(activity, policy: policy)
        case .blocking:
            return evaluateBlocking(activity, policy: policy)
        }
    }

    private static func evaluateAllowing(_ activity: ForegroundActivity, policy: SessionPolicy) -> PolicyDecision {
        let normalizedBundle = activity.bundleID.trimmingCharacters(in: .whitespacesAndNewlines)

        if policy.allowedApps.contains(normalizedBundle) {
            return PolicyDecision(isDistraction: false, reason: .allowedExplicitly)
        }

        return PolicyDecision(isDistraction: true, reason: .blockedExplicitly)
    }

    private static func evaluateBlocking(_ activity: ForegroundActivity, policy: SessionPolicy) -> PolicyDecision {
        let normalizedBundle = activity.bundleID.trimmingCharacters(in: .whitespacesAndNewlines)

        if policy.blockedApps.contains(normalizedBundle) {
            return PolicyDecision(isDistraction: true, reason: .blockedExplicitly)
        }

        return PolicyDecision(isDistraction: false, reason: .safeByDefault)
    }

    static func isBrowserCapableOfDomainPolicy(_ bundleID: String) -> Bool {
        policyDomainBrowsers.contains(bundleID)
    }

    static func normalizeDomain(_ host: String) -> String {
        var trimmed = host.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.hasPrefix("www.") {
            trimmed.removeFirst(4)
        }
        return trimmed
    }
}
