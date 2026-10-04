import Testing
@testable import Qoma

struct DistractionMotionTests {
    @Test func iceFlowersGrowEveryTenSecondsAndStopAtTwentyFour() {
        #expect(DistractionMotion.iceFlowerCount(elapsed: 0) == 6)
        #expect(DistractionMotion.iceFlowerCount(elapsed: 9.9) == 6)
        #expect(DistractionMotion.iceFlowerCount(elapsed: 10) == 10)
        #expect(DistractionMotion.iceFlowerCount(elapsed: 40) == 22)
        #expect(DistractionMotion.iceFlowerCount(elapsed: 50) == 24)
        #expect(DistractionMotion.iceFlowerCount(elapsed: 500) == 24)
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
}
