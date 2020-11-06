import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:local_image_provider/local_album.dart';
import 'package:local_image_provider/local_image.dart';

/// An interface to get information from the local image storage on the device.
///
/// Use [LocalImageProvider] to query for albums and images.
/// The general flow is as follows:
/// ```dart
///   LocalImageProvider lip = LocalImageProvider();
///   await lip.initialize();
///   if ( lip.isAvailable ) {
///     List<LocalImage> images = await lip.findLatest(10);
///     if ( images.isNotEmpty) {
///       // Do stuff with the image
///     }
///   }
///   else {
///     print('Access denied.');
///   }
/// ```
class LocalImageProvider {
  @visibleForTesting
  static const int cacheAtAnySize = 0;
  static const int cacheSuggestedCutoff = 800;
  static const MethodChannel lipChannel =
      const MethodChannel('plugin.csdcorp.com/local_image_provider');

  static final LocalImageProvider _instance =
      LocalImageProvider.withMethodChannel(lipChannel);
  final MethodChannel channel;
  bool _initWorked = false;
  int _bytesLoaded = 0;
  int _totalLoadTime = 0;
  int _lastLoadTime = 0;
  final Stopwatch _stopwatch = Stopwatch();

  /// Returns the singleton instance of the [LocalImageProvider].
  factory LocalImageProvider() => _instance;
  @visibleForTesting
  LocalImageProvider.withMethodChannel(this.channel);

  /// True if [initialize] succeeded and the user granted
  /// permission to access local images.
  ///
  /// Use this property to determine if calls to the [LocalImageProvider]
  /// are availablle. If [isAvailable] is false then other calls with
  /// throw an [LocalImageProviderNotInitializedException] exception. This
  /// method can be called before [initialize] although it will
  /// return false.
  bool get isAvailable => _initWorked;

  /// Returns true if the user has already granted permission to access photos.
  ///
  /// This method can be called before [initialize] to check if permission
  /// has already been granted. If this returns false then the [initialize]
  /// call will prompt the user for permission if it is allowed to do so.
  /// Note that applications cannot ask for permission again if the user has
  /// denied them permission in the past.
  Future<bool> get hasPermission async {
    bool hasPermission = await channel.invokeMethod('has_permission');
    return hasPermission;
  }

  /// Returns true if all [DeviceImage] should be cached in the global
  /// Flutter imageCache.
  ///
  /// Set the [maxCacheDimension] to change this to false. For example, to have all
  /// images with either a height or width of <= 800 pixels be cached but
  /// avoid adding anything larger than that set [maxCacheDimension] to
  /// 800.
  bool get cacheAll => cacheAtAnySize == maxCacheDimension;

  /// The maximum size at which a [DeviceImage] should be cached in the global
  /// Flutter imageCache.
  ///
  /// For example, to have all images with either a height or width of <=
  /// 800 pixels be cached but avoid adding anything larger than that set
  /// [maxCacheDimension] to 800. To cache any image use the constant
  /// value [cacheAtAnySize]. The constant [cacheSuggestedCutoff] is a
  /// reasonable tradeoff but particular applications will have different
  /// expected sizes so tuning may be required. Looking at the size of
  /// thumbnails can be a good guide so that the thumbnails are cached
  /// while the fullsize images are not.
  ///
  /// The Flutter cache uses a lot of memory for large images since it caches
  /// them as bitmaps. For applications that are displaying a number of
  /// large images this may not be desirable, especially if those images
  /// are only displayed once. This property provides control over what images
  /// are put in cache. To avoid caching entirely set this value very high.
  /// Be aware that when displaying images in grids or lists the Flutter cache
  /// makes redraw during scrolling very smooth, without caching there will be
  /// redraw flicker.
  int maxCacheDimension = cacheAtAnySize;

  /// Initialize and request permission to use platform services.
  ///
  /// If this returns false then either the user has denied permission
  /// to use the platform services or the services are not available
  /// for some reason, possibly due to platform version.
  Future<bool> initialize() async {
    if (_initWorked) {
      return Future.value(_initWorked);
    }
    _initWorked = await channel.invokeMethod('initialize');
    return _initWorked;
  }

  /// Returns the list of [LocalAlbum] available on the device matching the [localAlbumType]
  Future<List<LocalAlbum>> findAlbums(LocalAlbumType localAlbumType) async {
    if (!_initWorked) {
      throw LocalImageProviderNotInitializedException();
    }
    final List<dynamic> albums =
        await channel.invokeMethod('albums', localAlbumType.value);
    return albums.map((albumJson) {
      // print(albumJson);
      Map<String, dynamic> photoMap = jsonDecode(albumJson);
      return LocalAlbum.fromJson(photoMap);
    }).toList();
  }

  /// Returns the newest images on the local device up to [maxImages] in length.
  ///
  /// This list may be empty if there are no images on the device or the
  /// user has denied permission to see their local images.
  Future<List<LocalImage>> findLatest(int maxImages) async {
    if (!_initWorked) {
      throw LocalImageProviderNotInitializedException();
    }
    final List<dynamic> images =
        await channel.invokeMethod('latest_images', maxImages);
    return _jsonToLocalImages(images);
  }

  /// Returns the images contained in the given album on the local device
  /// up to [maxImages] in length.
  ///
  /// This list may be empty if there are no images in the album or the
  /// user has denied permission to see their local images. If there are
  /// more images in the album than maxImages the list is silently truncated.
  /// Note that images are quite small and fast to load since they don't load
  /// the image contents just basic metadata, so it is usually safe to load a
  /// large number of images from an album if required.
  Future<List<LocalImage>> findImagesInAlbum(
      String albumId, int maxImages) async {
    if (!_initWorked) {
      throw LocalImageProviderNotInitializedException();
    }
    final List<dynamic> images = await channel.invokeMethod(
        'images_in_album', {'albumId': albumId, 'maxImages': maxImages});
    return _jsonToLocalImages(images);
  }

  /// Returns a version of the image at the given size in a jpeg format suitable for loading with
  /// [MemoryImage].
  ///
  /// The returned image will maintain its aspect ratio while fitting within the given dimensions
  /// [height], [width]. The [id] to use is available from a returned [LocalImage]. The image is
  /// sent from the device as a JPEG compressed at 0.7 quality, which is a reasonable tradeoff
  /// between quality and size. If displayed images look blurry or low quality try requesting
  /// more pixels, i.e. a larger value for [height] and [width].
  /// Instead of using this directly look at [DeviceImage] which creates an [ImageProvider] from
  /// a [LocalImage], suitable for use in a widget tree.
  Future<Uint8List> imageBytes(String id, int height, int width, { int compression }) async {
    if (!_initWorked) {
      throw LocalImageProviderNotInitializedException();
    }
    _stopwatch.reset();
    _stopwatch.start();
    final Uint8List photoBytes = await channel.invokeMethod(
        'image_bytes', {'id': id, 'pixelHeight': height, 'pixelWidth': width, 'compression': compression});
    _stopwatch.stop();
    _totalLoadTime += _stopwatch.elapsedMilliseconds;
    _lastLoadTime = _stopwatch.elapsedMilliseconds;
    _bytesLoaded += photoBytes.length;
    return photoBytes;
  }

  /// Returns a temporary file path for the requested video.
  ///
  /// Call this method to get a playable video file where [id] is from
  /// a [LocalImage] that has `isVideo` true. These files can be
  /// used for video playback using the `video_player` plugin
  /// for example. These files should either be moved or deleted by
  /// client code, or cleaned up occasionally using the [cleanup] method.
  Future<String> videoFile(String id) async {
    if (!_initWorked) {
      throw LocalImageProviderNotInitializedException();
    }
    _stopwatch.reset();
    _stopwatch.start();
    final String filePath =
        await channel.invokeMethod('video_file', {'id': id});
    _stopwatch.stop();
    _totalLoadTime += _stopwatch.elapsedMilliseconds;
    _lastLoadTime = _stopwatch.elapsedMilliseconds;
    return filePath;
  }

  /// Call this method to cleanup any temporary files that have been
  /// created by the image provider.
  ///
  /// After this method completes any file paths returned from
  /// [videoFile] or other methods will no longer be valid. Only call
  /// this method when you no longer depend on those files. Calling this
  /// at program startup is safe, or at a point when you have finished
  /// using all returned file paths.
  Future cleanup() async {
    if (!_initWorked) {
      throw LocalImageProviderNotInitializedException();
    }
    await channel.invokeMethod('cleanup');
  }

  /// Resets the [totalLoadTime], [lastLaodTime], and [imgBytesLoaded]
  /// stats to zero.
  void resetStats() {
    _totalLoadTime = 0;
    _lastLoadTime = 0;
    _bytesLoaded = 0;
  }

  /// Returns the total milliseconds spent in [imageBytes] since the last call
  /// to [resetStats].
  int get totalLoadTime => _totalLoadTime;

  /// Returns the milliseconds spent in the last call to [imageBytes] assuming
  /// that [resetStats] wasn't called after the last call.
  int get lastLoadTime => _lastLoadTime;

  /// Returns the total bytes loaded in [imageBytes] since the last call
  /// to [resetStats].
  int get imgBytesLoaded => _bytesLoaded;

  List<LocalImage> _jsonToLocalImages(List<dynamic> jsonImages) {
    return jsonImages.map((imageJson) {
      // print(imageJson);
      Map<String, dynamic> imageMap = jsonDecode(imageJson);
      return LocalImage.fromJson(imageMap);
    }).toList();
  }
}

/// Thrown when a method is called that requires successful
/// initialization first. See [initialize]
class LocalImageProviderNotInitializedException implements Exception {}
