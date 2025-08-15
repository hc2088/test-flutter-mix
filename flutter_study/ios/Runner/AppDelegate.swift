import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    var textureRegistry: FlutterTextureRegistry?
    var texture: SimpleColorTexture?   // 用自定义类，FlutterPixelBufferTexture 不存在
    var textureId: Int64 = -1
    
    
    
    
    
    
    func generateRandomData(size: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: size)
        let status = SecRandomCopyBytes(kSecRandomDefault, size, &bytes)
        if status == errSecSuccess {
            return Data(bytes)
        } else {
            return Data()
        }
    }
    
    
    // 读取Assets.xcassets图片转Data返回Flutter
    func handleGetNativeImage(call: FlutterMethodCall, result: FlutterResult) {
        let imageName = call.arguments as? String ?? "AppIcon"
        guard let image = UIImage(named: imageName) else {
            result(FlutterError(code: "404", message: "Image not found", details: nil))
            return
        }
        guard let data = image.pngData() else {
            result(FlutterError(code: "500", message: "Failed to convert image to data", details: nil))
            return
        }
        result(FlutterStandardTypedData(bytes: data))
    }
    
    // 将Assets.xcassets图片写入临时目录，返回路径
    func handleGetNativeImagePath(call: FlutterMethodCall, result: FlutterResult) {
        let imageName = call.arguments as? String ?? "AppIcon"
        guard let image = UIImage(named: imageName) else {
            result(FlutterError(code: "404", message: "Image not found", details: nil))
            return
        }
        guard let data = image.pngData() else {
            result(FlutterError(code: "500", message: "Failed to convert image to data", details: nil))
            return
        }
        let tempDir = NSTemporaryDirectory()
        let filePath = tempDir + "flutter_native_image.png"
        do {
            try data.write(to: URL(fileURLWithPath: filePath))
            result(filePath)
        } catch {
            result(FlutterError(code: "500", message: "Failed to write image file", details: error.localizedDescription))
        }
    }
    
    // 创建一个简单的红色纹理，返回 textureId 给 Flutter
    func handleCreateTexture(result: FlutterResult) {
        guard let textureRegistry = textureRegistry else {
            result(FlutterError(code: "500", message: "TextureRegistry unavailable", details: nil))
            return
        }
        texture = SimpleColorTexture()
        textureId = textureRegistry.register(texture!)
        result(textureId)
    }
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {


        GeneratedPluginRegistrant.register(with: self)



        let controller = window?.rootViewController as! FlutterViewController
        if let registrar = controller.registrar(forPlugin: "test") {
            textureRegistry = registrar.textures()
        }
        
        let channel = FlutterMethodChannel(name: "test.bigdata.channel", binaryMessenger: controller.binaryMessenger)
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            switch call.method {
            case "getImageBytes":
                let data = self.generateRandomData(size: 5 * 1024 * 1024) // 5MB模拟数据
                result(FlutterStandardTypedData(bytes: data))
                
            case "getImagePath":
                let data = self.generateRandomData(size: 5 * 1024 * 1024)
                let path = NSTemporaryDirectory() + "test_img.jpg"
                try? data.write(to: URL(fileURLWithPath: path))
                result(path)
                
                
            case "createTexture":
                
                self.texture = SimpleColorTexture()
                if let textureRegistry = self.textureRegistry {
                    self.textureId = textureRegistry.register(self.texture!)
                    result(self.textureId)
                } else {
                    result(FlutterError(code: "NO_TEXTURE_REGISTRY", message: "Texture registry not found", details: nil))
                }
                
                
       
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        
        let controller2 : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel2 = FlutterMethodChannel(name: "native.asset.channel", binaryMessenger: controller2.binaryMessenger)
        
        textureRegistry = controller2.registrar(forPlugin: "native.asset.channel")?.textures()
        
        channel2.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            switch call.method {
            case "getNativeImage":
                self.handleGetNativeImage(call: call, result: result)
            case "getNativeImagePath":
                self.handleGetNativeImagePath(call: call, result: result)
            case "createTexture":
                self.handleCreateTexture(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    
    
}

class SimpleColorTexture: NSObject, FlutterTexture {
    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!
        ] as CFDictionary
        
        CVPixelBufferCreate(kCFAllocatorDefault, 200, 200, kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
        guard let pb = pixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(pb, [])
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pb),
            width: 200,
            height: 200,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pb),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        )
        
        context?.setFillColor(UIColor.red.cgColor)
        context?.fill(CGRect(x: 0, y: 0, width: 200, height: 200))
        CVPixelBufferUnlockBaseAddress(pb, [])
        
        return Unmanaged.passRetained(pb)
    }
}
