import ManagedSettings
import ManagedSettingsUI
import UIKit

final class StopShield: ShieldConfigurationDataSource {
    private func makeConfiguration() -> ShieldConfiguration {
        let lock = try? StopRepository.shared.snapshot().lock
        let task = lock?.task
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: .systemBackground,
            icon: UIImage(systemName: task?.symbol ?? "pause.circle"),
            title: .init(text: task.map { "这一次，" + $0.title } ?? "该休息一下了", color: .label),
            subtitle: .init(text: "完成随机任务即可继续，也可以从锁定开始等待 30 分钟。", color: .secondaryLabel),
            primaryButtonLabel: .init(text: "去 Pause 开始任务", color: .systemBackground),
            primaryButtonBackgroundColor: .label,
            secondaryButtonLabel: .init(text: "先放下手机", color: .secondaryLabel)
        )
    }
    override func configuration(shielding application: Application) -> ShieldConfiguration { makeConfiguration() }
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration { makeConfiguration() }
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration { makeConfiguration() }
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration { makeConfiguration() }
}
