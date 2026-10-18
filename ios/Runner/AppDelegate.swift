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
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "LocalAttachmentOpener")
    LocalAttachmentOpener.register(with: registrar)
  }
}

private final class LocalAttachmentOpener: NSObject, FlutterPlugin,
  UIDocumentInteractionControllerDelegate {
  private var documentController: UIDocumentInteractionController?
  private weak var previewViewController: UIViewController?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "aura/local_attachment_opener",
      binaryMessenger: registrar.messenger()
    )
    let instance = LocalAttachmentOpener()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "openFile" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard
      let arguments = call.arguments as? [String: Any],
      let path = arguments["path"] as? String
    else {
      result(FlutterError(
        code: "INVALID_PATH",
        message: "Attachment path is required.",
        details: nil
      ))
      return
    }
    guard FileManager.default.fileExists(atPath: path) else {
      result(FlutterError(
        code: "FILE_NOT_FOUND",
        message: "Attachment file does not exist.",
        details: nil
      ))
      return
    }
    previewViewController = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first(where: { $0.isKeyWindow })?
      .rootViewController
    guard previewViewController != nil else {
      result(FlutterError(
        code: "NO_VIEWER",
        message: "Could not find a view controller to preview the attachment.",
        details: nil
      ))
      return
    }

    let controller = UIDocumentInteractionController(
      url: URL(fileURLWithPath: path)
    )
    controller.delegate = self
    documentController = controller
    guard controller.presentPreview(animated: true) else {
      result(FlutterError(
        code: "NO_VIEWER",
        message: "No installed app can open this attachment.",
        details: nil
      ))
      return
    }
    result(nil)
  }

  func documentInteractionControllerViewControllerForPreview(
    _ controller: UIDocumentInteractionController
  ) -> UIViewController {
    previewViewController!
  }
}
