import Foundation

// import Libv2ray

// V2rayController 类用于管理 V2Ray 的初始化、启动、停止和状态获取
class V2rayController {
    // 初始化 V2Ray
    static func initV2ray(appIcon: Int, appName: String) {
        // 复制资源文件
        Utilities.copyAssets()
        AppConfigs.APPLICATION_ICON = appIcon
        AppConfigs.APPLICATION_NAME = appName

        // 注册广播接收器以接收 V2Ray 状态更新
        let receiver = NotificationCenter.default
        receiver.addObserver(forName: NSNotification.Name("V2RAY_CONNECTION_INFO"), object: nil, queue: nil) { notification in
            // 从通知中获取 V2Ray 状态
            if let state = notification.userInfo?["STATE"] as? AppConfigs.V2RAY_STATES {
                AppConfigs.V2RAY_STATE = state
            }
        }
    }

    // 启动 V2Ray
    static func startV2ray(remark: String, config: String, blockedApps: [String], bypassSubnets: [String]) {
        // 解析 V2Ray 配置
        AppConfigs.V2RAY_CONFIG = Utilities.parseV2rayJsonFile(remark: remark, config: config, blockedApplication: blockedApps, bypassSubnets: bypassSubnets)

        guard let v2rayConfig = AppConfigs.V2RAY_CONFIG else {
            return // 如果配置无效，返回
        }
        // 根据连接模式选择相应的服务
        let connectionMode = AppConfigs.V2RAY_CONNECTION_MODE
        let command: String

        switch connectionMode {
        case .PROXY_ONLY:
            // 启动代理服务
            command = "START_PROXY_SERVICE"
        case .VPN_TUN:
            // 启动 VPN 服务
            command = "START_VPN_SERVICE"
        }

        // 准备启动服务的参数
        // 假设有一个方法来启动后台任务
        startBackgroundTask(command: command, v2rayConfig: v2rayConfig)
    }

    // 启动后台任务的示例方法
    static func startBackgroundTask(command: String, v2rayConfig: Any) {
        V2rayCoreManager.shared.setUpListener();
        // 这里可以实现具体的后台启动逻辑
        // 例如，使用 URLSession、DispatchQueue等来启动后台网络连接
        // 打印自己的类名
//        print("当前类名: \(String(describing: self))")
//        print("启动服务命令: \(command), 配置: \(v2rayConfig)")
        // 实际的启动代码...
    }
}
