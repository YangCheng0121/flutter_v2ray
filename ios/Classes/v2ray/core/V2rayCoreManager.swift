import Flutter
import Foundation
import NetworkExtension

extension NEVPNStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .invalid: return "Invalid"
        case .connected: return "Connected"
        case .connecting: return "Connecting"
        case .disconnecting: return "Disconnecting"
        case .reasserting: return "Reasserting"
        default: return "Unknowed"
        }
    }
}

// import Libv2ray

// 单例 V2rayCoreManager 实现（与 Java 类似）
public class V2rayCoreManager {
//    public static var stage: FlutterEventSink?
    
//    var v2rayServicesListener: V2RayServicesListener?
    private static var sharedV2rayCoreManager: V2rayCoreManager = .init()

    public class func shared() -> V2rayCoreManager {
        return sharedV2rayCoreManager
    }
    
    private var manager = NETunnelProviderManager.shared()
   
    /// Packet tunnel provider.
    private weak static var packetTunnelProvider: NEPacketTunnelProvider?

    /// Set PacketTunnelProvider instance
    /// - Parameter packetTunnelProvider: an instance of `NEPacketTunnelProvider`. Internally stored
    ///   as a weak
    public static func setPacketTunnelProvider(with packetTunnelProvider: NEPacketTunnelProvider) {
        V2rayCoreManager.packetTunnelProvider = packetTunnelProvider
    }
     
    var isLibV2rayCoreInitialized = false
    var SERVICE_DURATION = "00:00:00"
    var seconds = 0
    var minutes = 0
    var hours = 0
    var uploadSpeed = 0
    var downloadSpeed = 0
    var totalDownload = 0
    var totalUpload = 0
    var V2RAY_STATE: AppConfigs.V2RAY_STATES = .DISCONNECT

    /// Designated initializer.
    public init() {
        
    }

    /// Set PacketTunnelProvider instance
    /// - Parameter packetTunnelProvider: an instance of `NEPacketTunnelProvider`. Internally stored
    ///   as a weak
    public static func setPacketTunnelProvider(with packetTunnelProvider: NEPacketTunnelProvider) {
        V2rayCoreManager.packetTunnelProvider = packetTunnelProvider
    }
    
    public func setUpListener() {
        do {
            isLibV2rayCoreInitialized = true // 标记初始化成功
            SERVICE_DURATION = "00:00:00" // 初始化服务时长
            seconds = 0 // 秒数重置
            minutes = 0 // 分钟重置
            hours = 0 // 小时重置
            uploadSpeed = 0 // 上传速度重置
            downloadSpeed = 0 // 下载速度重置
            totalDownload = 0 // 总下载流量重置
            totalUpload = 0 // 总上传流量重置
            
            print("setUpListener => 重新初始化为", self)
//            print("当前的XrayCore版本:", Libv2ray.IOSLibXrayLiteCheckVersionX())

        } catch {
            // 捕获异常并记录错误
            print("setUpListener failed => \(error)")
            isLibV2rayCoreInitialized = false // 标记初始化失败
        }
    }
    
    public func loadVPNPreference(completion: @escaping (Error?) -> Void) {
        // 从系统中加载所有已存在的 VPN 配置
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            // 如果加载失败或返回的配置为空，则调用回调函数并返回错误
            guard let managers = managers, error == nil else {
                completion(error) // 将错误传递给调用者
                return
            }

            // 检查是否没有现有的 VPN 配置
            if managers.count == 0 {
                // 如果没有配置，则创建一个新的 NETunnelProviderManager 实例
                let newManager = NETunnelProviderManager()
                
                // 配置新的 VPN 协议
                newManager.protocolConfiguration = NETunnelProviderProtocol()
                
                // 设置用户可见的 VPN 配置描述，用于识别该配置
                newManager.localizedDescription = "Sulian VPN"
                
                // 设置服务器地址（此处仅作标识，不是真实的服务器地址）
                newManager.protocolConfiguration?.serverAddress = "Sulian VPN"
                
                // 保存新的 VPN 配置到系统偏好设置中
                newManager.saveToPreferences { error in
                    // 如果保存失败，则返回错误
                    guard error == nil else {
                        completion(error) // 保存失败时，返回错误
                        return
                    }
                    
                    // 成功保存后，重新加载配置以确保其生效
                    newManager.loadFromPreferences { _ in
                        // 将当前实例的 `manager` 设置为新创建的配置
                        self.manager = newManager
                        // 调用回调函数表示成功
                        completion(nil)
                    }
                }
            } else {
                // 如果已存在至少一个配置，则直接使用第一个
                self.manager = managers[0]
                // 调用回调函数表示成功
                completion(nil)
            }
        }
    }
    
   
    // 启动核心逻辑
    public func startCore() -> Bool {
        print("startCore========>")
        V2RAY_STATE = AppConfigs.V2RAY_STATES.CONNECTED // 设置状态为连接中
        
        if !isLibV2rayCoreInitialized {
            print("Error: \(String(describing: V2rayCoreManager.self)) startCore failed => LibV2rayCore should be initialized before start.")
            return false // 如果没有初始化，返回失败
        }
//        do {
//            try manager.connection.startVPNTunnel()
//        } catch {
//            print("Failed to start VPN tunnel:", error)
//        }

        return true
    }

     public func enableVPNManager(completion: @escaping (Error?) -> Void) {
        // 启用当前的 VPN 配置
        manager.isEnabled = true

        // 保存启用状态到系统偏好设置中
        manager.saveToPreferences { error in
            // 如果保存失败，则返回错误
            guard error == nil else {
                completion(error) // 将错误传递给调用者
                return
            }

            // 成功保存后重新加载配置，以确保其生效
            self.manager.loadFromPreferences { error in
                completion(error) // 返回加载结果（可能是成功或错误）
            }
        }
    }

    
    // 停止核心逻辑
    public func stopCore() {
//        delegate?.stopService()
    }
}
