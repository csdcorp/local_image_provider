import Flutter
import UIKit
import Photos

public enum LocalImageProviderMethods: String {
    case initialize
    case latest_images
    case image_bytes
    case images_in_album
    case albums
    case unknown // just for testing
}

public enum LocalImageProviderErrors: String {
    case imgLoadFailed
    case imgNotFound
    case missingOrInvalidArg
    case unimplemented
}

@available(iOS 10.0, *)
public class SwiftLocalImageProviderPlugin: NSObject, FlutterPlugin {
  let imageManager = PHImageManager.default()
  let isoDf = ISO8601DateFormatter()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "plugin.csdcorp.com/local_image_provider", binaryMessenger: registrar.messenger())
    let instance = SwiftLocalImageProviderPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case LocalImageProviderMethods.initialize.rawValue:
        initialize( result )
    case LocalImageProviderMethods.albums.rawValue:
        guard let albumType = call.arguments as? Int else {
            result(FlutterError( code: LocalImageProviderErrors.missingOrInvalidArg.rawValue,
                message:"Missing arg albumType",
                details: nil ))
            return
        }
        getAlbums( albumType, result)
    case LocalImageProviderMethods.latest_images.rawValue:
        guard let maxImages = call.arguments as? Int else {
            result(FlutterError( code: LocalImageProviderErrors.missingOrInvalidArg.rawValue,
                message:"Missing arg maxPhotos",
                details: nil ))
            return
        }
        getLatestImages( maxImages, result);
    case LocalImageProviderMethods.images_in_album.rawValue:
        guard let argsArr = call.arguments as? Dictionary<String,AnyObject>,
            let albumId = argsArr["albumId"] as? String,
            let maxImages = argsArr["maxImages"] as? Int
            else {
            result(FlutterError( code: LocalImageProviderErrors.missingOrInvalidArg.rawValue,
                message:"Missing arg maxPhotos",
                details: nil ))
            return
        }
        getImagesInAlbum( albumId: albumId, maxImages: maxImages, result);
    case LocalImageProviderMethods.image_bytes.rawValue:
        guard let argsArr = call.arguments as? Dictionary<String,AnyObject>,
            let localId = argsArr["id"] as? String,
            let width = argsArr["pixelWidth"] as? Int,
            let height = argsArr["pixelHeight"] as? Int
            else {
                result(FlutterError( code: LocalImageProviderErrors.missingOrInvalidArg.rawValue,
                    message:"Missing args requires id, pixelWidth, pixelHeight",
                    details: nil ))
                return
        }
        getPhotoImage( localId, width, height, result)
    default:
        print("Unrecognized method: \(call.method)")
        result( FlutterMethodNotImplemented)
    }
  // result("iOS Photos min" )
  }
    
    private func initialize(_ result: @escaping FlutterResult) {
        if ( PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.notDetermined ) {
            PHPhotoLibrary.requestAuthorization({(status)->Void in
                result( status == PHAuthorizationStatus.authorized )
            });
        }
        else {
            result( true )
        }
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
                if let lastImg = containedImgs.firstObject {
                    var title = "n/a"
                    if let localizedTitle = collection.localizedTitle {
                        title = localizedTitle
                    }
                    let albumJson = """
                    {"id":"\(collection.localIdentifier)",
                    "title":"\(title)",
                    "coverImg":\(self.imageToJson( lastImg )),
                    "imageCount":\(containedImgs.count)}
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
        let photos = imagesToJson( allPhotos )
        result( photos )
    }

    private func imagesToJson( _ images: PHFetchResult<PHAsset> ) -> [String] {
        var photosJson = [String]()
        images.enumerateObjects{(object: AnyObject!,
            count: Int,
            stop: UnsafeMutablePointer<ObjCBool>) in
            
            if object is PHAsset{
                let asset = object as! PHAsset
                photosJson.append( self.imageToJson( asset) )
            }
        }
        return photosJson
    }
    
    private func imageToJson( _ asset: PHAsset ) -> String {
        let creationDate = isoDf.string(from: asset.creationDate!);
        return """
        {"id":"\(asset.localIdentifier)",
        "creationDate":"\(creationDate)",
        "pixelWidth":\(asset.pixelWidth),
        "pixelHeight":\(asset.pixelHeight)}
        """;
    }
    
    private func getImagesInAlbum( albumId: String, maxImages: Int, _ result: @escaping FlutterResult) {
        var photos = [String]()
        let albumOptions = PHFetchOptions()
        let albumResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumId], options: albumOptions )
        guard albumResult.count > 0 else {
            result( photos )
            return
        }
        if let album = albumResult.firstObject {
            let allPhotosOptions = PHFetchOptions()
            allPhotosOptions.fetchLimit = maxImages
            allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let albumPhotos = PHAsset.fetchAssets(in: album, options: allPhotosOptions)
            photos = imagesToJson( albumPhotos )
        }
       result( photos )
    }

    private func getPhotoImage(_ id: String, _ pixelHeight: Int, _ pixelWidth: Int, _ flutterResult: @escaping FlutterResult) {
        let fetchOptions = PHFetchOptions()
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: fetchOptions )
        if ( 1 == fetchResult.count ) {
            let asset = fetchResult.firstObject!
            let targetSize = CGSize( width: pixelWidth, height: pixelHeight )
            let contentMode = PHImageContentMode.aspectFit
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = false
            requestOptions.isNetworkAccessAllowed = true
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: requestOptions, resultHandler: {(result, info)->Void in
                if let resultInfo = info
                {
                    let degraded = resultInfo[PHImageResultIsDegradedKey] as? Bool
                    if ( degraded ?? false ) {
                        return
                    }
                }
                if let image = result {
                    let data = UIImageJPEGRepresentation(image, 0.7 );
                    let typedData = FlutterStandardTypedData( bytes: data! );
                    DispatchQueue.main.async {
                        flutterResult( typedData)
                    }
                }
                else {
                    print("Could not load")
                    DispatchQueue.main.async {
                        flutterResult(FlutterError( code: LocalImageProviderErrors.imgLoadFailed.rawValue, message: "Could not load image: \(id)", details: nil ))
                    }
                }
            });
        }
        else {
            DispatchQueue.main.async {
                flutterResult(FlutterError( code: LocalImageProviderErrors.imgNotFound.rawValue, message:"Image not found: \(id)", details: nil ))
            }
        }
    }
}
