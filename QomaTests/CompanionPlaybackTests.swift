import SpriteKit
import Testing
@testable import Qoma

@MainActor
struct CompanionPlaybackTests {
    @Test func coveFishMoveWithoutMovingTheIslandAndRespectPauseAndReducedMotion() throws {
        let scene = CompanionScene()
        let fish = try #require(scene.childNode(withName: "swimmingFish-0") as? SKSpriteNode)
        let island = try #require(scene.childNode(withName: "floe"))
        #expect(fish.isHidden)
        scene.startSession()
        scene.advanceAnimation(by: 1.21)
        let start = fish.position
        let islandPosition = island.position
        scene.advanceAnimation(by: 0.5)
        #expect(fish.position != start)
        #expect(island.position == islandPosition)
        scene.setSessionPaused(true)
        let paused = fish.position
        scene.advanceAnimation(by: 1)
        #expect(fish.position == paused)
        scene.reduceMotion = true
        let reduced = fish.position
        scene.setSessionPaused(false)
        scene.advanceAnimation(by: 1)
        #expect(fish.position == reduced)
        scene.shutDown()
        #expect(fish.isHidden)
    }

    @Test func fishStayInOpenWaterThroughoutTheirCompleteRoutes() throws {
        let scene = CompanionScene(playback: CompanionPlayback(biteWait: { 600 }, reelTime: { 2 }))
        scene.startSession()
        for _ in 0..<3600 {
            scene.advanceAnimation(by: 1.0 / 30)
            for index in 0..<3 {
                let fish = try #require(scene.childNode(withName: "swimmingFish-\(index)") as? SKSpriteNode)
                // Includes half the sprite size, not just its center.
                #expect(fish.position.x - 7 >= 39)
                #expect(fish.position.x + 7 <= 91)
                #expect(fish.position.y - 5 >= 29)
                #expect(fish.position.y + 5 <= 50)
            }
        }
        let character = try #require(scene.childNode(withName: "//character"))
        #expect(abs((character.parent?.xScale ?? 0) - 0.78) < 0.0001)
    }

    private func fishing() -> CompanionPlayback {
        var model = CompanionPlayback(biteWait: { 6 }, reelTime: { 2 })
        model.start()
        model.advance(by: 1.21)
        return model
    }

    @Test func visualLandingDoesNotAwardAnUnpersistedCatch() {
        var model = self.fishing()
        model.biteNow()
        model.advance(by: 0.22 + 2 + 1.19)
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

    @Test func catchVariationDoesNotDependOnFrameIntervals() {
        var coarse = fishing()
        var fine = fishing()
        coarse.advance(by: 20)
        for _ in 0..<2000 { fine.advance(by: 0.01) }
        #expect(coarse.completedVisualCatches == 2)
        #expect(fine.completedVisualCatches == coarse.completedVisualCatches)
        #expect(coarse.depositedCatches == 0)
        #expect(fine.depositedCatches == 0)

        coarse.recordCatch(kindID: "anchovy")
        #expect(coarse.completedVisualCatches == 2)
        coarse.start()
        #expect(coarse.completedVisualCatches == 0)
    }

    @Test func catchDrawingsAdvanceInOrderAndHoldTheRewardPose() {
        var model = fishing()
        model.biteNow()
        var seen = Set<Int>()
        var previous = 0
        while model.phase == .bite || model.phase == .pulling {
            let frame = model.catchFrame
            #expect(frame >= previous)
            #expect(frame - previous <= 1)
            seen.insert(frame)
            previous = frame
            model.advance(by: 1.0 / 60)
        }
        #expect(seen == Set(0..<12))
        #expect(model.phase == .deposit)
        #expect(model.depositedCatches == 0)
    }

    @Test func reducedMotionKeepsTheNewCatchArtworkStill() throws {
        let scene = CompanionScene(playback: CompanionPlayback(biteWait: { 60 }, reelTime: { 1.5 }))
        scene.reduceMotion = true
        scene.startSession()
        scene.advanceAnimation(by: 1.21)
        let character = try #require(scene.childNode(withName: "//character") as? SKSpriteNode)
        let texture = character.texture
        let position = character.position
        scene.biteNow()
        scene.advanceAnimation(by: 1.2)
        #expect(character.texture === texture)
        #expect(character.position == position)
    }

    @Test func castingAndDepositPlayEveryDrawingWithoutAwardingItems() {
        var model = CompanionPlayback(biteWait: { 0.8 }, reelTime: { 1.5 })
        model.start()
        var cast = Set<Int>()
        var deposit = Set<Int>()
        for _ in 0..<360 {
            if model.phase == .casting { cast.insert(model.movementFrame) }
            if model.phase == .deposit { deposit.insert(model.movementFrame) }
            model.advance(by: 1.0 / 60)
        }
        #expect(cast == Set(0..<12))
        #expect(deposit == Set(0..<12))
        #expect(model.completedVisualCatches == 1)
        #expect(model.depositedCatches == 0)
    }

    @Test func depositRoutesCatchAboveHeadThenIntoBucket() throws {
        let scene = CompanionScene(playback: CompanionPlayback(biteWait: { 0.8 }, reelTime: { 1.5 }))
        scene.startSession()
        let catchNode = try #require(scene.childNode(withName: "//catch") as? SKSpriteNode)
        let bucket = try #require(scene.childNode(withName: "//bucket") as? SKSpriteNode)
        var checked = 0
        for _ in 0..<360 {
            if scene.playback.phase == .deposit, !catchNode.isHidden {
                let point = catchNode.position
                #expect(point.x < 35 || point.x > 110 || point.y > 115)
                if scene.playback.progress > 0.5 { #expect(point.x == bucket.position.x) }
                checked += 1
            }
            scene.advanceAnimation(by: 1.0 / 60)
        }
        #expect(checked > 30)
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
        model.recordCatch(kindID: "anchovy")
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
        let bucket = try #require(scene.childNode(withName: "//bucket") as? SKSpriteNode)
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
        #expect(floe.size.width == CompanionScene.stageSize.width)
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
        let catchNode = try #require(scene.childNode(withName: "//catch") as? SKSpriteNode)
        #expect(!catchNode.isHidden)
        let bucket = try #require(scene.childNode(withName: "//bucket") as? SKSpriteNode)
        #expect(catchNode.position.x == bucket.position.x)
        #expect(scene.playback.depositedCatches == 0)
        scene.advanceAnimation(by: 1.21)
        #expect(scene.playback.depositedCatches == 0)
        scene.recordCatch(kindID: "anchovy")
        #expect(scene.playback.depositedCatches == 1)
        #expect(scene.playback.phase == .casting)
    }
}
