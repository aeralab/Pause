import XCTest

struct SeededGenerator: RandomNumberGenerator {
    var seed: UInt64
    mutating func next() -> UInt64 {
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        return seed
    }
}
final class RulesTests: XCTestCase {
    let start = Date(timeIntervalSince1970: 100000)
    func testWaitingBoundaryWithoutDoingTask() {
        let lock = LockState(startedAt: start, taskID: "literature")
        XCTAssertFalse(lock.canUnlock(at: start.addingTimeInterval(1799.999)))
        XCTAssertTrue(lock.canUnlock(at: start.addingTimeInterval(1800)))
    }
    func testEveryTaskRequiresItsEntireDuration() {
        for task in RecoveryTask.all {
            var lock = LockState(startedAt: start, taskID: task.id, creditedSeconds: task.seconds - 1)
            XCTAssertFalse(lock.canUnlock(at: start.addingTimeInterval(1)))
            lock.credit(1)
            XCTAssertTrue(lock.canUnlock(at: start.addingTimeInterval(1)))
        }
    }
    func testSuspensionAndInvalidDeltasDoNotCompleteTask() {
        var lock = LockState(startedAt: start, taskID: "arms")
        lock.credit(3600)
        XCTAssertEqual(lock.creditedSeconds, 1.5)
        lock.credit(-100); lock.credit(.nan); lock.credit(.infinity)
        XCTAssertEqual(lock.creditedSeconds, 1.5)
    }
    func testPersistenceKeepsAssignmentDeadlineAndIdentity() throws {
        let lock = LockState(startedAt: start, taskID: "face", creditedSeconds: 123)
        let restored = try JSONDecoder().decode(LockState.self, from: JSONEncoder().encode(lock))
        XCTAssertEqual(restored.id, lock.id)
        XCTAssertEqual(restored.taskID, "face")
        XCTAssertEqual(restored.creditedSeconds, 123)
        XCTAssertEqual(restored.waitEndsAt, start.addingTimeInterval(1800))
    }
    func testRandomCategoriesDoNotRepeatAndStayBalanced() {
        var rng = SeededGenerator(seed: 42)
        var previous: TaskCategory?
        var counts: [TaskCategory: Int] = [:]
        for _ in 0..<6000 {
            let task = RecoveryTask.draw(after: previous, using: &rng)
            XCTAssertNotEqual(task.category, previous)
            XCTAssertNotNil(RecoveryTask.find(task.id))
            counts[task.category, default: 0] += 1
            previous = task.category
        }
        for category in TaskCategory.allCases { XCTAssertTrue((1500...2500).contains(counts[category, default: 0])) }
    }
    func testInvalidTaskCannotUnlockEarly() {
        var lock = LockState(startedAt: start, taskID: "invalid", creditedSeconds: 9999)
        lock.credit(10)
        XCTAssertFalse(lock.canUnlock(at: start))
        XCTAssertTrue(lock.canUnlock(at: start.addingTimeInterval(1800)))
    }
}
