import Foundation
import Testing
@testable import Qoma

struct FocusPolicyEvaluatorTests {
    private let chrome = "com.google.Chrome"
    private let slack = "com.tinyspeck.slackmacgap"
    private let xcode = "com.apple.dt.Xcode"

    @Test
    func timerOnlyAlwaysSafe() {
        let policy = SessionPolicy(mode: .timerOnly)
        let activity = ForegroundActivity(bundleID: chrome, appName: "Chrome", domain: "youtube.com", browserBundleID: chrome)
        let decision = FocusPolicyEvaluator.evaluate(activity, against: policy)
        #expect(decision.isDistraction == false)
        #expect(decision.reason == .timerOnly)
    }

    @Test
    func allowingAllowedAppIsSafe() {
        var policy = SessionPolicy(mode: .allowing)
        policy.allowedApps.insert(xcode)
        let activity = ForegroundActivity(bundleID: xcode, appName: "Xcode", domain: nil, browserBundleID: nil)
        let decision = FocusPolicyEvaluator.evaluate(activity, against: policy)
        #expect(decision.isDistraction == false)
        #expect(decision.reason == .allowedExplicitly)
    }

    @Test
    func allowingAllowedBrowserCoversAllSites() {
        var policy = SessionPolicy(mode: .allowing)
        policy.allowedApps.insert(chrome)
        let activity = ForegroundActivity(bundleID: chrome, appName: "Chrome", domain: "youtube.com", browserBundleID: chrome)
        let decision = FocusPolicyEvaluator.evaluate(activity, against: policy)
        #expect(decision.isDistraction == false)
        #expect(decision.reason == .allowedExplicitly)
    }

    @Test
    func allowingIgnoresLegacyDomainRules() {
        var policy = SessionPolicy(mode: .allowing)
        policy.allowedDomains.insert("example.com")
        let activity = ForegroundActivity(bundleID: chrome, appName: "Chrome", domain: "www.example.com", browserBundleID: chrome)
        let decision = FocusPolicyEvaluator.evaluate(activity, against: policy)
        #expect(decision.isDistraction)
        #expect(decision.reason == .blockedExplicitly)
    }

    @Test
    func allowingUnallowedBrowserBlocked() {
        var policy = SessionPolicy(mode: .allowing)
        policy.allowedDomains.insert("example.com")
        let activity = ForegroundActivity(bundleID: chrome, appName: "Chrome", domain: "youtube.com", browserBundleID: chrome)
        let decision = FocusPolicyEvaluator.evaluate(activity, against: policy)
        #expect(decision.isDistraction == true)
        #expect(decision.reason == .blockedExplicitly)
    }

    @Test
    func allowingOtherAppNotAllowed() {
        var policy = SessionPolicy(mode: .allowing)
        policy.allowedApps.insert(xcode)
        let activity = ForegroundActivity(bundleID: slack, appName: "Slack", domain: nil, browserBundleID: nil)
        let decision = FocusPolicyEvaluator.evaluate(activity, against: policy)
        #expect(decision.isDistraction == true)
    }

    @Test
    func blockingBlockedAppIsDistraction() {
        var policy = SessionPolicy(mode: .blocking)
        policy.blockedApps.insert(slack)
        let activity = ForegroundActivity(bundleID: slack, appName: "Slack", domain: nil, browserBundleID: nil)
        let decision = FocusPolicyEvaluator.evaluate(activity, against: policy)
        #expect(decision.isDistraction == true)
        #expect(decision.reason == .blockedExplicitly)
    }

    @Test
    func blockingBlockedBrowserBlocksAllTabs() {
        var policy = SessionPolicy(mode: .blocking)
        policy.blockedApps.insert(chrome)
        let activity = ForegroundActivity(bundleID: chrome, appName: "Chrome", domain: "example.com", browserBundleID: chrome)
        let decision = FocusPolicyEvaluator.evaluate(activity, against: policy)
        #expect(decision.isDistraction == true)
        #expect(decision.reason == .blockedExplicitly)
    }

    @Test
    func blockingIgnoresLegacyDomainRules() {
        var policy = SessionPolicy(mode: .blocking)
        policy.blockedDomains.insert("youtube.com")
        let activity = ForegroundActivity(bundleID: chrome, appName: "Chrome", domain: "www.youtube.com", browserBundleID: chrome)
        let decision = FocusPolicyEvaluator.evaluate(activity, against: policy)
        #expect(!decision.isDistraction)
        #expect(decision.reason == .safeByDefault)
    }

    @Test
    func unconfiguredDomainPolicyDoesNotRequireAutomation() async {
        let capability = await MainActor.run {
            PermissionManager.shared.permissionRequirement(for: SessionPolicy(mode: .allowing))
        }
        #expect(capability == .available)
    }

    @Test
    func blockingSafeByDefault() {
        let policy = SessionPolicy(mode: .blocking)
        let activity = ForegroundActivity(bundleID: xcode, appName: "Xcode", domain: nil, browserBundleID: nil)
        let decision = FocusPolicyEvaluator.evaluate(activity, against: policy)
        #expect(decision.isDistraction == false)
        #expect(decision.reason == .safeByDefault)
    }

    @Test
    func unsupportedBrowserEvaluatedAsApp() {
        let firefox = "org.mozilla.firefox"
        var policy = SessionPolicy(mode: .allowing)
        policy.allowedApps.insert(firefox)
        let activity = ForegroundActivity(bundleID: firefox, appName: "Firefox", domain: "youtube.com", browserBundleID: firefox)
        let decision = FocusPolicyEvaluator.evaluate(activity, against: policy)
        #expect(decision.isDistraction == false)
        #expect(decision.reason == .allowedExplicitly)
    }

    @Test
    func domainNormalizationDropsWWW() {
        #expect(FocusPolicyEvaluator.normalizeDomain("www.Example.COM") == "example.com")
        #expect(FocusPolicyEvaluator.normalizeDomain("EXAMPLE.COM") == "example.com")
        #expect(FocusPolicyEvaluator.normalizeDomain("sub.example.com") == "sub.example.com")
    }
}
