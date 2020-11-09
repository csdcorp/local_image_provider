import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui show Codec;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
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
  static final String noImageBase64 =
      "iVBORw0KGgoAAAANSUhEUgAAABkAAAAZCAIAAABLixI0AAAAA3NCSVQICAjb4U/gAAADCUlEQVQ4ja2VT0zTYBTAX9dttB3b6AzFAEIlgEaH7gRxHIyBYGIkGMNAQpaBCdEYjiacPHD0QCQSlcSL8aaZhIN/4xBFlkVj5mY0hgMskwDyt5SNtdBu9VDp1m6AGt/p/fm+33vv+16/IpIkwX8S/d7hZCy2NTMtzs/rS0ryDlegZvPfs1IpZsQbuzeYYlcz3Yi5wNx1lex0I/ocG5HsHoWlxcUr3eLs9G75dYXF1NB9rLJyH5YkCHOdLnHme9qF6nU2SoqxEr+Zxh04WPLkGZqfr8qhYa/cvpUG6VBLb1+5P1z2Yrx8Mlh496GuoFCOpFZ/Lvff0NabafA8n3j9XDFN167j7R28IHAcx3GcruYEOXAnvTjwbovjcvSYSCS8Xi83NXX2lVcObOkMo+fbthFEk9z19BGWFGR9vKEFPW5vbW0lCAKUewyFQtFoFDBstLmDjMdNsY0UimaDiriEAkoCEsNxNhoNhUJOpzPNYhhGVqiq6tra2rW1Nb/fD/F4JsiYStmDHxSTMZMsqs/cqxoTDMNcLpfBYAAAk8k0MjKihMxJsf79WCG7LJsSwGzVMU3VKlZxcbEMAgCaptOgVPL0m5dkYl0Bfaup+3qIBrWoWJFIhGVZq9UKAOFwWGnNOeFTQADIRsulz4BClqhYkiQNDw/b7XaGYSKRiOys/zhJ7bQGANa+ftrVvuzzBQIBDUs7q9vb28FgcGFhQa6uQBRLF38oUUtvH+lqB4DGxsa6urp9WABAEITH4+np6aEoqmhlSfFjZ87Zui4rZlNTE4Zhe7EIgnC73RRF4TjudrtLd6YJAIw1JzWLEfUAqs4LRVEZpHCPnqrfnIvKZl71kewmdmUZjUYFJIvN023zdO+NyM0SBEFzO5a3Y8aJMVkX7Y71i22a9TlYJEkCgCiKPp8vM1wf+lSxPC/rK1/AZ7FllyPvBeXsHQ5H5qD/udA07XA4ZF31rvI8r3lm2aFB/vEDWTc4G2w3BzKjCIJkjoX229akRZov8FW/r89QVobj+B415vh3/LP8AvvVK04ZJmjyAAAAAElFTkSuQmCC";
  static final Uint8List noImageBytes = base64Decode(noImageBase64);

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
  const DeviceImage(this.localImage,
      {this.scale = 1.0, this.minPixels = 0, this.compression})
      : assert(localImage != null),
        assert(scale != null),
        assert(minPixels != null);

  /// The LocalImage to decode into an image.
  final LocalImage localImage;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  /// The minPixels to place in the [ImageInfo] object of the image.
  final int minPixels;

  /// Optional image compression (0-100), default is set to 70.
  final int compression;

  @override
  Future<DeviceImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<DeviceImage>(this);
  }

  @override
  ImageStreamCompleter load(DeviceImage key, DecoderCallback decoder) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decoder),
      scale: key.scale,
      informationCollector: () sync* {
        yield ErrorDescription('Id: ${localImage?.id}');
      },
    );
  }

  @override
  void resolveStreamForKey(ImageConfiguration configuration, ImageStream stream,
      DeviceImage key, ImageErrorListener handleError) {
    if (shouldCache()) {
      super.resolveStreamForKey(configuration, stream, key, handleError);
      return;
    }
    final ImageStreamCompleter completer =
        load(key, PaintingBinding.instance.instantiateImageCodec);
    if (completer != null) {
      stream.setCompleter(completer);
    }
  }

  int get height => max((localImage.pixelHeight * scale).round(), minPixels);
  int get width => max((localImage.pixelWidth * scale).round(), minPixels);

  @visibleForTesting
  bool shouldCache() {
    return LocalImageProvider().cacheAll ||
        max(height, width) <= LocalImageProvider().maxCacheDimension;
  }

  Future<ui.Codec> _loadAsync(DeviceImage key, DecoderCallback decoder) async {
    assert(key == this);
    try {
      final Uint8List bytes = await LocalImageProvider()
          .imageBytes(localImage.id, height, width, compression: compression);
      if (bytes.lengthInBytes == 0) return null;

      return await decoder(bytes);
    } on PlatformException {
      return await decoder(noImageBytes);
    }
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
