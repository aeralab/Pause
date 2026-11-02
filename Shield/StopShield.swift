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
            title: .init(text: task.map { "��һ�Σ�" + $0.title } ?? "����Ϣһ����", color: .label),
            subtitle: .init(text: "���������񼴿ɼ�����Ҳ���Դ�������ʼ�ȴ� 30 ���ӡ�", color: .secondaryLabel),
            primaryButtonLabel: .init(text: "ȥ Pause ��ʼ����", color: .systemBackground),
            primaryButtonBackgroundColor: .label,
            secondaryButtonLabel: .init(text: "�ȷ����ֻ�", color: .secondaryLabel)
        )
    }
    override func configuration(shielding application: Application) -> ShieldConfiguration { makeConfiguration() }
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration { makeConfiguration() }
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration { makeConfiguration() }
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration { makeConfiguration() }
}
