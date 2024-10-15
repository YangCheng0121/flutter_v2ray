import Foundation
import UIKit

class Utilities {
    /// 复制文件
    static func copyFiles(from src: InputStream, to dst: URL) throws {
        let fileManager = FileManager.default
        let outputStream = OutputStream(url: dst, append: false)

        src.open()
        outputStream?.open()
        defer {
            src.close()
            outputStream?.close()
        }

        var buffer = [UInt8](repeating: 0, count: 1024)
        while src.hasBytesAvailable {
            let len = src.read(&buffer, maxLength: 1024)
            if len > 0 {
                outputStream?.write(buffer, maxLength: len)
            }
        }
    }

    /// 获取用户的 assets 路径
    static func getUserAssetsPath(_ context: UIViewController) -> String {
        let fileManager = FileManager.default
        if let extDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("assets"),
           fileManager.fileExists(atPath: extDir.path)
        {
            return extDir.path
        } else {
            let assetsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("assets")
            return assetsDir?.path ?? ""
        }
    }

    /// 复制应用的 assets 文件
    static func copyAssets(_ context: UIViewController) {
        let extFolder = getUserAssetsPath(context)
        do {
            let geoFiles = ["geosite.dat", "geoip.dat"]
            let assetFiles = try FileManager.default.contentsOfDirectory(atPath: Bundle.main.resourcePath!)
            for asset in assetFiles where geoFiles.contains(asset) {
                let src = InputStream(fileAtPath: Bundle.main.path(forResource: asset, ofType: nil)!)
                let dst = URL(fileURLWithPath: extFolder).appendingPathComponent(asset)
                try copyFiles(from: src!, to: dst)
            }
        } catch {
            print("Utilities: copyAssets failed => \(error)")
        }
    }

    /// 将整数转换为两位数
    static func convertIntToTwoDigit(_ value: Int) -> String {
        return value < 10 ? "0\(value)" : "\(value)"
    }

    /// 解析 V2Ray 的 JSON 配置文件
    static func parseV2rayJsonFile(remark: String, config: String, blockedApplication: [String], bypassSubnets: [String]) -> V2rayConfig? {
        let v2rayConfig = V2rayConfig()
        v2rayConfig.REMARK = remark
        v2rayConfig.BLOCKED_APPS = blockedApplication
        v2rayConfig.BYPASS_SUBNETS = bypassSubnets
        v2rayConfig.APPLICATION_ICON = AppConfigs.APPLICATION_ICON
        v2rayConfig.APPLICATION_NAME = AppConfigs.APPLICATION_NAME
        v2rayConfig.NOTIFICATION_DISCONNECT_BUTTON_NAME = AppConfigs.NOTIFICATION_DISCONNECT_BUTTON_NAME

        do {
            let configJson = try JSONSerialization.jsonObject(with: Data(config.utf8), options: []) as! [String: Any]

            if let inbounds = configJson["inbounds"] as? [[String: Any]] {
                for inbound in inbounds {
                    if let protocolType = inbound["protocol"] as? String, let port = inbound["port"] as? Int {
                        if protocolType == "socks" {
                            v2rayConfig.LOCAL_SOCKS5_PORT = port
                        } else if protocolType == "http" {
                            v2rayConfig.LOCAL_HTTP_PORT = port
                        }
                    }
                }
            }

            if let outbounds = configJson["outbounds"] as? [[String: Any]],
               let settings = outbounds[0]["settings"] as? [String: Any],
               let servers = settings["vnext"] as? [[String: Any]] ?? settings["servers"] as? [[String: Any]],
               let server = servers.first
            {
                v2rayConfig.CONNECTED_V2RAY_SERVER_ADDRESS = server["address"] as? String ?? ""
                v2rayConfig.CONNECTED_V2RAY_SERVER_PORT = server["port"] as? String ?? ""
            }

            if AppConfigs.ENABLE_TRAFFIC_AND_SPEED_STATICS {
                var policy = [String: Any]()
                let levels = [
                    "8": [
                        "connIdle": 300,
                        "downlinkOnly": 1,
                        "handshake": 4,
                        "uplinkOnly": 1
                    ]
                ]
                policy["levels"] = levels
                policy["system"] = [
                    "statsOutboundUplink": true,
                    "statsOutboundDownlink": true
                ]

                var updatedConfigJson = configJson
                updatedConfigJson["policy"] = policy
                updatedConfigJson["stats"] = [:]

                v2rayConfig.ENABLE_TRAFFIC_STATICS = true

                if let jsonData = try? JSONSerialization.data(withJSONObject: updatedConfigJson, options: []),
                   let updatedConfig = String(data: jsonData, encoding: .utf8)
                {
                    v2rayConfig.V2RAY_FULL_JSON_CONFIG = updatedConfig
                }
            }
        } catch {
            print("Utilities: parseV2rayJsonFile failed => \(error)")
            return nil
        }

        return v2rayConfig
    }
}
