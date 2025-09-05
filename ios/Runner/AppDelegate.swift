import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Configurar el canal de método para comunicación con Flutter
    if let controller = window?.rootViewController as? FlutterViewController {
      methodChannel = FlutterMethodChannel(
        name: "com.example.tfg_definitivo2/alarm",
        binaryMessenger: controller.binaryMessenger
      )
      
      methodChannel?.setMethodCallHandler { [weak self] (call, result) in
        self?.handleMethodCall(call, result: result)
      }
    }
    
    // Configurar notificaciones
    setupNotifications()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupNotifications() {
    UNUserNotificationCenter.current().delegate = self
    
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if let error = error {
        print("Error al solicitar permisos de notificación: \(error)")
      }
    }
  }
  
  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startAlarm":
      startAlarmActivity()
      result(nil)
    case "stopAlarm":
      stopAlarmActivity()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func startAlarmActivity() {
    DispatchQueue.main.async {
      let alarmViewController = AlarmViewController()
      alarmViewController.modalPresentationStyle = .fullScreen
      alarmViewController.modalTransitionStyle = .crossDissolve
      
      if let rootViewController = self.window?.rootViewController {
        rootViewController.present(alarmViewController, animated: true, completion: nil)
      }
    }
  }
  
  private func stopAlarmActivity() {
    DispatchQueue.main.async {
      if let presentedViewController = self.window?.rootViewController?.presentedViewController {
        presentedViewController.dismiss(animated: true, completion: nil)
      }
    }
  }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.alert, .sound, .badge])
  }
  
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    completionHandler()
  }
}
