import Testing
@testable import Qoma

struct DistractionMotionTests {
    @Test func crystalBloomTurnsSlowlyInBothDirectionsAndRespectsReducedMotion() {
        let clockwise = DistractionMotion.crystalBloom(index: 0, age: 12, reduceMotion: false)
        let counterclockwise = DistractionMotion.crystalBloom(index: 1, age: 12, reduceMotion: false)
        #expect(abs(clockwise.rotation - .pi / 2) < 0.0001)
        #expect(counterclockwise.rotation < 0)
        #expect((0.94...1).contains(clockwise.opacity))
        let still = DistractionMotion.crystalBloom(index: 1, age: 12, reduceMotion: true)
        #expect(still.rotation == 0 && still.opacity == 1)
    }

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
            #expect(DistractionMotion.penguinFrame(effect: effect, elapsed: elapsed, reduceMotion: true) == (effect == .iceFlower ? 2 : 0))
        }
        #expect(frames == Set(0..<(effect == .iceFlower ? 11 : 12)))
        #expect(DistractionMotion.penguinFrame(effect: effect, elapsed: -1, reduceMotion: false) == 0)
        #expect(DistractionMotion.penguinFrame(effect: effect, elapsed: .infinity, reduceMotion: false) == (effect == .iceFlower ? 2 : 0))
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
        for (click, frame) in [(1.2, 3), (5.6, 9), (9.125, 3)] {
            #expect(DistractionMotion.penguinFrame(effect: .dimBright, elapsed: click, reduceMotion: false) == frame)
            #expect(DistractionMotion.penguinFrame(effect: .dimBright, elapsed: click - 0.01, reduceMotion: false) == frame - 1)
        }
        for effect in [DistractionEffect.snowstorm] {
            for drawing in 0..<12 {
                let extraHold = effect == .snowstorm && drawing >= 7 ? 11.0 / 12 : 0
                let time = 0.3 + (Double(drawing) + 0.1) / 12 + extraHold
                #expect(DistractionMotion.penguinFrame(effect: effect, elapsed: time, reduceMotion: false) == drawing)
            }
        }
    }

    @Test func flowersAppearOnFirstBreathFrame() {
        for (index, time) in [(0, 0.5), (30, 10.5)] {
            #expect(DistractionMotion.iceFlowerBirth(index: index, area: 900 * 650) == time)
            #expect(DistractionMotion.penguinFrame(effect: .iceFlower, elapsed: time, reduceMotion: false) == 6)
        }
    }
}
