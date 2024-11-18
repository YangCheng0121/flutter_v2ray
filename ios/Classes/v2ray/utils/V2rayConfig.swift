import Foundation

/// V2rayConfig 类用于存储 V2Ray 连接配置。
class V2rayConfig: NSObject {
    // 连接的 V2Ray 服务器地址
    var CONNECTED_V2RAY_SERVER_ADDRESS: String = ""
    // 连接的 V2Ray 服务器端口
    var CONNECTED_V2RAY_SERVER_PORT: String = ""
    // 本地 SOCKS5 代理端口
    var LOCAL_SOCKS5_PORT: Int = 10808
    // 本地 HTTP 代理端口
    var LOCAL_HTTP_PORT: Int = 10809
    // 被阻止的应用列表
    var BLOCKED_APPS: [String]? = nil
    // 绕过的子网列表
    var BYPASS_SUBNETS: [String]? = nil
    // 完整的 V2Ray JSON 配置
    var V2RAY_FULL_JSON_CONFIG: String? = nil
    // 是否启用流量统计
    var ENABLE_TRAFFIC_STATISTICS: Bool = false
    // 备注
    var REMARK: String = ""
    // 应用名称
    var APPLICATION_NAME: String?
    // 应用图标的资源 ID
    var APPLICATION_ICON: Int = 0

    var NOTIFICATION_DISCONNECT_BUTTON_NAME: String = "DISCONNECT"

    // MARK: - NSCoding

//    /// 解码器初始化方法，用于从 NSCoder 解码对象。
//    required convenience init?(coder aDecoder: NSCoder) {
//        self.init()
//        // 解码 V2Ray 服务器地址
//        CONNECTED_V2RAY_SERVER_ADDRESS = aDecoder.decodeObject(forKey: "connectedV2rayServerAddress") as? String ?? ""
//        // 解码 V2Ray 服务器端口
//        CONNECTED_V2RAY_SERVER_PORT = aDecoder.decodeObject(forKey: "connectedV2rayServerPort") as? String ?? ""
//        // 解码本地 SOCKS5 代理端口
//        LOCAL_SOCKS5_PORT = aDecoder.decodeInteger(forKey: "localSocks5Port")
//        // 解码本地 HTTP 代理端口
//        LOCAL_HTTP_PORT = aDecoder.decodeInteger(forKey: "localHttpPort")
//        // 解码被阻止的应用列表
//        BLOCKED_APPS = aDecoder.decodeObject(forKey: "blockedApps") as? [String]
//        // 解码绕过的子网列表
//        BYPASS_SUBNETS = aDecoder.decodeObject(forKey: "bypassSubnets") as? [String]
//        // 解码完整的 V2Ray JSON 配置
//        V2RAY_FULL_JSON_CONFIG = aDecoder.decodeObject(forKey: "v2rayFullJsonConfig") as? String
//        // 解码流量统计启用状态
//        ENABLE_TRAFFIC_STATISTICS = aDecoder.decodeBool(forKey: "enableTrafficStatics")
//        // 解码备注
//        REMARK = aDecoder.decodeObject(forKey: "remark") as? String ?? ""
//        // 解码应用名称
//        APPLICATION_NAME = aDecoder.decodeObject(forKey: "applicationName") as? String
//        // 解码应用图标资源 ID
//        APPLICATION_ICON = aDecoder.decodeInteger(forKey: "applicationIcon")
//    }
//
//    /// 编码方法，用于将对象编码到 NSCoder。
//    func encode(with aCoder: NSCoder) {
//        // 编码 V2Ray 服务器地址
//        aCoder.encode(CONNECTED_V2RAY_SERVER_ADDRESS, forKey: "connectedV2rayServerAddress")
//        // 编码 V2Ray 服务器端口
//        aCoder.encode(CONNECTED_V2RAY_SERVER_PORT, forKey: "connectedV2rayServerPort")
//        // 编码本地 SOCKS5 代理端口
//        aCoder.encode(LOCAL_SOCKS5_PORT, forKey: "localSocks5Port")
//        // 编码本地 HTTP 代理端口
//        aCoder.encode(LOCAL_HTTP_PORT, forKey: "localHttpPort")
//        // 编码被阻止的应用列表
//        aCoder.encode(BLOCKED_APPS, forKey: "blockedApps")
//        // 编码绕过的子网列表
//        aCoder.encode(BYPASS_SUBNETS, forKey: "bypassSubnets")
//        // 编码完整的 V2Ray JSON 配置
//        aCoder.encode(V2RAY_FULL_JSON_CONFIG, forKey: "v2rayFullJsonConfig")
//        // 编码流量统计启用状态
//        aCoder.encode(ENABLE_TRAFFIC_STATISTICS, forKey: "enableTrafficStatics")
//        // 编码备注
//        aCoder.encode(REMARK, forKey: "remark")
//        // 编码应用名称
//        aCoder.encode(APPLICATION_NAME, forKey: "applicationName")
//        // 编码应用图标资源 ID
//        aCoder.encode(APPLICATION_ICON, forKey: "applicationIcon")
//    }
}
