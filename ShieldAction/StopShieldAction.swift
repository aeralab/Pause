import ManagedSettings

final class StopShieldAction: ShieldActionDelegate {
    private func respond(_ action: ShieldAction, completion: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            if #available(iOS 26.5, *) { completion(.openParentalControlsApp) }
            else { completion(.close) }
        case .secondaryButtonPressed: completion(.close)
        @unknown default: completion(.close)
        }
    }
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(action, completion: completionHandler)
    }
    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(action, completion: completionHandler)
    }
    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(action, completion: completionHandler)
    }
}
