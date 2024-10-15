
import Foundation

class AppConfigs {
    /// 当前 V2Ray 连接模式，默认为 VPN_TUN
    static var V2RAY_CONNECTION_MODE: V2RAY_CONNECTION_MODES = .VPN_TUN
    
    /// 应用名称，默认为空
    static var APPLICATION_NAME: String?
    
    /// 应用图标的资源 ID
    static var APPLICATION_ICON: Int = 0
    
    /// V2Ray 配置，默认为 nil
    static var V2RAY_CONFIG: V2rayConfig?
    
    /// 当前 V2Ray 状态，默认为断开连接
    static var V2RAY_STATE: V2RAY_STATES = .V2RAY_DISCONNECTED
    
    /// 是否启用流量和速度统计，默认为 true
    static var ENABLE_TRAFFIC_AND_SPEED_STATICS: Bool = true
    
    /// 用于测量延迟的 URL
    static var DELAY_URL: String?
    
    /// 通知中的断开连接按钮名称
    static var NOTIFICATION_DISCONNECT_BUTTON_NAME: String?

    /// V2Ray 服务命令枚举
    enum V2RAY_SERVICE_COMMANDS {
        case START_SERVICE
        case STOP_SERVICE
        case MEASURE_DELAY
    }

    /// V2Ray 状态枚举
    enum V2RAY_STATES {
        case V2RAY_CONNECTED
        case V2RAY_DISCONNECTED
        case V2RAY_CONNECTING
    }

    /// V2Ray 连接模式枚举
    enum V2RAY_CONNECTION_MODES {
        case VPN_TUN
        case PROXY_ONLY
    }
}
