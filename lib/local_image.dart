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
  final String id;
  final int pixelWidth;
  final int pixelHeight;
  final String creationDate;

  const LocalImage(
      this.id, this.creationDate, this.pixelHeight, this.pixelWidth);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is LocalImage) {
      return id == other.id;
    }
    return false;
  }

  double scaleToFit(int height, int width) {
    double vScale = height / pixelHeight;
    double hScale = width / pixelWidth;
    if (vScale >= 1 && hScale >= 1) {
      return 1.0;
    }
    return min(vScale, hScale);
  }

  @override
  int get hashCode => id.hashCode;
  @override
  String toString() =>
      '$runtimeType($id, creation: $creationDate, height: $pixelHeight, width: $pixelWidth)';

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
    return await localImageProvider.imageBytes(id, desiredHeight, desiredWidth);
  }

  factory LocalImage.fromJson(Map<String, dynamic> json) =>
      _$LocalImageFromJson(json);
  Map<String, dynamic> toJson() => _$LocalImageToJson(this);
}
