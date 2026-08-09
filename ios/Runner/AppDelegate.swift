import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let installChannel = FlutterMethodChannel(
      name: "com.daidai.panel/app_install",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    installChannel.setMethodCallHandler { call, result in
      guard call.method == "openExternalUrl" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let rawURL = arguments["url"] as? String,
        let url = URL(string: rawURL),
        url.scheme == "https",
        url.host?.lowercased() == "github.com"
      else {
        result(FlutterError(code: "INVALID_URL", message: "A trusted HTTPS URL is required", details: nil))
        return
      }
      UIApplication.shared.open(url, options: [:]) { opened in
        result(opened)
      }
    }
  }
}
