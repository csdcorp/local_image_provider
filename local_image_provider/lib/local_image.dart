import 'dart:math';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:local_image_provider/local_image_provider.dart';

part 'local_image.g.dart';

/// A single image on the local device.
///
/// Each photo has an id which uniquely identifies it on the
/// local device. Using that id other information about the
/// photo can be retrieved.
@JsonSerializable()
class LocalImage {
  static const String imageMediaType = 'img';
  static const String videoMediaType = 'video';

  /// Unique identifier for the image on the local device, this should
  /// be stable across invocations.
  final String id;

  /// pixel height of the image
  final int pixelHeight;

  /// pixel width of the image
  final int pixelWidth;

  /// optional image compression (0-100), default is set to 70
  final int compression;

  /// date the image was created as reported by the local device
  final String creationDate;

  /// Local filename for the image on the device
  final String fileName;

  /// Size in bytes of the image on disk
  final int fileSize;

  /// 'video' or 'img', use the isImage or isVideo properties instead
  /// of using this value directly
  final String mediaType;

  const LocalImage(this.id, this.creationDate, this.pixelHeight,
      this.pixelWidth, this.fileName, this.fileSize, this.mediaType,
      {this.compression});

  bool get isImage => imageMediaType == mediaType;
  bool get isVideo => videoMediaType == mediaType;

  /// Returns the scale required to fit the image into the given
  /// [height] and [width] in pixels.
  ///
  /// The scale is the lower of the vertical or horizontal scale.
  /// For example if the image [pixelHeight]x[pixelWidth] is 1000 x 2000
  /// and this was called with 100x250 then the correct scale would be
  /// 10% or 0.1 since 100/1000 = 0.1 while 250/2000 = 0.125, so the
  /// the 0.1 scale is the lower of the two.
  /// Use this with [DeviceImage] to find a scale for a particular
  /// desired screen resolution.
  double scaleToFit(int height, int width) {
    double vScale = height / pixelHeight;
    double hScale = width / pixelWidth;
    if (vScale >= 1 && hScale >= 1) {
      return 1.0;
    }
    return min(vScale, hScale);
  }

  /// Returns a jpeg scaled by the given scaling factor in each dimension.
  ///
  /// The resulting image will maintain its aspect ratio and fit
  /// within a [pixelHeight]*[scale] x [pixelWidth]*[scale] area.
  @Deprecated("See [DeviceImage] for a better way to load scaled images.")
  Future<Uint8List> getScaledImageBytes(
      LocalImageProvider localImageProvider, double scale) async {
    int scaledHeight = (pixelHeight * scale).round();
    int scaledWidth = (pixelWidth * scale).round();
    return getImageBytes(localImageProvider, scaledHeight, scaledWidth);
  }

  /// Returns a jpeg of the image that can be loaded into a [MemoryImage].
  ///
  /// The resulting image will maintain its aspect ratio and fit
  /// within a [pixelHeight]x[pixelWidth] area.
  @Deprecated("See [DeviceImage] for a better way to load the image contents.")
  Future<Uint8List> getImageBytes(LocalImageProvider localImageProvider,
      int desiredHeight, int desiredWidth) async {
    return await localImageProvider.imageBytes(id, desiredHeight, desiredWidth,
        compression: compression);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is LocalImage) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode => id.hashCode;
  @override
  String toString() =>
      '$runtimeType($id, creation: $creationDate, height: $pixelHeight, width: $pixelWidth)';

  factory LocalImage.fromJson(Map<String, dynamic> json) =>
      _$LocalImageFromJson(json);
  Map<String, dynamic> toJson() => _$LocalImageToJson(this);
}
