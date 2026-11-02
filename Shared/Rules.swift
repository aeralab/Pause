import Foundation

enum TaskCategory: String, Codable, CaseIterable {
    case reading, movement, face
    var title: String {
        switch self { case .reading: return "�Ķ�"; case .movement: return "�����˶�"; case .face: return "�沿�٤" }
    }
}
struct RecoveryTask: Identifiable {
    let id: String
    let title: String
    let minutes: Int
    let category: TaskCategory
    let symbol: String
    var seconds: TimeInterval { TimeInterval(minutes * 60) }
    static let all: [RecoveryTask] = [
        .init(id: "literature", title: "��ѧ�Ķ�", minutes: 10, category: .reading, symbol: "book.closed"),
        .init(id: "history", title: "��ʷ�Ķ�", minutes: 10, category: .reading, symbol: "book.closed"),
        .init(id: "philosophy", title: "��ѧ�Ķ�", minutes: 10, category: .reading, symbol: "book.closed"),
        .init(id: "science", title: "��ѧ�Ķ�", minutes: 10, category: .reading, symbol: "book.closed"),
        .init(id: "eyeCare", title: "�۱�����", minutes: 5, category: .movement, symbol: "eye"),
        .init(id: "eyes", title: "�۲�����", minutes: 10, category: .movement, symbol: "eye"),
        .init(id: "face", title: "�沿�٤", minutes: 10, category: .face, symbol: "face.smiling"),
        .init(id: "squats", title: "�¶�", minutes: 5, category: .movement, symbol: "figure.strengthtraining.functional"),
        .init(id: "arms", title: "�ֱۻ", minutes: 5, category: .movement, symbol: "figure.flexibility"),
        .init(id: "back", title: "�����", minutes: 5, category: .movement, symbol: "figure.flexibility"),
        .init(id: "legs", title: "�Ȳ��", minutes: 5, category: .movement, symbol: "figure.walk"),
        .init(id: "waist", title: "��������", minutes: 5, category: .movement, symbol: "figure.cooldown")
    ]
    static func find(_ id: String) -> RecoveryTask? { all.first { $0.id == id } }
    static func draw<R: RandomNumberGenerator>(after previous: TaskCategory?, using rng: inout R) -> RecoveryTask {
        let category = TaskCategory.allCases.filter { $0 != previous }.randomElement(using: &rng)!
        return all.filter { $0.category == category }.randomElement(using: &rng)!
    }
}
struct LockState: Codable, Identifiable {
    var id = UUID()
    let startedAt: Date
    let taskID: String
    var creditedSeconds: TimeInterval = 0
    var task: RecoveryTask? { RecoveryTask.find(taskID) }
    var waitEndsAt: Date { startedAt.addingTimeInterval(30 * 60) }
    func canUnlock(at now: Date) -> Bool {
        if now >= waitEndsAt { return true }
        guard let task else { return false }
        return creditedSeconds.isFinite && creditedSeconds >= task.seconds
    }
    mutating func credit(_ seconds: TimeInterval) {
        guard seconds.isFinite, seconds > 0, let task else { return }
        creditedSeconds = min(task.seconds, max(0, creditedSeconds) + min(seconds, 1.5))
    }
}
struct StopEvent: Codable, Identifiable {
    var id = UUID()
    let at: Date
    let text: String
}
