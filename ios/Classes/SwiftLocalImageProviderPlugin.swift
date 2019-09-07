import Flutter
import UIKit
import Photos

@available(iOS 10.0, *)
public class SwiftLocalImageProviderPlugin: NSObject, FlutterPlugin {
  let imageManager = PHImageManager.default()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "local_image_provider", binaryMessenger: registrar.messenger())
    let instance = SwiftLocalImageProviderPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "latest_images":
        let maxPhotos = call.arguments! as! Int
        getLatestImages( maxPhotos, result);
    case "photo_image":
        let arguments = call.arguments! as! Dictionary<String,AnyObject>
        getPhotoImage(arguments["id"] as! String, arguments["pixelWidth"] as! Int, arguments["pixelHeight"] as! Int, result);
    default:
        print("Unrecognized method: \(call.method)");
        result("Unrecognized method: \(call.method)");
    }
  // result("iOS Photos min" )
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
    }
}
