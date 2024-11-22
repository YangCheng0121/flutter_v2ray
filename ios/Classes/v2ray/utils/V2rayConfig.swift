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
}
