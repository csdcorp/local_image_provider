import 'dart:async';
import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel_local_image_provider.dart';
import 'local_album_type.dart';

/// The interface that implementations of local_image_provider must implement.
///
/// Platform implementations should extend this class rather than implement it as `local_image_provider`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [LocalImageProviderPlatform] methods.
abstract class LocalImageProviderPlatform extends PlatformInterface {
  static const int cacheAtAnySize = 0;
  static const int cacheSuggestedCutoff = 800;

  /// Constructs a LocalImageProviderPlatform.
  LocalImageProviderPlatform() : super(token: _token);

  static final Object _token = Object();

  static LocalImageProviderPlatform _instance =
      MethodChannelLocalImageProvider();

  /// The default instance of [LocalImageProviderPlatform] to use.
  ///
  /// Defaults to [MethodChannelLocalImageProvider].
  static LocalImageProviderPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [LocalImageProviderPlatform] when they register themselves.
  static set instance(LocalImageProviderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
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

  Future<bool> hasPermission() {
    throw UnimplementedError();
  }

  Future<bool> hasLimitedPermission() {
    throw UnimplementedError();
  }

  Future<bool> initialize() {
    throw UnimplementedError();
  }

  Future<List<String>> findAlbums(LocalAlbumType localAlbumType) {
    throw UnimplementedError();
  }

  Future<List<String>> findLatest(int maxImages) {
    throw UnimplementedError();
  }

  Future<List<String>> findImagesInAlbum(String albumId, int maxImages) {
    throw UnimplementedError();
  }

  Future<Uint8List> imageBytes(String id, int height, int width,
      {int compression}) {
    throw UnimplementedError();
  }

  Future<String> videoFile(String id) {
    throw UnimplementedError();
  }

  Future cleanup() {
    throw UnimplementedError();
  }
}
