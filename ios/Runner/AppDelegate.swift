import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var pushChannel: FlutterMethodChannel?
  private var apnsToken: String?
  private var pendingTaps: [[String: Any]] = []
  /// Dart is listening once it has asked for the taps that launched the app.
  private var dartReady = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Octo's pushes and flutter_local_notifications' taps both come through here.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Keeps the account folder (database, WAL, journal) out of backups: the
    // outbox is operational state, and restoring it could send a task twice.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "OctoBackup") {
      let channel = FlutterMethodChannel(name: "dev.october.octo/backup", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        guard call.method == "excludeFromBackup", let path = call.arguments as? String else {
          result(FlutterMethodNotImplemented)
          return
        }
        var url = URL(fileURLWithPath: path, isDirectory: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        do {
          try url.setResourceValues(values)
          result(nil)
        } catch {
          result(FlutterError(code: "backup", message: nil, details: nil))
        }
      }
    }

    // Pushes straight from Apple (no Firebase): the device token, and the
    // taps on and arrivals of October's notifications (lib/data/push/apns_push.dart).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "OctoPush") {
      let channel = FlutterMethodChannel(name: "dev.october.octo/push", binaryMessenger: registrar.messenger())
      pushChannel = channel
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else { return }
        switch call.method {
        case "requestPermission":
          UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
              DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
            }
            DispatchQueue.main.async { result(granted) }
          }
        case "token":
          // Asking again is cheap; the answer arrives in didRegister… and goes to Dart.
          UIApplication.shared.registerForRemoteNotifications()
          result(self.apnsToken)
        case "pendingTaps":
          result(self.pendingTaps)
          self.pendingTaps.removeAll()
          self.dartReady = true
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }

  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    apnsToken = token
    pushChannel?.invokeMethod("token", arguments: token)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  /// October's pushes carry computerId and kind next to `aps`; anything else
  /// (a local notification) goes to the plugins as before.
  private func octoData(_ userInfo: [AnyHashable: Any]) -> [String: Any]? {
    guard let computerId = userInfo["computerId"] as? String, let kind = userInfo["kind"] as? String else { return nil }
    var data: [String: Any] = ["computerId": computerId, "kind": kind]
    if let taskId = userInfo["taskId"] as? String { data["taskId"] = taskId }
    if let alert = (userInfo["aps"] as? [String: Any])?["alert"] as? [String: Any] {
      if let title = alert["title"] as? String { data["title"] = title }
      if let body = alert["body"] as? String { data["body"] = body }
    }
    return data
  }

  // While the app is open: no system banner; the app shows its own.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if let data = octoData(notification.request.content.userInfo), notification.request.trigger is UNPushNotificationTrigger {
      pushChannel?.invokeMethod("foreground", arguments: data)
      completionHandler([])
      return
    }
    super.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if let data = octoData(response.notification.request.content.userInfo),
       response.notification.request.trigger is UNPushNotificationTrigger {
      if dartReady, let channel = pushChannel {
        channel.invokeMethod("tap", arguments: data)
      } else {
        pendingTaps.append(data)
      }
      completionHandler()
      return
    }
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }
}
