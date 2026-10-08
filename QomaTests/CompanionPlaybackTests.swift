import SpriteKit
import Testing
@testable import Qoma

@MainActor
struct CompanionPlaybackTests {
    private func fishing() -> CompanionPlayback {
        var model = CompanionPlayback(biteWait: { 6 }, reelTime: { 2 })
        model.start()
        model.advance(by: 1.21)
        return model
    }

    @Test func visualLandingDoesNotAwardAnUnpersistedCatch() {
        var model = self.fishing()
        model.biteNow()
        model.advance(by: 0.22 + 2 + 0.47)
        #expect(model.phase == .deposit)
        #expect(model.depositedCatches == 0)
        model.advance(by: 0.02)
        #expect(model.depositedCatches == 0)
        #expect(model.phase == .casting)
    }

    @Test func onlyPersistedCatchEventsUpdateCompanionRewardCount() {
        var model = self.fishing()
        model.advance(by: 0.1)
        model.recordCatch(kindID: "stick")
        #expect(model.depositedCatches == 1)
        #expect(model.catchIsTree)
    }

    @Test func distractionCancelsAnInflightCatchImmediately() {
        var model = self.fishing()
        model.biteNow()
        model.advance(by: 2.5)
        #expect(model.phase == .deposit)
        model.setDistracted(true)
        #expect(model.phase == .distracted)
        model.advance(by: 100)
        #expect(model.depositedCatches == 0)
        model.setDistracted(false)
        #expect(model.phase == .casting)
    }

    @Test func sleepTakesPrecedenceAndResumeHonorsDistraction() {
        var model = self.fishing()
        model.setPaused(true)
        model.setDistracted(true)
        model.advance(by: 20)
        #expect(model.phase == .sleeping)
        #expect(model.depositedCatches == 0)
        model.setPaused(false)
        #expect(model.phase == .distracted)
        model.setDistracted(false)
        #expect(model.phase == .casting)
    }

    @Test func earlyStopReturnsOnlyPersistedCatchesAndEventuallyHides() {
        var model = self.fishing()
        model.recordCatch(kindID: "anchovy")
        model.advance(by: 0.01)
        #expect(model.depositedCatches == 1)
        model.stop(activeSeconds: 299.9)
        #expect(model.phase == .releasing)
        #expect(model.releasedCatches == 1)
        #expect(model.depositedCatches == 0)
        model.advance(by: 1.2)
        #expect(model.phase == .hidden)
    }

    @Test func stopAtThresholdKeepsDepositedCatches() {
        var model = self.fishing()
        model.biteNow()
        model.advance(by: 2.71)
        model.stop(activeSeconds: 300)
        #expect(model.releasedCatches == 0)
        #expect(model.depositedCatches == 1)
    }

    @Test func completionCancelsPullingAndRestartClearsOldState() {
        var model = self.fishing()
        model.biteNow()
        model.advance(by: 1)
        model.complete()
        model.setPaused(true)
        model.setDistracted(true)
        model.advance(by: 100)
        #expect(model.phase == .completed)
        #expect(model.depositedCatches == 0)
        model.start()
        #expect(model.phase == .starting)
        #expect(model.depositedCatches == 0)
        #expect(!model.isPaused)
        #expect(!model.isDistracted)
    }

    @Test func stopBeforeFirstLandingDoesNotInventReturnedFish() {
        var model = self.fishing()
        model.biteNow()
        model.advance(by: 2.5)
        model.stop(activeSeconds: 20)
        #expect(model.releasedCatches == 0)
    }

    @Test func fixedSceneKeepsItsAnchorsAcrossCharacterStates() throws {
        let scene = CompanionScene()
        let floe = try #require(scene.childNode(withName: "floe") as? SKSpriteNode)
        let bucket = try #require(scene.childNode(withName: "bucket") as? SKSpriteNode)
        let floePosition = floe.position
        let bucketPosition = bucket.position
        let floeTexture = floe.texture
        scene.startSession()
        scene.advanceAnimation(by: 1.21)
        scene.setSessionPaused(true)
        #expect(floe.position == floePosition)
        #expect(bucket.position == bucketPosition)
        scene.setSessionPaused(false)
        scene.setDistracted(true)
        scene.advanceAnimation(by: 0.4)
        #expect(floe.position == floePosition)
        #expect(bucket.position == bucketPosition)
        scene.completeSession()
        #expect(floe.size.width == 118)
        #expect(floe.texture === floeTexture)
        #expect(bucket.position == bucketPosition)
    }

    @Test func reducedMotionStillShowsCatchBeforeLanding() throws {
        let scene = CompanionScene()
        scene.reduceMotion = true
        scene.startSession()
        scene.advanceAnimation(by: 1.21)
        scene.biteNow()
        for _ in 0..<700 {
            if scene.playback.phase == .deposit { break }
            scene.advanceAnimation(by: 0.01)
        }
        #expect(scene.playback.phase == .deposit)
        let catchNode = try #require(scene.childNode(withName: "catch") as? SKSpriteNode)
        #expect(!catchNode.isHidden)
        #expect(catchNode.position.x == 113)
        #expect(scene.playback.depositedCatches == 0)
        scene.advanceAnimation(by: 0.5)
        #expect(scene.playback.depositedCatches == 1)
        #expect(scene.playback.phase == .casting)
    }
}
