import Flutter
import UIKit
import Photos

public enum LocalImageProviderMethods: String {
    case request_permission
    case latest_images
    case image_bytes
    case unknown // just for testing
}

@available(iOS 10.0, *)
public class SwiftLocalImageProviderPlugin: NSObject, FlutterPlugin {
  let imageManager = PHImageManager.default()
  public let LatestImagesMethod = "latest_images"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "local_image_provider", binaryMessenger: registrar.messenger())
    let instance = SwiftLocalImageProviderPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case LocalImageProviderMethods.request_permission.rawValue:
        getPermissions( result )
    case LocalImageProviderMethods.latest_images.rawValue:
        guard let maxPhotos = call.arguments as? Int else { result("Missing max photos argument."); return}
        getLatestImages( maxPhotos, result);
    case LocalImageProviderMethods.image_bytes.rawValue:
        guard let argsArr = call.arguments as? Dictionary<String,AnyObject>,
            let localId = argsArr["id"] as? String,
            let width = argsArr["pixelWidth"] as? Int,
            let height = argsArr["pixelHeight"] as? Int
            else { result("Missing or invalid arguments: \(call.method)"); return }
        getPhotoImage( localId, width, height, result);
    default:
        print("Unrecognized method: \(call.method)");
        result("Unrecognized method: \(call.method)");
    }
  // result("iOS Photos min" )
  }
    
    private func getPermissions(_ result: @escaping FlutterResult) {
        PHPhotoLibrary.requestAuthorization({(status) -> Void in
            if ( status == PHAuthorizationStatus.authorized ) {
                result(true)
            }
            else {
                result(false)
            }
        })
    }
    
    private func getLatestImages( _ maxPhotos: Int, _ result: @escaping FlutterResult) {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.fetchLimit = maxPhotos
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
        var photoIds = [String]();
        allPhotos.enumerateObjects{(object: AnyObject!,
            count: Int,
            stop: UnsafeMutablePointer<ObjCBool>) in
            
            if object is PHAsset{
                let asset = object as! PHAsset
                let df = ISO8601DateFormatter();
                let creationDate = df.string(from: asset.creationDate!);
                let assetJson = """
                {"id":"\(asset.localIdentifier)",
                "creationDate":"\(creationDate)",
                "pixelWidth":\(asset.pixelWidth),
                "pixelHeight":\(asset.pixelHeight)}
                """;
                photoIds.append( assetJson )
            }
        }
       result( photoIds )
    }

    private func getPhotoImage(_ id: String, _ pixelHeight: Int, _ pixelWidth: Int, _ flutterResult: @escaping FlutterResult) {
        let fetchOptions = PHFetchOptions()
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: fetchOptions )
        if ( 1 == fetchResult.count ) {
            let asset = fetchResult.firstObject!
            let targetSize = CGSize( width: pixelWidth, height: pixelHeight );
            let contentMode = PHImageContentMode.aspectFit;
            let requestOptions = PHImageRequestOptions();
            requestOptions.isSynchronous = true;
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: requestOptions, resultHandler: {(result, info)->Void in
                let image = result!
                let data = UIImageJPEGRepresentation(image, 0.7 );
                let typedData = FlutterStandardTypedData( bytes: data! );
                flutterResult( typedData);
            });
        }
        else {
            flutterResult("Image not found: \(id)")
        }
    }
}
