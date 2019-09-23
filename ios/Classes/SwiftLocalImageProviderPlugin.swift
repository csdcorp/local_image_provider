import Flutter
import UIKit
import Photos

public enum LocalImageProviderMethods: String {
    case latest_images
    case image_bytes
    case albums
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
    case LocalImageProviderMethods.albums.rawValue:
//        guard let albumType = call.arguments as? Int else { result("Missing album type argument."); return}
        getAlbums( 1, result);
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
    
    private func getAlbums( _ albumType: Int, _ result: @escaping FlutterResult) {
        var albumEncodings = [String]();
        albumEncodings.append(contentsOf: getAlbumsWith( with: .album, subtype: .albumRegular ));
        albumEncodings.append(contentsOf: getAlbumsWith( with: .album, subtype: .albumSyncedEvent ));
        albumEncodings.append(contentsOf: getAlbumsWith( with: .album, subtype: .albumSyncedFaces));
        albumEncodings.append(contentsOf: getAlbumsWith( with: .album, subtype: .albumSyncedAlbum ));
        albumEncodings.append(contentsOf: getAlbumsWith( with: .album, subtype: .albumImported ));
        albumEncodings.append(contentsOf: getAlbumsWith( with: .album, subtype: .albumCloudShared ));

        result(albumEncodings)
    }
    
    private func getAlbumsWith( with: PHAssetCollectionType, subtype: PHAssetCollectionSubtype) -> [String] {
        let albums = PHAssetCollection.fetchAssetCollections(with: with, subtype: subtype, options: nil)
        var albumEncodings = [String]();
        albums.enumerateObjects{(object: AnyObject!,
        count: Int,
        stop: UnsafeMutablePointer<ObjCBool>) in
            if object is PHAssetCollection {
                let collection = object as! PHAssetCollection
                let imageOptions = PHFetchOptions()
                imageOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
                imageOptions.sortDescriptors = [NSSortDescriptor( key: "creationDate", ascending: false )]
                let containedImgs = PHAsset.fetchAssets(in: collection, options: imageOptions )
                var coverImgId = ""
                if let lastImg = containedImgs.firstObject {
                    coverImgId = lastImg.localIdentifier
                    var title = "n/a"
                    if let localizedTitle = collection.localizedTitle {
                        title = localizedTitle;
                    }
                    let albumJson = """
                    {"id":"\(collection.localIdentifier)",
                    "title":"\(title)",
                    "coverImgId":"\(coverImgId)"}
                    """;
                    albumEncodings.append( albumJson )
                }
            }
        }
        return albumEncodings
    }
    
    private func getLatestImages( _ maxPhotos: Int, _ result: @escaping FlutterResult) {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.fetchLimit = maxPhotos
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
        var photoIds = [String]();
        let df = ISO8601DateFormatter();
        allPhotos.enumerateObjects{(object: AnyObject!,
            count: Int,
            stop: UnsafeMutablePointer<ObjCBool>) in
            
            if object is PHAsset{
                let asset = object as! PHAsset
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
