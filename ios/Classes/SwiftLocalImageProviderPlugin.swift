import Flutter
import UIKit
import Photos

public enum LocalImageProviderMethods: String {
    case initialize
    case latest_images
    case image_bytes
    case video_file
    case cleanup
    case images_in_album
    case albums
    case has_permission
    case unknown // just for testing
}

public enum LocalImageProviderErrors: String {
    case imgLoadFailed
    case imgNotFound
    case missingOrInvalidArg
    case unimplemented
}

public enum LocalImageAlbumType: Int {
    case all
    case album
    case user
    case generated
    case faces
    case event
    case imported
    case shared
}

@available(iOS 10.0, *)
public class SwiftLocalImageProviderPlugin: NSObject, FlutterPlugin {
    var imageManager: PHImageManager?
    let isoDf = ISO8601DateFormatter()
    let subtypeToSource: [PHAssetCollectionSubtype: LocalImageAlbumType] = [
        PHAssetCollectionSubtype.albumRegular: LocalImageAlbumType.user,
        PHAssetCollectionSubtype.albumSyncedEvent: LocalImageAlbumType.event,
        PHAssetCollectionSubtype.albumSyncedFaces: LocalImageAlbumType.faces,
        PHAssetCollectionSubtype.albumSyncedAlbum: LocalImageAlbumType.generated,
        PHAssetCollectionSubtype.albumImported: LocalImageAlbumType.imported,
        PHAssetCollectionSubtype.albumCloudShared: LocalImageAlbumType.shared,
    ]
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "plugin.csdcorp.com/local_image_provider", binaryMessenger: registrar.messenger())
        let instance = SwiftLocalImageProviderPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case LocalImageProviderMethods.has_permission.rawValue:
            hasPermission( result )
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
            let compression = argsArr["compression"] as? Int
            getPhotoImage( localId, height, width, compression ?? 70, result)
        case LocalImageProviderMethods.video_file.rawValue:
            guard let argsArr = call.arguments as? Dictionary<String,AnyObject>,
                let localId = argsArr["id"] as? String
                else {
                    result(FlutterError( code: LocalImageProviderErrors.missingOrInvalidArg.rawValue,
                                         message:"Missing args requires id",
                                         details: nil ))
                    return
            }
            getVideoFile( localId, result)
        case LocalImageProviderMethods.cleanup.rawValue:
            cleanup( result)
        default:
            print("Unrecognized method: \(call.method)")
            result( FlutterMethodNotImplemented)
        }
        // result("iOS Photos min" )
    }
    
    private func hasPermission(_ result: @escaping FlutterResult) {
        if ( PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized ) {
            result( true )
        }
        result( false )
    }
    
    private func initialize(_ result: @escaping FlutterResult) {
        var authorized = false
        let currentAuth = PHPhotoLibrary.authorizationStatus()
        if ( currentAuth == PHAuthorizationStatus.notDetermined ) {
            PHPhotoLibrary.requestAuthorization({(status)->Void in
                authorized = status == PHAuthorizationStatus.authorized
                self.handleInitResult( authorized, result )
            })
        }
        else {
            authorized = currentAuth == PHAuthorizationStatus.authorized
            handleInitResult( authorized, result )
        }
    }
    
    /// Note that authorized is initilally null, it must be set in this method or subsequent use will fail
    private func handleInitResult( _ authorized: Bool, _ result: @escaping FlutterResult ) {
        if ( authorized ) {
            imageManager = PHImageManager.default()
        }
        result( authorized )
    }
    
    private func getAlbums( _ rawAlbumType: Int, _ result: @escaping FlutterResult) {
        let albumType = LocalImageAlbumType(rawValue: rawAlbumType)
        var albumEncodings = [String]();
        switch albumType {
        case .user:
            albumEncodings.append(contentsOf: getAlbumsWith( with: .album, subtype: .albumRegular));
        case .faces:
            albumEncodings.append(contentsOf: getAlbumsWith( with: .album, subtype: .albumSyncedFaces));
        case .event:
            albumEncodings.append(contentsOf: getAlbumsWith( with: .album, subtype: .albumSyncedEvent));
        case .album:
            albumEncodings.append(contentsOf: getAlbumsWith( with: .album, subtype: .albumSyncedAlbum));
        case .generated:
            albumEncodings.append(contentsOf: getAlbumsWith( with: .album, subtype: .albumSyncedEvent ));
            albumEncodings.append(contentsOf: getAlbumsWith( with: .album, subtype: .albumSyncedFaces));
            albumEncodings.append(contentsOf: getAlbumsWith( with: .album, subtype: .albumSyncedAlbum ));
        case .imported:
            albumEncodings.append(contentsOf: getAlbumsWith( with: .album, subtype: .albumImported));
        case .shared:
            albumEncodings.append(contentsOf: getAlbumsWith( with: .album, subtype: .albumCloudShared));
        default:
            albumEncodings.append(contentsOf: getAlbumsWith( with: .album, subtype: .albumRegular ));
            albumEncodings.append(contentsOf: getAlbumsWith( with: .album, subtype: .albumSyncedEvent ));
            albumEncodings.append(contentsOf: getAlbumsWith( with: .album, subtype: .albumSyncedFaces));
            albumEncodings.append(contentsOf: getAlbumsWith( with: .album, subtype: .albumSyncedAlbum ));
            albumEncodings.append(contentsOf: getAlbumsWith( with: .album, subtype: .albumImported ));
            albumEncodings.append(contentsOf: getAlbumsWith( with: .album, subtype: .albumCloudShared ));
        }
        
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
                let containedImages = self.findContainedMedia( assetCollection: collection, mediaType: PHAssetMediaType.image )
                let containedVideos = self.findContainedMedia( assetCollection: collection, mediaType: PHAssetMediaType.video )
                
                if let lastImg = containedImages.count > 0 ? containedImages.firstObject : containedVideos.firstObject {
                    var title = "n/a"
                    if let localizedTitle = collection.localizedTitle {
                        title = localizedTitle
                    }
                    let albumJson = """
                    {"id":"\(collection.localIdentifier)",
                    "title":"\(title)",
                    "coverImg":\(self.imageToJson( lastImg )),
                    "imageCount":\(containedImages.count),
                    "videoCount":\(containedVideos.count),
                    "transferType":\(self.subtypeToSource[subtype]?.rawValue ?? LocalImageAlbumType.album.rawValue)
                    }
                    """;
                    albumEncodings.append( albumJson )
                }
            }
        }
        return albumEncodings
    }
    
    private func findContainedMedia( assetCollection: PHAssetCollection, mediaType: PHAssetMediaType ) ->  PHFetchResult<PHAsset> {
        let imageOptions = PHFetchOptions()
        imageOptions.predicate = NSPredicate(format: "mediaType = %d", mediaType.rawValue)
        imageOptions.sortDescriptors = [NSSortDescriptor( key: "creationDate", ascending: false )]
        return PHAsset.fetchAssets(in: assetCollection, options: imageOptions )
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
                if ( asset.mediaType == PHAssetMediaType.image || asset.mediaType == PHAssetMediaType.video ) {
                    photosJson.append( self.imageToJson( asset) )
                }
            }
        }
        return photosJson
    }
    
    private func imageToJson( _ asset: PHAsset ) -> String {
        let creationDate = isoDf.string(from: asset.creationDate!)
        var fileName = asset.fileName
        let fileSize = asset.fileSize
        var mediaType = "img"
        if ( asset.mediaType == PHAssetMediaType.video ) {
            mediaType = "video"
        }
        return """
        {"id":"\(asset.localIdentifier)",
        "creationDate":"\(creationDate)",
        "pixelWidth":\(asset.pixelWidth),
        "pixelHeight":\(asset.pixelHeight),
        "fileName":"\(fileName)",
        "fileSize":\(fileSize),
        "mediaType":"\(mediaType)"
        }
        """
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
    
    private func getVideoFile(_ id: String, _ flutterResult: @escaping FlutterResult) {
        let fetchOptions = PHFetchOptions()
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: fetchOptions )
        if ( 1 == fetchResult.count ) {
            let asset = fetchResult.firstObject!
            let requestOptions = PHVideoRequestOptions()
            requestOptions.deliveryMode = .mediumQualityFormat
            imageManager?.requestExportSession(forVideo: asset, options: requestOptions, exportPreset: AVAssetExportPresetPassthrough, resultHandler: { (exportSession, info)->Void in
                if let resultInfo = info
                {
                    if let error = resultInfo[PHImageErrorKey] as? Bool {
                        if error {
                            DispatchQueue.main.async {
                                flutterResult(FlutterError( code: LocalImageProviderErrors.imgLoadFailed.rawValue, message: "request video failed: \(id) ", details: nil ))
                            }
                            return
                        }
                    }
                }
                let tempPath = self.getTemporaryPath()
                let outputFile = tempPath.appendingPathComponent(UUID().uuidString)
                let finalFile = outputFile.appendingPathExtension("mov")
                exportSession?.outputURL = finalFile
                exportSession?.outputFileType = AVFileType.mov
                exportSession?.exportAsynchronously {
                    flutterResult( finalFile.path)
                }
            });
        }
        else {
            DispatchQueue.main.async {
                flutterResult(FlutterError( code: LocalImageProviderErrors.imgNotFound.rawValue, message:"Video not found: \(id)", details: nil ))
            }
        }
    }
    
    private func cleanup( _ flutterResult: @escaping FlutterResult) {
        let tempPath = getTemporaryPath()
        guard let filePaths = try? FileManager.default.contentsOfDirectory(at: tempPath, includingPropertiesForKeys: nil, options: []) else { return }
        for filePath in filePaths {
            try? FileManager.default.removeItem(at: filePath)
        }
        DispatchQueue.main.async {
            flutterResult( true )
        }
    }

    private func getTemporaryPath() -> URL {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let tempDir = paths[0]
        let tempPath = tempDir.appendingPathComponent("csdcorp_lip")
        if !FileManager.default.fileExists(atPath: tempPath.path) {
                do {
                    try FileManager.default.createDirectory(atPath: tempPath.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    NSLog("Couldn't create folder in tmp directory")
                    NSLog("==> directory is: \(tempPath)")
                }
            }        
        return tempPath
    }   

    private func getPhotoImage(_ id: String, _ pixelHeight: Int, _ pixelWidth: Int, _ compression: Int, _ flutterResult: @escaping FlutterResult) {
        let fetchOptions = PHFetchOptions()
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: fetchOptions )
        if ( 1 == fetchResult.count ) {
            let asset = fetchResult.firstObject!
            let targetSize = CGSize( width: pixelWidth, height: pixelHeight )
            let contentMode = PHImageContentMode.aspectFit
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = false
            requestOptions.isNetworkAccessAllowed = true
            requestOptions.resizeMode = PHImageRequestOptionsResizeMode.fast
            requestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
            imageManager?.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: requestOptions, resultHandler: {(result, info)->Void in
                if let resultInfo = info
                {
                    let degraded = resultInfo[PHImageResultIsDegradedKey] as? Bool
                    if ( degraded ?? false ) {
                        return
                    }
                    if let error = resultInfo[PHImageErrorKey] {
                        DispatchQueue.main.async {
                            flutterResult(FlutterError( code: LocalImageProviderErrors.imgLoadFailed.rawValue, message: "request image failed: \(id) \(error) - \(pixelHeight)x\(pixelWidth)", details: nil ))
                        }                    }
                }
                var details = "";
                if let image = result {
                    if image.cgImage == nil {
                        //                        guard let ciImage = image.ciImage, let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else { return }
                        //                        image.cgImage = cgImage;
                        details = "cgImage nil"
                    }
                    
                    if let data = image.jpegData(compressionQuality: CGFloat(compression / 100)) {
                        let typedData = FlutterStandardTypedData( bytes: data );
                        DispatchQueue.main.async {
                            flutterResult( typedData)
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            flutterResult(FlutterError( code: LocalImageProviderErrors.imgLoadFailed.rawValue, message: "Could not convert image: \(id) \(details) - \(pixelHeight)x\(pixelWidth)", details: details ))
                        }
                    }
                    
                }
                else {
                    print("Could not load")
                    DispatchQueue.main.async {
                        flutterResult(FlutterError( code: LocalImageProviderErrors.imgLoadFailed.rawValue, message: "Could not load image: \(id)", details: details ))
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

extension PHAsset {
    var fileSize: Int {
        get {
            if #available(iOS 9, *) {
                let resource = PHAssetResource.assetResources(for: self)
                if nil != resource.first {
                    let imageSizeByte = resource.first?.value(forKey: "fileSize") as! Int
                    return imageSizeByte
                }
            }
            return 0
        }
    }
    var fileName: String {
        get {
            if #available(iOS 9, *) {
                let resource = PHAssetResource.assetResources(for: self)
                if nil != resource.first {
                    if let fileName = resource.first?.originalFilename {
                        return fileName
                    }
                }
            }
            return ""
        }
    }
}
