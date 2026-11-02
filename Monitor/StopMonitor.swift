import DeviceActivity

final class StopMonitor: DeviceActivityMonitor {
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        guard event.rawValue == "twentyMinutes" else { return }
        ScreenTime.shared.reachedThreshold(activity: activity.rawValue)
    }
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        ScreenTime.shared.intervalEnded(activity.rawValue)
    }
}
