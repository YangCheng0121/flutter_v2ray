import Flutter
import NetworkExtension

public class VPNConfigValidator {
    // 单例
    private static var sharedVPNConfigValidator: VPNConfigValidator = .init()
    public class func shared() -> VPNConfigValidator {
        return sharedVPNConfigValidator
    }

    public typealias VpnStatusChangeCallback = (Bool) -> Void

    // 优化点1：更精确的状态判断
    private func checkConnectionStatus(_ manager: NETunnelProviderManager?) -> Bool {
        guard let connection = manager?.connection else { return false }
        return [.connected, .connecting, .reasserting, .disconnecting].contains(connection.status)
//        return [.connected].contains(connection.status)
    }

    /// 优化点2：移除信号量 + 简化判断逻辑
    public func checkInitialState(changeHandler: @escaping VpnStatusChangeCallback) {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            // 优化点3：添加错误处理
            guard error == nil else {
                print("配置加载错误: \(error!.localizedDescription)")
                changeHandler(false)
                return
            }

            // 合并配置有效性检查
            let validManagers = managers?.filter {
                ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == AppConfigs.BUNDLE_IDENTIFIER
            } ?? []

            // 查找第一个激活的有效配置
            guard let activeManager = validManagers.first(where: { $0.isEnabled }) else {
                changeHandler(false)
                return
            }

            // 最终状态 = 连接状态
            let isValid = self?.checkConnectionStatus(activeManager) ?? false
            print("当前有效状态: \(isValid)")
            changeHandler(isValid)
        }
    }
}
