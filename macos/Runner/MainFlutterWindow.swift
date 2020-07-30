import Cocoa
import FlutterMacOS
import IOKit.ps

let psInfo = IOPSCopyPowerSourcesInfo().takeRetainedValue()
let psList = IOPSCopyPowerSourcesList(psInfo).takeRetainedValue() as [CFTypeRef]

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame

    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    let batteryChannel = FlutterMethodChannel(name: "samples.flutter.dev/battery",
                                              binaryMessenger: flutterViewController.engine.binaryMessenger)
    batteryChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
      // Note: this method is invoked on the UI thread.
      guard call.method == "getBatteryLevel" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.receiveBatteryLevel(result: result)
    })

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

    private func receiveBatteryLevel(result: FlutterResult) {
      for ps in psList {
          if let psDesc = IOPSGetPowerSourceDescription(psInfo, ps).takeUnretainedValue() as? [String: Any] {
              if let _ = psDesc[kIOPSTypeKey] as? String,
                  let currentCapacity = (psDesc[kIOPSCurrentCapacityKey] as? Int),
                    let maxCapacity = (psDesc[kIOPSMaxCapacityKey] as? Int) {
                        return result(Int(Float(currentCapacity) / Float(maxCapacity) * 100))
                    }
//            if let type = psDesc[kIOPSTypeKey] as? String,
//                let isCharging = (psDesc[kIOPSIsChargingKey] as? Bool) {
//                print(type, "is charging:", isCharging)
//                return result(Bool(isCharging))
//            }
          }
      }
    }
}
