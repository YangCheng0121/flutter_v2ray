//
//  V2rayController.swift
//  Pods
//
//  Created by Cheng Yang on 2024/11/13.
//
import NetworkExtension

public class V2rayController {
    // 单例
    private static var sharedV2rayController: V2rayController = .init()

    public class func shared() -> V2rayController {
        return sharedV2rayController
    }

    // 启动 V2ray
    public func startV2Ray(remark: String, config: String, blockedApps: [String], bypassSubnets: [String], proxyOnly: Bool) {
        // 打印输入参数，便于调试
//        print("startV2Ray 被调用，传入的参数如下：")
//        print("remark: \(remark)")
//        print("config: \(config)")
//        print("blockedApps: \(blockedApps)")
//        print("bypassSubnets: \(bypassSubnets)")
//        print("proxyOnly: \(proxyOnly)")
        // 确保 result 被调用，输出状态信息
//        print("startV2Ray===========>")
        // 解析 V2ray 配置
        guard let v2rayConfig = Utilities.parseV2rayJsonFile(remark: remark, config: config, blockedApplication: blockedApps, bypassSubnets: bypassSubnets) else {
            // 如果解析失败，直接返回
            print("V2ray 配置解析失败")
            return
        }

        AppConfigs.V2RAY_CONFIG = v2rayConfig
//        if let address = AppConfigs.V2RAY_CONFIG?.CONNECTED_V2RAY_SERVER_ADDRESS {
//            print(address)
//        }
        print(AppConfigs.V2RAY_CONFIG?.CONNECTED_V2RAY_SERVER_ADDRESS ?? "Default Address")
        print(AppConfigs.V2RAY_CONFIG?.CONNECTED_V2RAY_SERVER_PORT ?? "Default Port")

        // 如果配置为 nil, 不做任何操作
        if AppConfigs.V2RAY_CONFIG == nil {
            print("V2ray 配置为空")
            return
        }

        // 这里可以加入启动 V2ray 的其他逻辑
        print("V2ray 配置已启动")
    }
}
