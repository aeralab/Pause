import Foundation
import FamilyControls
import Darwin

struct StopState: Codable {
    var version = 2
    var enabled = false
    var selection = FamilyActivitySelection()
    var cycleID: String?
    var cycleEndsAt: Date?
    var cooldownID: String?
    var lock: LockState?
    var previousCategory: TaskCategory?
    var history: [StopEvent] = []
    var lastError: String?
    var hasSelection: Bool {
        !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty || !selection.webDomainTokens.isEmpty
    }
    mutating func record(_ text: String) {
        history.insert(StopEvent(at: Date(), text: text), at: 0)
        history = Array(history.prefix(100))
    }
}
enum StopFailure: LocalizedError {
    case unavailableGroup, busy, invalidState, authorization, emptySelection, alreadyActive
    var errorDescription: String? {
        switch self {
        case .unavailableGroup: return "�������������ã������� App ����չ�� App Group ǩ����"
        case .busy: return "�������ڸ��£����Ժ����ԡ�"
        case .invalidState: return "�����޷���ȡ���ѱ���ԭ�ļ������ȼ�鰲װ����־��"
        case .authorization: return "������Ȩ��Ļʹ��ʱ�䡣"
        case .emptySelection: return "������ѡ��һ����Ҫ���Ƶ� App ����վ��"
        case .alreadyActive: return "���������á�������������ͣ�ã��������õ�ǰ��ʱ��"
        }
    }
}
final class StopRepository {
    static let shared = StopRepository()
    static let group = "group.com.onepersoncompany.stop"
    func withState<T>(_ operation: (inout StopState) throws -> T) throws -> T {
        guard let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.group) else { throw StopFailure.unavailableGroup }
        let fd = open(directory.appendingPathComponent("state.lock").path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard fd >= 0 else { throw StopFailure.unavailableGroup }
        defer { close(fd) }
        var acquired = false
        for _ in 0..<40 {
            if flock(fd, LOCK_EX | LOCK_NB) == 0 { acquired = true; break }
            usleep(10_000)
        }
        guard acquired else { throw StopFailure.busy }
        defer { flock(fd, LOCK_UN) }
        let file = directory.appendingPathComponent("state-v2.json")
        var state: StopState
        if FileManager.default.fileExists(atPath: file.path) {
            guard let data = try? Data(contentsOf: file), let decoded = try? JSONDecoder().decode(StopState.self, from: data), decoded.version == 2 else { throw StopFailure.invalidState }
            state = decoded
        } else { state = StopState() }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let before = try encoder.encode(state)
        let result = try operation(&state)
        let after = try encoder.encode(state)
        if before != after || !FileManager.default.fileExists(atPath: file.path) {
            try after.write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        }
        return result
    }
    func snapshot() throws -> StopState { try withState { $0 } }
}
