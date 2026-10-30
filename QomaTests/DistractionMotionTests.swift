import Testing
@testable import Qoma

struct DistractionMotionTests {
    @Test func flowersGrowDenselyWithWindowAreaAndStayBounded() {
        #expect(DistractionMotion.iceFlowerCount(elapsed: 0) == 30)
        #expect(DistractionMotion.iceFlowerCount(elapsed: 9.9) == 30)
        #expect(DistractionMotion.iceFlowerCount(elapsed: 10) == 48)
        #expect(DistractionMotion.iceFlowerCount(elapsed: 40) == 102)
        #expect(DistractionMotion.iceFlowerCount(elapsed: 50) == 117)
        #expect(DistractionMotion.iceFlowerCount(elapsed: 500) == 117)
        #expect(DistractionMotion.iceFlowerCount(elapsed: 500, area: 600 * 400) == 48)
        #expect(DistractionMotion.iceFlowerCount(elapsed: 500, area: 3840 * 2160) == 180)
        #expect(DistractionMotion.iceFlowerCount(elapsed: -1, area: 0) == 6)
    }

    @Test(arguments: DistractionEffect.allCases)
    func penguinUsesTwelveWholeDrawingsAndReducedMotionHoldsStill(effect: DistractionEffect) {
        var frames = Set<Int>()
        for tick in 0..<240 {
            let elapsed = Double(tick) / 30
            let frame = DistractionMotion.penguinFrame(effect: effect, elapsed: elapsed, reduceMotion: false)
            #expect((0..<12).contains(frame))
            frames.insert(frame)
            #expect(DistractionMotion.penguinFrame(effect: effect, elapsed: elapsed, reduceMotion: true) == 0)
        }
        #expect(frames == Set(0..<12))
        #expect(DistractionMotion.penguinFrame(effect: effect, elapsed: -1, reduceMotion: false) == 0)
        #expect(DistractionMotion.penguinFrame(effect: effect, elapsed: .infinity, reduceMotion: false) == 0)
    }

    @Test func dimmingStartsBrightAndReturnsBrightAtCycleBoundary() {
        #expect(DistractionMotion.dimStrength(elapsed: 0) == 0)
        #expect(DistractionMotion.dimStrength(elapsed: 4) > 0.99)
        #expect(DistractionMotion.dimStrength(elapsed: 8) < 0.0001)
        #expect(DistractionMotion.dimPhase(elapsed: 8 + 3.75) > 0.49)
        #expect(DistractionMotion.dimPhase(elapsed: 8 + 3.75) < 0.51)
    }

    @Test func dimmingEventuallyReachesThreeSecondCycle() {
        #expect(DistractionMotion.dimPhase(elapsed: 60) >= 0)
        #expect(DistractionMotion.dimPhase(elapsed: 60) < 1)
        #expect(DistractionMotion.dimPhase(elapsed: 100) == DistractionMotion.dimPhase(elapsed: 103))
    }

    @Test func drawnPressMatchesSoundBeatsAndConnectingDrawingsAdvanceInOrder() {
        for click in [2.0, 6.0, 9.875] {
            #expect(DistractionMotion.penguinFrame(effect: .dimBright, elapsed: click, reduceMotion: false) == 6)
            for drawing in 0..<12 {
                let time = click - 0.5 + (Double(drawing) + 0.1) / 12
                #expect(DistractionMotion.penguinFrame(effect: .dimBright, elapsed: time, reduceMotion: false) == drawing)
            }
        }
        for effect in [DistractionEffect.iceFlower, .snowstorm] {
            for drawing in 0..<12 {
                let extraHold = effect == .snowstorm && drawing >= 7 ? 11.0 / 12 : 0
                let time = 0.3 + (Double(drawing) + 0.1) / 12 + extraHold
                #expect(DistractionMotion.penguinFrame(effect: effect, elapsed: time, reduceMotion: false) == drawing)
            }
        }
    }

    @Test func hopMovesTheWholeDrawingAndKeepsReducedMotionGrounded() {
        #expect(DistractionMotion.penguinLift(effect: .iceFlower, elapsed: 0, reduceMotion: false) == 0)
        #expect(DistractionMotion.penguinLift(effect: .iceFlower, elapsed: 0.85, reduceMotion: false) > 9)
        for effect in DistractionEffect.allCases {
            #expect(DistractionMotion.penguinLift(effect: effect, elapsed: 0.85, reduceMotion: true) == 0)
        }
    }
}
