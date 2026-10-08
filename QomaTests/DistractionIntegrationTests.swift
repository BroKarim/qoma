import AppKit
import AVFoundation
import Testing
@testable import Qoma

@MainActor
struct DistractionIntegrationTests {
    @Test func repeatedPolicyUpdatesKeepEpisodeAndGrowActualSurface() {
        let fixture = DistractionTestFixture()
        let controller = DistractionOverlayController(
            frontmostPID: { fixture.pid },
            locate: { DistractionTargetWindow(number: 0, ownerPID: $0, level: 0,
                                             frame: CGRect(x: 50, y: 50, width: 600, height: 400)) },
            now: { fixture.date }, chooseEffect: { .iceFlower }, audio: DistractionAudioPlayer(enabled: { false }))
        defer { controller.hide() }
        let decision = PolicyDecision(isDistraction: true, reason: .safeByDefault)
        controller.show(decision: decision)
        let firstState = controller.state
        #expect(controller.surface?.flowerCount == 6)
        for second in 1...51 {
            fixture.date = Date(timeIntervalSince1970: 100 + Double(second))
            controller.show(decision: decision)
        }
        #expect(controller.state == firstState)
        #expect(controller.surface?.flowerCount == 24)
        #expect(controller.window?.ignoresMouseEvents == true)
        #expect(controller.window?.canBecomeKey == false)
        fixture.pid = nil
        controller.updateFrame()
        #expect(controller.window?.isVisible == false)
        #expect(controller.state == nil)
    }

    @Test func actualDimSurfacePaintsAndClearsWithoutAHostingTimeline() throws {
        let view = DistractionEffectView(frame: CGRect(x: 0, y: 0, width: 200, height: 160))
        let state = DistractionVisualState(effect: .dimBright, startedAt: Date(), seed: 1, ownerPID: 42)
        func alpha(at elapsed: Double) throws -> CGFloat {
            view.render(state: state, elapsed: elapsed, reduceMotion: false)
            let bitmap = try #require(view.bitmapImageRepForCachingDisplay(in: view.bounds))
            view.cacheDisplay(in: view.bounds, to: bitmap)
            return try #require(bitmap.colorAt(x: bitmap.pixelsWide / 2, y: bitmap.pixelsHigh / 2)).alphaComponent
        }
        #expect(try alpha(at: 4) > 0.3)
        #expect(try alpha(at: 8) < 0.01)
    }

    @Test func eachBatchAndEachLightTransitionHasOnlyOneCue() {
        var ice = DistractionSoundCursor()
        #expect(ice.advance(effect: .iceFlower, elapsed: 0, reduceMotion: false) == .freeze)
        #expect(ice.advance(effect: .iceFlower, elapsed: 1, reduceMotion: false) == nil)
        #expect(ice.advance(effect: .iceFlower, elapsed: 10, reduceMotion: false) == .freeze)
        #expect(ice.advance(effect: .iceFlower, elapsed: 10.1, reduceMotion: false) == nil)
        var dim = DistractionSoundCursor()
        #expect(dim.advance(effect: .dimBright, elapsed: 0, reduceMotion: false) == nil)
        #expect(dim.advance(effect: .dimBright, elapsed: 2, reduceMotion: false) == .lightSwitch)
        #expect(dim.advance(effect: .dimBright, elapsed: 2.1, reduceMotion: false) == nil)
        #expect(dim.advance(effect: .dimBright, elapsed: 6, reduceMotion: false) == .lightSwitch)
        #expect(dim.advance(effect: .dimBright, elapsed: 10, reduceMotion: true) == nil)
    }

    @Test func bothSoundsAreBundledAndDecodable() throws {
        for name in ["IceFreezingSound", "LightSwitchSound"] {
            let data = try #require(NSDataAsset(name: name)?.data)
            let player = try AVAudioPlayer(data: data)
            #expect(player.duration > 0.1)
        }
    }

    @Test func appLevelRulesSkipBrowserAutomation() {
        let chrome = "com.google.Chrome"
        var policy = SessionPolicy(mode: .allowing)
        #expect(!ForegroundActivityMonitor.requiresDomainLookup(bundleID: chrome, policy: policy))
        policy.allowedDomains.insert("example.com")
        #expect(ForegroundActivityMonitor.requiresDomainLookup(bundleID: chrome, policy: policy))
        policy.allowedApps.insert(chrome)
        #expect(!ForegroundActivityMonitor.requiresDomainLookup(bundleID: chrome, policy: policy))
        policy.mode = .blocking
        policy.blockedApps.insert(chrome)
        policy.blockedDomains.insert("example.com")
        #expect(!ForegroundActivityMonitor.requiresDomainLookup(bundleID: chrome, policy: policy))
    }

    @Test func unrelatedOccludingWindowIsExcludedFromTheVeil() throws {
        let view = DistractionEffectView(frame: CGRect(x: 0, y: 0, width: 200, height: 160))
        view.occludedRegions = [CGRect(x: 70, y: 50, width: 60, height: 60)]
        view.render(state: .init(effect: .dimBright, startedAt: Date(), seed: 1, ownerPID: 42),
                    elapsed: 4, reduceMotion: false)
        let bitmap = try #require(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: bitmap)
        let middle = try #require(bitmap.colorAt(x: bitmap.pixelsWide / 2, y: bitmap.pixelsHigh / 2))
        let edge = try #require(bitmap.colorAt(x: bitmap.pixelsWide / 8, y: bitmap.pixelsHigh / 2))
        #expect(middle.alphaComponent < 0.01)
        #expect(edge.alphaComponent > 0.3)
    }
}

@MainActor
private final class DistractionTestFixture {
    var pid: pid_t? = 42
    var date = Date(timeIntervalSince1970: 100)
}
