import Flutter
import UIKit
import Vision
import ImageIO

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
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DespensaTextRecognition") else { return }
    let channel = FlutterMethodChannel(name: "despensa/text_recognition", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognize" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any], let path = args["path"] as? String else {
        result(FlutterError(code: "invalid_image", message: "Imagem inválida.", details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let text = try ReceiptTextRecognizer.recognize(path: path)
          DispatchQueue.main.async { result(text) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "recognition_failed", message: "Não foi possível ler a imagem.", details: nil))
          }
        }
      }
    }
  }
}

/// On-device OCR. The image never leaves the app for recognition.
enum ReceiptTextRecognizer {
  static func recognize(path: String) throws -> String {
    guard let image = UIImage(contentsOfFile: path), let cgImage = image.cgImage else {
      throw NSError(domain: "Despensa", code: 1)
    }
    let orientation: CGImagePropertyOrientation
    switch image.imageOrientation {
    case .up: orientation = .up
    case .down: orientation = .down
    case .left: orientation = .left
    case .right: orientation = .right
    case .upMirrored: orientation = .upMirrored
    case .downMirrored: orientation = .downMirrored
    case .leftMirrored: orientation = .leftMirrored
    case .rightMirrored: orientation = .rightMirrored
    @unknown default: orientation = .up
    }
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    let supported = try request.supportedRecognitionLanguages()
    let preferred = ["pt-BR", "pt-PT", "en-US"].filter { supported.contains($0) }
    if !preferred.isEmpty { request.recognitionLanguages = preferred }
    if #available(iOS 16.0, *) { request.automaticallyDetectsLanguage = true }
    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
    try handler.perform([request])
    return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
  }
}
