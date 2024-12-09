import Flutter
import NetworkExtension
import UIKit

public class FlutterV2rayPlugin: NSObject, FlutterPlugin {
    private var eventSink: FlutterEventSink?

    // V2ray Controller
    private lazy var controller: V2rayController = .shared()
    // V2ray Core
    private lazy var coreManager: V2rayCoreManager = .shared()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: "flutter_v2ray", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "flutter_v2ray/status", binaryMessenger: registrar.messenger())

        let instance = FlutterV2rayPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startV2Ray":
            if let args = call.arguments as? [String: Any] {
                // 确保所有参数都被正确解析
                if let remark = args["remark"] as? String,
                   let config = args["config"] as? String
                {
                    // 处理 blockedApps 和 bypassSubnets
                    let blockedApps = args["blocked_apps"] as? [String] ?? []
                    let bypassSubnets = args["bypass_subnets"] as? [String] ?? []
                    let proxyOnly = args["proxyOnly"] as? Bool ?? false

                    // 调用 startV2Ray 方法
                    controller.startV2Ray(remark: remark, config: config, blockedApps: blockedApps, bypassSubnets: bypassSubnets, proxyOnly: proxyOnly)
                    // Successful response: pass `nil` or any value here.
                    result(nil) // No data to return
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing or invalid arguments for startV2Ray", details: nil))
                }
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing or invalid arguments for startV2Ray", details: nil))
            }
        case "stopV2Ray":
            stopV2Ray(result: result)
        case "initializeV2Ray":
            initializeV2Ray(result: result)
        case "getServerDelay":
            if let args = call.arguments as? [String: Any],
               let config = args["config"] as? String,
               let url = args["url"] as? String
            {
                getServerDelay(config: config, url: url, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing or invalid arguments for getServerDelay", details: nil))
            }
        case "getConnectedServerDelay":
            if let args = call.arguments as? [String: Any],
               let url = args["url"] as? String
            {
                getConnectedServerDelay(url: url, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing or invalid arguments for getConnectedServerDelay", details: nil))
            }
        case "requestPermission":
            requestPermission(result: result)
        case "getCoreVersion":
            getCoreVersion(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func initializeV2Ray(result: FlutterResult) {
//        sendStatusUpdate(state: "initialized")
        result("V2Ray initialized on iOS")
    }

    private func stopV2Ray(result: FlutterResult) {
//        sendStatusUpdate(state: "stopped")
        result("V2Ray stopped on iOS")
    }

    private func getServerDelay(config: String, url: String, result: FlutterResult) {
        let delay = 100 // 示例延迟
        result(delay)
    }

    private func getConnectedServerDelay(url: String, result: FlutterResult) {
        let delay = 50 // 示例延迟
        result(delay)
    }

    private func requestPermission(result: @escaping FlutterResult) {
        coreManager.loadVPNPreference { [weak self] error in
            if let error = error {
                self?.handleFlutterError(
                    result: result,
                    code: "VPN_LOAD_FAILED",
                    message: "Failed to load VPN preference",
                    details: error.localizedDescription
                )
                return
            }

            self?.coreManager.enableVPNManager { error in
                if let error = error {
                    self?.handleFlutterError(
                        result: result,
                        code: "VPN_ENABLE_FAILED",
                        message: "Failed to enable VPN",
                        details: error.localizedDescription
                    )
                    return
                }

                // 成功返回
                result(true)
            }
        }
    }

    /// 统一处理错误并返回 FlutterError
    private func handleFlutterError(result: @escaping FlutterResult, code: String, message: String, details: String?) {
        print("[Error] Code: \(code), Message: \(message), Details: \(details ?? "No details")")
        result(FlutterError(
            code: code,
            message: message,
            details: details
        ))
    }

    private func getCoreVersion(result: FlutterResult) {
        result("1.0.0")
    }

    struct V2RayStatus {
        let runTime: String
        let uploadSpeed: String
        let downloadSpeed: String
        let totalUpload: String
        let totalDownload: String
        let currentState: String
    }

    private func sendStatusUpdate(status: V2RayStatus) {
        guard let eventSink = eventSink else {
            return
        }

        let statusArray: [Any] = [
            status.runTime,
            status.uploadSpeed,
            status.downloadSpeed,
            status.totalUpload,
            status.totalDownload,
            status.currentState
        ]

        eventSink(statusArray)
    }
}

extension FlutterV2rayPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
//        sendStatusUpdate(state: "listening")
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
