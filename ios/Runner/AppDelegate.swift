import UIKit
import Flutter
import LocalAuthentication

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    let methodChannel = "com.theamorn.flutter"
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        initFlutterChannel()
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func callNativeSDK(_ id: String) {
        // You can put any Native SDK in here, if the result return from Delegate
        let sdk = ThirdPartySDK(delegate: self, id: id)
        sdk.start()
    }
    
    private func returnValueSDK(result: FlutterResult, id: String) {
        // You can call any SDK in here if the result return immediately
        let sdk = ThirdPartySDK(delegate: self, id: id)
        return result(sdk.process())
    }
    
    private func initFlutterChannel() {
        // com.theamorn.flutter can change to whatever you want, just have to be the same between Flutter and iOS and unique ‘domain prefix. just com.theamorn is not enough
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: methodChannel,
                binaryMessenger: controller.binaryMessenger)
            
            channel.setMethodCallHandler({ [weak self] (
                call: FlutterMethodCall,
                result: @escaping FlutterResult) -> Void in
                switch call.method {
                case "methodNameOne":
                    if let data = call.arguments as? String {
                        self?.callNativeSDK(data)
                    } else {
                        result(FlutterMethodNotImplemented)
                    }
                case "deviceHasPasscode":
                    result(self?.isDeviceHasPasscode)
                    
                case "returnValue":
                    if let data = call.arguments as? String {
                        self?.returnValueSDK(result: result, id: data)
                    } else {
                        result(FlutterMethodNotImplemented)
                    }
                default:
                    result(FlutterMethodNotImplemented)
                }
            })
        }
    }
    
    // Hide private information when going background
    override func applicationWillResignActive(_ application: UIApplication) {
        window.blur()
    }
    
    override func applicationDidBecomeActive(_ application: UIApplication) {
        window.unBlur()
    }
    
    // Disable 3rd Party Keyboard
    override func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        return extensionPointIdentifier != .keyboard
    }
    
    // Check If user has passcode in the device
    private var isDeviceHasPasscode: Bool {
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }
}

extension AppDelegate: ThirdPartySDKDelegate {
    
    func onFinish(value: String) {
        // You can send anything into arguments, String, Boolean, or even Dictionary
        // Send data back to Flutter
        if let controller = self.window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: methodChannel,
                binaryMessenger: controller.binaryMessenger)
            channel.invokeMethod("methodNameTwoFromSDK", arguments: value)
        }
    }
    
}
