import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui show Codec;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:local_image_provider/local_image.dart';
import 'package:local_image_provider/local_image_provider.dart';

/// Decodes the given [LocalImage] object as an image, associating it with the given
/// scale.
///
class DeviceImage extends ImageProvider<DeviceImage> {
  /// Creates an object that decodes a [LocalImage] as an image.
  ///
  /// The arguments must not be null.
  const DeviceImage(this.localImage, {this.scale = 1.0})
      : assert(localImage != null),
        assert(scale != null);

  /// The LocalImage to decode into an image.
  final LocalImage localImage;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  @override
  Future<DeviceImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<DeviceImage>(this);
  }

  // @override
  ImageStreamCompleter load(DeviceImage key) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key),
      scale: key.scale,
      informationCollector: () sync* {
        yield ErrorDescription('Id: ${localImage?.id}');
      },
    );
  }

  Future<ui.Codec> _loadAsync(DeviceImage key) async {
    assert(key == this);
    int height = (localImage.pixelHeight * scale).round();
    int width = (localImage.pixelWidth * scale).round();
    final Uint8List bytes =
        await localImage.getImageBytes(LocalImageProvider(), height, width);
    if (bytes.lengthInBytes == 0) return null;

    return await instantiateImageCodec(bytes);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final DeviceImage typedOther = other;
    return localImage.id == typedOther.localImage.id &&
        scale == typedOther.scale;
  }

  @override
  int get hashCode => localImage.hashCode;

  @override
  String toString() => '$runtimeType($localImage, scale: $scale)';
}
