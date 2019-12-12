import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui show Codec;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:local_image_provider/local_image.dart';
import 'package:local_image_provider/local_image_provider.dart';

/// Decodes the given [LocalImage] object as an [ImageProvider], associating it with the given
/// scale.
///
///
/// In general only the constructor of this object should be used directly,
/// after that use the resulting object wherever an [ImageProvider] is
/// needed in Flutter. In particular with an [Image] widget.
///
class DeviceImage extends ImageProvider<DeviceImage> {
  /// Creates an object that decodes a [LocalImage] as an image.
  ///
  /// The arguments must not be null. [scale] returns a scaled down
  /// version of the image. For example to load a thumbnail you could
  /// use something like .1 as the scale. There's a convenience method
  /// on [LocalImage] that can calculate the scale for a given pixel
  /// size.
  /// [minPixels] can be used to specify a minimum independent of the
  /// requested scale. The idea is that scaling an image that you don't know
  /// the original size of can result in some results that are too small.
  /// If the goal is to display the image in a 50x50 thumbnail then you might
  /// want to set 50 as the minPixels, then regardless of the image size and
  /// scale you'll get at least 50 pixels in each dimension. This parameter
  /// was added as a result of a strange result in iOS where an image with
  /// a portrait aspect ratio was failing to load when scaled below 120 pixels.
  /// Setting 150 as the minimum in this case resolved the problem.
  const DeviceImage(this.localImage, {this.scale = 1.0, this.minPixels = 0})
      : assert(localImage != null),
        assert(scale != null),
        assert(minPixels != null);

  /// The LocalImage to decode into an image.
  final LocalImage localImage;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  /// The minPixels to place in the [ImageInfo] object of the image.
  final int minPixels;

  @override
  Future<DeviceImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<DeviceImage>(this);
  }

  @override
  ImageStreamCompleter load(DeviceImage key, DecoderCallback decoder ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decoder ),
      scale: key.scale,
      informationCollector: () sync* {
        yield ErrorDescription('Id: ${localImage?.id}');
      },
    );
  }

  Future<ui.Codec> _loadAsync(DeviceImage key, DecoderCallback decoder) async {
    assert(key == this);
    int height = max((localImage.pixelHeight * scale).round(), minPixels);
    int width = max((localImage.pixelWidth * scale).round(), minPixels);
    final Uint8List bytes =
        await LocalImageProvider().imageBytes(localImage.id, height, width);
    if (bytes.lengthInBytes == 0) return null;

    return await decoder(bytes);
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
