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
    // قناة النسخ الاحتياطي على iCloud (تستخدمها lib/services/backup/icloud_provider.dart).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DaftryICloudBackup") {
      ICloudBackupChannel.register(with: registrar)
    }
  }
}

/// النسخ الاحتياطي على iCloud Documents بحساب Apple الخاص بالمستخدم.
/// الملفات مشفّرة مسبقاً في Dart (AES-256)، وهنا فقط نحفظها ونقرؤها.
final class ICloudBackupChannel: NSObject {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "daftry/icloud_backup",
      binaryMessenger: registrar.messenger()
    )
    let instance = ICloudBackupChannel()
    channel.setMethodCallHandler { call, result in
      instance.handle(call, result: result)
    }
  }

  /// مجلد النسخ داخل حاوية iCloud الخاصة بالتطبيق.
  private var backupsURL: URL? {
    FileManager.default
      .url(forUbiquityContainerIdentifier: nil)?
      .appendingPathComponent("Documents/Backups", isDirectory: true)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // عمليات الملفات في خيط خلفي حتى لا تتجمد الواجهة.
    DispatchQueue.global(qos: .utility).async {
      let reply: Any?
      do {
        reply = try self.perform(call)
      } catch {
        reply = FlutterError(code: "icloud_error", message: error.localizedDescription, details: nil)
      }
      DispatchQueue.main.async { result(reply) }
    }
  }

  private func perform(_ call: FlutterMethodCall) throws -> Any? {
    let args = call.arguments as? [String: Any]
    let fm = FileManager.default
    switch call.method {
    case "isAvailable":
      return fm.ubiquityIdentityToken != nil && backupsURL != nil

    case "upload":
      guard let dir = backupsURL,
            let name = args?["name"] as? String,
            let bytes = args?["bytes"] as? FlutterStandardTypedData
      else { return FlutterError(code: "bad_args", message: nil, details: nil) }
      try fm.createDirectory(at: dir, withIntermediateDirectories: true)
      try bytes.data.write(to: dir.appendingPathComponent(name), options: .atomic)
      return nil

    case "list":
      guard let dir = backupsURL else { return [[String: Any]]() }
      try fm.createDirectory(at: dir, withIntermediateDirectories: true)
      let keys: [URLResourceKey] = [.contentModificationDateKey, .fileSizeKey]
      let urls = try fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: keys)
      return urls.compactMap { url -> [String: Any]? in
        var name = url.lastPathComponent
        // الملفات غير المنزّلة بعد تظهر باسم مخفي: .name.dftry.icloud
        if name.hasPrefix("."), name.hasSuffix(".icloud") {
          name = String(name.dropFirst().dropLast(".icloud".count))
        }
        guard name.hasSuffix(".dftry") else { return nil }
        let values = try? url.resourceValues(forKeys: Set(keys))
        return [
          "name": name,
          "modified": (values?.contentModificationDate ?? Date()).timeIntervalSince1970 * 1000,
          "size": values?.fileSize ?? 0,
        ]
      }

    case "download":
      guard let dir = backupsURL, let name = args?["name"] as? String else { return nil }
      let url = dir.appendingPathComponent(name)
      if !fm.fileExists(atPath: url.path) {
        // الملف في السحابة فقط: نطلب تنزيله وننتظر حتى 30 ثانية.
        try fm.startDownloadingUbiquitousItem(at: url)
        for _ in 0..<60 where !fm.fileExists(atPath: url.path) {
          Thread.sleep(forTimeInterval: 0.5)
        }
      }
      return FlutterStandardTypedData(bytes: try Data(contentsOf: url))

    case "delete":
      guard let dir = backupsURL, let name = args?["name"] as? String else { return nil }
      try fm.removeItem(at: dir.appendingPathComponent(name))
      return nil

    default:
      return FlutterMethodNotImplemented
    }
  }
}
