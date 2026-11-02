import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings
import OSLog

final class ScreenTime {
    static let shared = ScreenTime()
    private let repository = StopRepository.shared
    private let center = DeviceActivityCenter()
    private let store = ManagedSettingsStore(named: .init("stop"))
    private let logger = Logger(subsystem: "com.onepersoncompany.stop", category: "monitor")
    private func schedule(from start: Date, to end: Date) -> DeviceActivitySchedule {
        let parts: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        return .init(intervalStart: Calendar.current.dateComponents(parts, from: start), intervalEnd: Calendar.current.dateComponents(parts, from: end), repeats: false)
    }
    func enable(selection: FamilyActivitySelection) throws {
        guard AuthorizationCenter.shared.authorizationStatus == .approved else { throw StopFailure.authorization }
        try repository.withState { state in
            guard !state.enabled, state.lock == nil else { throw StopFailure.alreadyActive }
            state.selection = selection
            guard state.hasSelection else { throw StopFailure.emptySelection }
            state.enabled = true; state.lastError = nil
            armUsage(&state)
            state.record(state.cycleID == nil ? "启用未完成，等待重试" : "已启用：累计使用 20 分钟后休息")
        }
    }
    private func armUsage(_ state: inout StopState) {
        guard state.enabled, state.lock == nil, state.hasSelection else { return }
        let name = "use-" + UUID().uuidString
        let now = Date(), end = Date().addingTimeInterval(24 * 3600)
        let event = DeviceActivityEvent(applications: state.selection.applicationTokens,
            categories: state.selection.categoryTokens, webDomains: state.selection.webDomainTokens,
            threshold: DateComponents(minute: 20), includesPastActivity: false)
        do {
            try center.startMonitoring(.init(name), during: schedule(from: now, to: end), events: [.init("twentyMinutes"): event])
            let old = state.cycleID
            state.cycleID = name; state.cycleEndsAt = end; state.lastError = nil
            if let old { center.stopMonitoring([.init(old)]) }
        } catch { state.lastError = "使用监控未启动：" + error.localizedDescription }
    }
    private func applyShield(_ state: StopState) {
        store.shield.applications = state.selection.applicationTokens
        store.shield.applicationCategories = state.selection.categoryTokens.isEmpty ? nil : .specific(state.selection.categoryTokens)
        store.shield.webDomains = state.selection.webDomainTokens
        store.shield.webDomainCategories = state.selection.categoryTokens.isEmpty ? nil : .specific(state.selection.categoryTokens)
    }
    private func armCooldown(_ state: inout StopState) {
        guard let lock = state.lock, lock.waitEndsAt > Date() else { return }
        if let id = state.cooldownID, center.activities.contains(.init(id)) { return }
        state.cooldownID = nil
        let name = "rest-" + UUID().uuidString
        do {
            try center.startMonitoring(.init(name), during: schedule(from: lock.startedAt, to: lock.waitEndsAt))
            state.cooldownID = name; state.lastError = nil
        } catch { state.lastError = "后台休息监控未启动，请到时打开 Stop 恢复：" + error.localizedDescription }
    }
    func reachedThreshold(activity: String) {
        performInExtension { state in
            guard state.enabled, activity == state.cycleID, state.lock == nil else { return }
            var rng = SystemRandomNumberGenerator()
            let task = RecoveryTask.draw(after: state.previousCategory, using: &rng)
            state.lock = LockState(startedAt: Date(), taskID: task.id)
            state.previousCategory = task.category
            applyShield(state)
            state.record("累计使用 20 分钟，分配任务：" + task.title)
            armCooldown(&state)
        }
    }
    private func unlockIfEligible(_ state: inout StopState) {
        guard let lock = state.lock, lock.canUnlock(at: Date()) else { return }
        let reason = Date() >= lock.waitEndsAt ? "等待 30 分钟，已解锁" : "完成" + (lock.task?.title ?? "任务") + "，已解锁"
        let cooldown = state.cooldownID, cycle = state.cycleID
        state.lock = nil; state.cooldownID = nil; state.cycleID = nil; state.cycleEndsAt = nil
        store.clearAllSettings()
        if let cooldown { center.stopMonitoring([.init(cooldown)]) }
        if let cycle { center.stopMonitoring([.init(cycle)]) }
        state.record(reason)
        armUsage(&state)
    }
    func reconcile() throws -> StopState {
        try repository.withState { state in
            guard state.enabled else { return state }
            guard AuthorizationCenter.shared.authorizationStatus == .approved else {
                state.enabled = false; state.lock = nil; state.cycleID = nil; state.cooldownID = nil; state.cycleEndsAt = nil
                center.stopMonitoring(); store.clearAllSettings()
                state.lastError = "屏幕使用时间授权已撤销，限制已停用。"
                state.record("授权已撤销")
                return state
            }
            if let lock = state.lock {
                if lock.canUnlock(at: Date()) { unlockIfEligible(&state) }
                else { applyShield(state); armCooldown(&state) }
            } else if state.cycleID == nil || state.cycleEndsAt.map({ $0 <= Date() }) == true || !center.activities.contains(.init(state.cycleID!)) {
                armUsage(&state)
            }
            return state
        }
    }
    func credit(seconds: TimeInterval, lockID: UUID) throws -> StopState {
        try repository.withState { state in
            guard var lock = state.lock, lock.id == lockID else { return state }
            lock.credit(seconds); state.lock = lock
            unlockIfEligible(&state)
            return state
        }
    }
    func disable() throws {
        try repository.withState { state in
            state.enabled = false; state.lock = nil; state.cycleID = nil; state.cooldownID = nil; state.cycleEndsAt = nil; state.lastError = nil
            center.stopMonitoring(); store.clearAllSettings(); state.record("手动停用限制")
        }
    }
    func intervalEnded(_ name: String) {
        performInExtension { state in
            guard state.enabled else { return }
            if name == state.cooldownID {
                if let lock = state.lock, Date() >= lock.waitEndsAt { unlockIfEligible(&state) }
            } else if name == state.cycleID, state.lock == nil {
                guard let end = state.cycleEndsAt, Date() >= end else { return }
                armUsage(&state)
            }
        }
    }
    private func performInExtension(_ action: (inout StopState) -> Void) {
        do { try repository.withState(action) }
        catch { logger.error("Stop state update failed: \(error.localizedDescription, privacy: .public)") }
    }
}
