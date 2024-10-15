import Flutter
import UIKit

public class FlutterV2rayPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(name: "flutter_v2ray", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "flutter_v2ray/status", binaryMessenger: registrar.messenger())
    
    let instance = FlutterV2rayPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance) // Register event channel for status updates
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initializeV2Ray":
      guard let args = call.arguments as? [String: Any],
            let notificationIconResourceType = args["notificationIconResourceType"] as? String,
            let notificationIconResourceName = args["notificationIconResourceName"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for initializeV2Ray", details: nil))
        return
      }
      initializeV2Ray(notificationIconResourceType: notificationIconResourceType, notificationIconResourceName: notificationIconResourceName)
      result(nil) // Return success

    case "startV2Ray":
      guard let args = call.arguments as? [String: Any],
            let remark = args["remark"] as? String,
            let config = args["config"] as? String,
            let notificationDisconnectButtonName = args["notificationDisconnectButtonName"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for startV2Ray", details: nil))
        return
      }
      startV2Ray(remark: remark, config: config, notificationDisconnectButtonName: notificationDisconnectButtonName)
      result(nil)

    case "stopV2Ray":
      stopV2Ray()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // Methods for initializing and starting/stopping V2Ray
  private func initializeV2Ray(notificationIconResourceType: String, notificationIconResourceName: String) {
    // Initialization logic for V2Ray (this will depend on your native V2Ray setup)
    // You can set up native notification, V2Ray core, etc.
  }

  private func startV2Ray(remark: String, config: String, notificationDisconnectButtonName: String) {
    // Logic to start V2Ray with the provided configuration
    // Send event data to Flutter via eventSink if necessary
    eventSink?(["state": "connected"])  // Example of sending connection state
  }

  private func stopV2Ray() {
    // Logic to stop V2Ray
    eventSink?(["state": "disconnected"])  // Example of sending disconnection state
  }

  // FlutterStreamHandler methods for EventChannel
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }
}
