import Foundation
import Libv2ray


// 单例 V2rayCoreManager 实现（与 Java 类似）
class V2rayCoreManager {
//    var v2rayServicesListener: V2RayServicesListener?
    
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

    static let shared = V2rayCoreManager()
    
    private init() {}
    
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
            
            print("setUpListener => new initialize from ", self)
            print("当前的XrayCore版本:", Libv2ray.IOSLibXrayLiteCheckVersionX())


        } catch {
            // 捕获异常并记录错误
            print("setUpListener failed => \(error)")
            isLibV2rayCoreInitialized = false // 标记初始化失败
        }
    }
    
    // 启动核心逻辑
    func startCore() -> Bool {
//        delegate?.startService()
        V2RAY_STATE = AppConfigs.V2RAY_STATES.V2RAY_CONNECTING // 设置状态为连接中
        
        if !isLibV2rayCoreInitialized {
            print("Error: \(String(describing: V2rayCoreManager.self)) startCore failed => LibV2rayCore should be initialized before start.")
            return false // 如果没有初始化，返回失败
        }
        
        return true
    }
    
    // 停止核心逻辑
    func stopCore() {
//        delegate?.stopService()
    }
}
