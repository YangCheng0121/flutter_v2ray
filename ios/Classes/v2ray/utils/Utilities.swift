import Foundation
import UIKit

/// Utilities 类提供各种实用工具方法。
class Utilities {

    /// 复制文件从输入流到指定的 URL。
    /// - Parameters:
    ///   - src: 输入流源
    ///   - dst: 目标文件 URL
    /// - Throws: 如果复制过程中发生错误，会抛出异常
    static func copyFiles(src: InputStream, dst: URL) throws {
        let out = OutputStream(url: dst, append: false)!
        out.open()  // 打开输出流
        defer { out.close() }  // 确保在方法结束时关闭输出流

        var buf = [UInt8](repeating: 0, count: 1024)  // 缓冲区
        while true {
            let len = src.read(&buf, maxLength: buf.count)  // 从输入流读取数据
            if len <= 0 { break }  // 结束条件：无更多数据
            out.write(buf, maxLength: len)  // 写入输出流
        }
    }

    /// 获取用户资产目录路径。
    /// - Returns: 资产目录的路径
    static func getUserAssetsPath() -> String {
        let fileManager = FileManager.default
        // 获取应用支持目录下的 assets 子目录
        guard let extDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("assets") else {
            return ""
        }

        // 如果资产目录不存在，则创建
        if !fileManager.fileExists(atPath: extDir.path) {
            do {
                try fileManager.createDirectory(at: extDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return ""  // 创建目录失败
            }
        }
        return extDir.path  // 返回资产目录路径
    }

    /// 复制必要的资产文件到用户资产目录。
    /// - Parameter context: 当前的视图控制器上下文
    static func copyAssets() {
        let extFolder = getUserAssetsPath()  // 获取资产目录
        let assetFiles = ["geosite.dat", "geoip.dat"]  // 需要复制的资产文件

        // 遍历资产文件并复制
        for asset in assetFiles {
            if let assetPath = Bundle.main.path(forResource: asset, ofType: nil) {
                do {
                    let src = InputStream(fileAtPath: assetPath)!  // 创建输入流
                    let dst = URL(fileURLWithPath: extFolder).appendingPathComponent(asset)  // 目标路径
                    try copyFiles(src: src, dst: dst)  // 复制文件
                } catch {
                    print("copyAssets failed: \(error)")  // 处理复制失败的错误
                }
            }
        }
    }

    /// 将整数转换为两位数字的字符串格式。
    /// - Parameter value: 要转换的整数值
    /// - Returns: 格式化后的字符串
    static func convertIntToTwoDigit(_ value: Int) -> String {
        return String(format: "%02d", value)  // 使用格式化字符串返回两位数
    }

    /// 解析 V2Ray JSON 配置文件并生成 V2rayConfig 对象。
    /// - Parameters:
    ///   - remark: 备注
    ///   - config: JSON 配置字符串
    ///   - blockedApplication: 被阻止的应用列表
    ///   - bypassSubnets: 绕过的子网列表
    /// - Returns: V2rayConfig 对象，或在失败时返回 nil
    static func parseV2rayJsonFile(remark: String, config: String, blockedApplication: [String], bypassSubnets: [String]) -> V2rayConfig? {
        let v2rayConfig = V2rayConfig()  // 创建 V2rayConfig 实例
        v2rayConfig.REMARK = remark  // 设置备注
        v2rayConfig.BLOCKED_APPS = blockedApplication  // 设置被阻止的应用
        v2rayConfig.BYPASS_SUBNETS = bypassSubnets  // 设置绕过的子网
        v2rayConfig.APPLICATION_ICON = AppConfigs.APPLICATION_ICON  // 设置应用图标
        v2rayConfig.APPLICATION_NAME = AppConfigs.APPLICATION_NAME  // 设置应用名称

        do {
            // 将 JSON 字符串转换为字典
            if let configData = config.data(using: .utf8),
               let configJson = try JSONSerialization.jsonObject(with: configData, options: []) as? [String: Any] {

                // 解析入站配置
                if let inbounds = configJson["inbounds"] as? [[String: Any]] {
                    for inbound in inbounds {
                        if let protocolType = inbound["protocol"] as? String {
                            // 根据协议类型设置相应的端口
                            if protocolType == "socks", let port = inbound["port"] as? Int {
                                v2rayConfig.LOCAL_SOCKS5_PORT = port
                            } else if protocolType == "http", let port = inbound["port"] as? Int {
                                v2rayConfig.LOCAL_HTTP_PORT = port
                            }
                        }
                    }
                }

                // 解析出站配置
                if let outbounds = configJson["outbounds"] as? [[String: Any]],
                   let settings = outbounds[0]["settings"] as? [String: Any],
                   let vnext = settings["vnext"] as? [[String: Any]] {
                    v2rayConfig.CONNECTED_V2RAY_SERVER_ADDRESS = vnext[0]["address"] as? String ?? ""  // 服务器地址
                    v2rayConfig.CONNECTED_V2RAY_SERVER_PORT = vnext[0]["port"] as? String ?? ""  // 服务器端口
                }

                // 移除不必要的字段
                var mutableConfigJson = configJson
                mutableConfigJson.removeValue(forKey: "policy")
                mutableConfigJson.removeValue(forKey: "stats")

                // 如果启用流量和速度统计，添加相应配置
                if AppConfigs.ENABLE_TRAFFIC_AND_SPEED_STATISTICS {
                    let policy: [String: Any] = [
                        "levels": ["8": ["connIdle": 300, "downlinkOnly": 1, "handshake": 4, "uplinkOnly": 1]],
                        "system": ["statsOutboundUplink": true, "statsOutboundDownlink": true]
                    ]
                    mutableConfigJson["policy"] = policy
                    mutableConfigJson["stats"] = [:]
                    v2rayConfig.ENABLE_TRAFFIC_STATISTICS = true  // 启用流量统计
                }

                // 将字典转换回 JSON 数据
                let jsonData = try JSONSerialization.data(withJSONObject: mutableConfigJson, options: [])
                v2rayConfig.V2RAY_FULL_JSON_CONFIG = String(data: jsonData, encoding: .utf8)  // 设置完整的 JSON 配置
            }
        } catch {
            print("parseV2rayJsonFile failed: \(error)")  // 处理解析失败的错误
            return nil  // 返回 nil
        }

        return v2rayConfig  // 返回解析后的配置
    }
}
