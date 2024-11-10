import Flutter
import Foundation
import NetworkExtension

// import Libv2ray

// 单例 V2rayCoreManager 实现（与 Java 类似）
public class V2rayCoreManager {
    public static var stage: FlutterEventSink?
    
    private var manager = NETunnelProviderManager.shared()

//    var v2rayServicesListener: V2RayServicesListener?
    private static var sharedV2rayCoreManager: V2rayCoreManager = .init()

    public class func shared() -> V2rayCoreManager {
        return sharedV2rayCoreManager
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
    var V2RAY_STATE: AppConfigs.V2RAY_STATES = .V2RAY_DISCONNECTED
    
    public func setUpListener() {
        do {
            // 将目标服务赋值给 v2rayServicesListener
            
//            v2rayServicesListener = targetService as? V2RayServicesListener
            
            // 初始化 V2Ray 环境
//            let userAssetsPath = Utilities.getUserAssetsPath()
//            Libv2ray.IOSLibXrayLiteInitV2Env(userAssetsPath, "")
//            print("userAssetsPath============>", userAssetsPath)
            
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
    
    // 加载配置
    public func loadVPNPreference(completion: @escaping (Error?) -> Void) {
        // 尝试加载所有现有的 VPN 配置
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            // 如果加载失败或返回的配置为空，则直接调用回调函数并返回错误
            guard let managers = managers, error == nil else {
                completion(error)
                return
            }

            // 检查是否没有现有的 VPN 配置
            if managers.count == 0 {
                // 如果没有现有配置，则创建一个新的 NETunnelProviderManager 实例
                let newManager = NETunnelProviderManager()
                
                // 配置新的 VPN 协议
                newManager.protocolConfiguration = NETunnelProviderProtocol()
                
                // 设置描述，以便用户识别此 VPN 配置
                newManager.localizedDescription = "V2ray"
                
                newManager.protocolConfiguration?.serverAddress = "your.server.address.com"
                
                // 将新的 VPN 配置保存到系统中
                newManager.saveToPreferences { error in
                    // 如果保存出错，则返回错误
                    guard error == nil else {
                        completion(error)
                        return
                    }
                    
                    // 成功保存后，重新加载配置以确保生效
                    newManager.loadFromPreferences { _ in
                        // 将当前 manager 设置为新创建的配置
                        self.manager = newManager
                        // 回调成功
                        completion(nil)
                    }
                }
            } else {
                // 如果已存在至少一个 VPN 配置，则直接使用第一个配置
                self.manager = managers[0]
                // 回调成功
                completion(nil)
            }
        }
    }

    // 启动核心逻辑
    public func startCore() -> Bool {
        print("startCore========>")
//        delegate?.startService()
        loadVPNPreference() { error in
            guard error == nil else {
//                fatalError("load VPN preference failed: \(error.debugDescription)")
                print("加载VPN配置失败 \(error.debugDescription)")
                return
            }

//            manager.enableVPNManager { error in
//                guard error == nil else {
//                    fatalError("enable VPN failed: \(error.debugDescription)")
//                }
//                manager.toggleVPNConnection { error in
//                    guard error == nil else {
//                        fatalError("toggle VPN connection failed: \(error.debugDescription)")
//                    }
//                }
//            }
        }
        V2RAY_STATE = AppConfigs.V2RAY_STATES.V2RAY_CONNECTING // 设置状态为连接中
        
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
    
    // 停止核心逻辑
    public func stopCore() {
//        delegate?.stopService()
    }
}
