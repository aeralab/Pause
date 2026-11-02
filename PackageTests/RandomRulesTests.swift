import XCTest
@testable import StopRules
final class RandomRulesTests: XCTestCase {
    func testRandomTaskSurvivesRestart() throws {
        var rng = SystemRandomNumberGenerator()
        let task = RecoveryTask.draw(after: nil, using: &rng)
        let state = LockState(startedAt: Date(timeIntervalSince1970: 0), taskID: task.id)
        let restored = try JSONDecoder().decode(LockState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored.id, state.id)
        XCTAssertEqual(restored.taskID, task.id)
        XCTAssertFalse(restored.canUnlock(at: Date(timeIntervalSince1970: 1799)))
        XCTAssertTrue(restored.canUnlock(at: Date(timeIntervalSince1970: 1800)))
    }
    func testNoRepeatedCategoryOverManyDraws() {
        var rng = SystemRandomNumberGenerator()
        var previous: TaskCategory?
        for _ in 0..<3000 {
            let task = RecoveryTask.draw(after: previous, using: &rng)
            XCTAssertNotEqual(previous, task.category)
            previous = task.category
        }
    }
    func testTaskTimingAndSuspension() {
        for task in RecoveryTask.all {
            var state = LockState(startedAt: Date(), taskID: task.id)
            state.credit(1000)
            XCTAssertEqual(state.creditedSeconds, 1.5)
            state.creditedSeconds = task.seconds - 0.5
            state.credit(0.4)
            XCTAssertFalse(state.canUnlock(at: state.startedAt))
            state.credit(0.2)
            XCTAssertTrue(state.canUnlock(at: state.startedAt))
        }
    }
}
