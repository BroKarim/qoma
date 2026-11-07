import AppKit
import AVFoundation
import SpriteKit
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
        #expect(controller.surface?.flowerCount == 12)
        for second in 1...51 {
            fixture.date = Date(timeIntervalSince1970: 100 + Double(second))
            controller.show(decision: decision)
        }
        #expect(controller.state == firstState)
        #expect(controller.surface?.flowerCount == 48)
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
        #expect(try alpha(at: 4) > 0.8)
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
        var storm = DistractionSoundCursor()
        #expect(storm.advance(effect: .snowstorm, elapsed: 0, reduceMotion: false) == nil)
        #expect(storm.advance(effect: .snowstorm, elapsed: 20, reduceMotion: false) == nil)
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
        #expect(edge.alphaComponent > 0.8)
    }

    @Test func illustratedEffectsAreBundledAndDrawWithoutLeakingIntoOcclusions() throws {
        for name in (1...6).map({ "DistractionIceFlower\($0)" })
            + (1...6).map({ "DistractionSnow\($0)" })
            + ["DistractionWind", "DistractionSnowbank", "CompanionDistractionLightsV3",
               "CompanionDistractionIceV3", "CompanionDistractionSnowV3"] {
            let image = try #require(NSImage(named: name))
            #expect(image.size.width > 0)
        }
        for effect in [DistractionEffect.iceFlower, .snowstorm] {
            let view = DistractionEffectView(frame: CGRect(x: 0, y: 0, width: 600, height: 400))
            view.occludedRegions = [CGRect(x: 200, y: 150, width: 200, height: 100)]
            view.render(state: .init(effect: effect, startedAt: Date(), seed: 1, ownerPID: 42),
                        elapsed: 51, reduceMotion: false)
            let bitmap = try #require(view.bitmapImageRepForCachingDisplay(in: view.bounds))
            view.cacheDisplay(in: view.bounds, to: bitmap)
            let center = try #require(bitmap.colorAt(x: bitmap.pixelsWide / 2, y: bitmap.pixelsHigh / 2))
            #expect(center.alphaComponent < 0.01)
            var painted = 0
            for x in stride(from: 20, to: bitmap.pixelsWide - 20, by: 20) {
                for y in stride(from: 20, to: bitmap.pixelsHigh - 20, by: 20) {
                    if (bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.1 { painted += 1 }
                }
            }
            #expect(painted > 0)
        }
    }

    @Test func resizedWindowsChangeDensityAndReducedMotionStopsStormGrowth() {
        let view = DistractionEffectView(frame: CGRect(x: 0, y: 0, width: 600, height: 400))
        let ice = DistractionVisualState(effect: .iceFlower, startedAt: Date(), seed: 1, ownerPID: 42)
        view.render(state: ice, elapsed: 51, reduceMotion: false)
        #expect(view.flowerCount == 48)
        view.setFrameSize(CGSize(width: 900, height: 650))
        view.render(state: ice, elapsed: 51, reduceMotion: false)
        #expect(view.flowerCount == 117)
        let storm = DistractionVisualState(effect: .snowstorm, startedAt: Date(), seed: 1, ownerPID: 42)
        view.render(state: storm, elapsed: 100, reduceMotion: false)
        #expect(view.snowCount == 30)
        view.render(state: storm, elapsed: 100, reduceMotion: true)
        #expect(view.snowCount == 18)
    }

    @Test(arguments: DistractionEffect.allCases)
    func penguinFramesFollowEpisodeClockAndResetAfterDistraction(effect: DistractionEffect) throws {
        let scene = CompanionScene()
        scene.startSession()
        scene.advanceAnimation(by: 1.21)
        let character = try #require(scene.childNode(withName: "//character") as? SKSpriteNode)
        let fishingTexture = try #require(character.texture)
        scene.visualNow = { Date(timeIntervalSince1970: 100) }
        scene.setDistractionVisual(.init(
            effect: effect, startedAt: Date(timeIntervalSince1970: 100), seed: 1, ownerPID: 42))
        let restTexture = try #require(character.texture)
        #expect(restTexture !== fishingTexture)
        let anchor = character.anchorPoint
        let position = character.position
        let elapsed: Double = switch effect {
        case .dimBright: 2
        case .iceFlower: 0.65
        case .snowstorm: 1.7
        }
        scene.visualNow = { Date(timeIntervalSince1970: 100 + elapsed) }
        scene.advanceAnimation(by: 0.01)
        #expect(character.texture !== restTexture)
        if effect == .iceFlower {
            #expect(character.position.y > position.y)
        } else {
            #expect(character.position == position)
        }
        #expect(character.children.isEmpty, "Distraction illustrations must stay whole, without a body-part rig")
        #expect(scene.childNode(withName: "lightSwitch") == nil)
        #expect(character.anchorPoint == anchor)
        scene.reduceMotion = true
        #expect(character.texture === restTexture)
        scene.setDistractionVisual(nil)
        #expect(scene.playback.phase == .casting)
        #expect(character.texture !== restTexture)
        #expect(character.anchorPoint != anchor)
    }

    @Test(arguments: [0, 3, 8])
    func transparentCompanionPanelDoesNotPunchABrightRectangle(targetLevel: Int) throws {
        let frame = CGRect(x: 50, y: 50, width: 600, height: 400)
        let panel = NSPanel(
            contentRect: CGRect(x: 400, y: 100, width: 140, height: 140),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.level = .floating
        panel.orderFrontRegardless()
        let controller = DistractionOverlayController(
            frontmostPID: { 42 },
            locate: { DistractionTargetWindow(number: 0, ownerPID: $0, level: targetLevel, frame: frame) },
            now: { Date(timeIntervalSince1970: 100) }, chooseEffect: { .dimBright },
            audio: DistractionAudioPlayer(enabled: { false }))
        defer { controller.hide(); panel.orderOut(nil) }
        controller.show(decision: .init(isDistraction: true, reason: .safeByDefault))
        let surface = try #require(controller.surface)
        let state = try #require(controller.state)
        surface.render(state: state, elapsed: 4, reduceMotion: false)
        let bitmap = try #require(surface.bitmapImageRepForCachingDisplay(in: surface.bounds))
        surface.cacheDisplay(in: surface.bounds, to: bitmap)
        let scale = CGFloat(bitmap.pixelsWide) / surface.bounds.width
        let pixel = try #require(bitmap.colorAt(
            x: Int((panel.frame.minX - frame.minX + 5) * scale),
            y: Int((frame.maxY - panel.frame.maxY + 5) * scale)))
        #expect(pixel.alphaComponent > 0.8, "Transparent panel pixels must still have the dark veil underneath")
        let overlay = try #require(controller.window)
        #expect(panel.level.rawValue > overlay.level.rawValue)
        controller.hide()
        #expect(panel.level == .floating)
    }

    @Test func wholeDrawingBreathesBetweenIllustratedFrames() throws {
        let scene = CompanionScene()
        scene.startSession()
        scene.visualNow = { Date(timeIntervalSince1970: 101.35) }
        scene.setDistractionVisual(.init(
            effect: .dimBright, startedAt: Date(timeIntervalSince1970: 100), seed: 1, ownerPID: 42))
        let character = try #require(scene.childNode(withName: "//character") as? SKSpriteNode)
        let position = character.position
        let rotation = character.zRotation
        let scale = character.yScale
        scene.visualNow = { Date(timeIntervalSince1970: 101.35 + 1.0 / 60) }
        scene.advanceAnimation(by: 1.0 / 60)
        #expect(character.position != position || character.zRotation != rotation || character.yScale != scale)
    }
}

@MainActor
private final class DistractionTestFixture {
    var pid: pid_t? = 42
    var date = Date(timeIntervalSince1970: 100)
}
