import Foundation

class V2rayConfig: NSObject, NSCoding {
    /// 已连接的 V2Ray 服务器地址，默认为空字符串
    var CONNECTED_V2RAY_SERVER_ADDRESS: String = ""
    
    /// 已连接的 V2Ray 服务器端口，默认为空字符串
    var CONNECTED_V2RAY_SERVER_PORT: String = ""
    
    /// 本地 Socks5 代理端口，默认为 10808
    var LOCAL_SOCKS5_PORT: Int = 10808
    
    /// 本地 HTTP 代理端口，默认为 10809
    var LOCAL_HTTP_PORT: Int = 10809
    
    /// 被阻止的应用程序列表，默认为 nil
    var BLOCKED_APPS: [String]? = nil
    
    /// 绕过的子网列表，默认为 nil
    var BYPASS_SUBNETS: [String]? = nil
    
    /// V2Ray 完整的 JSON 配置，默认为 nil
    var V2RAY_FULL_JSON_CONFIG: String? = nil
    
    /// 是否启用流量统计，默认为 false
    var ENABLE_TRAFFIC_STATICS: Bool = false
    
    /// 备注信息，默认为空字符串
    var REMARK: String = ""
    
    /// 应用名称，默认为 nil
    var APPLICATION_NAME: String? = nil
    
    /// 通知中断开连接按钮的名称，默认为 nil
    var NOTIFICATION_DISCONNECT_BUTTON_NAME: String? = nil
    
    /// 应用图标资源 ID，默认为 0
    var APPLICATION_ICON: Int = 0
    
    // MARK: - NSCoding

    required init?(coder aDecoder: NSCoder) {
        self.CONNECTED_V2RAY_SERVER_ADDRESS = aDecoder.decodeObject(forKey: "CONNECTED_V2RAY_SERVER_ADDRESS") as? String ?? ""
        self.CONNECTED_V2RAY_SERVER_PORT = aDecoder.decodeObject(forKey: "CONNECTED_V2RAY_SERVER_PORT") as? String ?? ""
        self.LOCAL_SOCKS5_PORT = aDecoder.decodeInteger(forKey: "LOCAL_SOCKS5_PORT")
        self.LOCAL_HTTP_PORT = aDecoder.decodeInteger(forKey: "LOCAL_HTTP_PORT")
        self.BLOCKED_APPS = aDecoder.decodeObject(forKey: "BLOCKED_APPS") as? [String]
        self.BYPASS_SUBNETS = aDecoder.decodeObject(forKey: "BYPASS_SUBNETS") as? [String]
        self.V2RAY_FULL_JSON_CONFIG = aDecoder.decodeObject(forKey: "V2RAY_FULL_JSON_CONFIG") as? String
        self.ENABLE_TRAFFIC_STATICS = aDecoder.decodeBool(forKey: "ENABLE_TRAFFIC_STATICS")
        self.REMARK = aDecoder.decodeObject(forKey: "REMARK") as? String ?? ""
        self.APPLICATION_NAME = aDecoder.decodeObject(forKey: "APPLICATION_NAME") as? String
        self.NOTIFICATION_DISCONNECT_BUTTON_NAME = aDecoder.decodeObject(forKey: "NOTIFICATION_DISCONNECT_BUTTON_NAME") as? String
        self.APPLICATION_ICON = aDecoder.decodeInteger(forKey: "APPLICATION_ICON")
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(CONNECTED_V2RAY_SERVER_ADDRESS, forKey: "CONNECTED_V2RAY_SERVER_ADDRESS")
        aCoder.encode(CONNECTED_V2RAY_SERVER_PORT, forKey: "CONNECTED_V2RAY_SERVER_PORT")
        aCoder.encode(LOCAL_SOCKS5_PORT, forKey: "LOCAL_SOCKS5_PORT")
        aCoder.encode(LOCAL_HTTP_PORT, forKey: "LOCAL_HTTP_PORT")
        aCoder.encode(BLOCKED_APPS, forKey: "BLOCKED_APPS")
        aCoder.encode(BYPASS_SUBNETS, forKey: "BYPASS_SUBNETS")
        aCoder.encode(V2RAY_FULL_JSON_CONFIG, forKey: "V2RAY_FULL_JSON_CONFIG")
        aCoder.encode(ENABLE_TRAFFIC_STATICS, forKey: "ENABLE_TRAFFIC_STATICS")
        aCoder.encode(REMARK, forKey: "REMARK")
        aCoder.encode(APPLICATION_NAME, forKey: "APPLICATION_NAME")
        aCoder.encode(NOTIFICATION_DISCONNECT_BUTTON_NAME, forKey: "NOTIFICATION_DISCONNECT_BUTTON_NAME")
        aCoder.encode(APPLICATION_ICON, forKey: "APPLICATION_ICON")
    }
    
    override init() {
        super.init()
    }
}
