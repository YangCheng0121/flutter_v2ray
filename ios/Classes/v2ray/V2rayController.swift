import Flutter
import NetworkExtension
import os.log

let conLog = OSLog(subsystem: "com.group.sulian.app", category: "vpn_controller")

public class V2rayController {
    private lazy var pligun = FlutterV2rayPlugin.shared()

    // 单例
    private static var sharedV2rayController: V2rayController = .init()
    public class func shared() -> V2rayController {
        return sharedV2rayController
    }

    // V2ray Core
    private lazy var coreManager: V2rayCoreManager = .shared()
    private var manager = NETunnelProviderManager.shared()

//    public init() {
//        VPNConfigValidator.checkInitialState()
//    }

    public func initializeV2Ray(result: @escaping FlutterResult) {
        // 获取 V2RAY_STATE 的字符串表示
        let connectStatus = AppConfigs.V2RAY_STATE.description
        let stats = V2RayStats.defaultStats()

        pligun.sendEventToFlutter([
            stats.time,
            stats.uploadSpeed,
            stats.downloadSpeed,
            stats.totalUpload,
            stats.totalDownload,
            connectStatus // 当前状态
        ])

        result(nil)
    }

    // 启动 V2ray
    public func startV2Ray(remark: String, config: String, blockedApps: [String], bypassSubnets: [String], proxyOnly: Bool, result: @escaping FlutterResult) {
        coreManager.setUpListener()
        // 打印输入参数，便于调试
//        print("startV2Ray 被调用，传入的参数如下：")
//        print("remark: \(remark)")
//        print("config: \(config)")
//        print("blockedApps: \(blockedApps)")
//        print("bypassSubnets: \(bypassSubnets)")
//        print("proxyOnly: \(proxyOnly)")

        // 解析 V2ray 配置
        guard let v2rayConfig = Utilities.parseV2rayJsonFile(remark: remark, config: config, blockedApplication: blockedApps, bypassSubnets: bypassSubnets) else {
            // 如果解析失败，直接返回
            return
        }

        AppConfigs.V2RAY_CONFIG = v2rayConfig
        AppConfigs.V2RAY_STATE = .CONNECTED

//        print(AppConfigs.V2RAY_CONFIG?.APPLICATION_ICON ?? 0)
//        print(AppConfigs.V2RAY_CONFIG?.APPLICATION_NAME ?? "Default Name")
//        print(AppConfigs.V2RAY_CONFIG?.BLOCKED_APPS ?? "BLOCKED_APPS")
//        print(AppConfigs.V2RAY_CONFIG?.BYPASS_SUBNETS ?? "BYPASS_SUBNETS")
//        print(AppConfigs.V2RAY_CONFIG?.CONNECTED_V2RAY_SERVER_ADDRESS ?? "Default Address")
//        print(AppConfigs.V2RAY_CONFIG?.CONNECTED_V2RAY_SERVER_PORT ?? "Default Port")
//        print(AppConfigs.V2RAY_CONFIG?.ENABLE_TRAFFIC_STATISTICS ?? false)
//        print(AppConfigs.V2RAY_CONFIG?.LOCAL_HTTP_PORT ?? 0)
//        print(AppConfigs.V2RAY_CONFIG?.LOCAL_SOCKS5_PORT ?? 0)
//        print(AppConfigs.V2RAY_CONFIG?.NOTIFICATION_DISCONNECT_BUTTON_NAME ?? "DISCONNECT")
//        print(AppConfigs.V2RAY_CONFIG?.REMARK ?? "Default Remark")
//        print(AppConfigs.V2RAY_CONFIG?.V2RAY_FULL_JSON_CONFIG ?? "Default Full JSON")

        // 如果配置为 nil, 不做任何操作
        if AppConfigs.V2RAY_CONFIG == nil {
            return
        }

        coreManager.startCore()

        initializeV2Ray(result: result)
    }

    public func stopV2Ray(result: @escaping FlutterResult) {
        AppConfigs.V2RAY_STATE = .DISCONNECT
        coreManager.stopCore()

        initializeV2Ray(result: result)
    }
}
