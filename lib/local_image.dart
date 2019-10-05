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
  String creationDate;

  LocalImage(this.id, this.creationDate, this.pixelWidth, this.pixelHeight);

  /// Returns a jpeg of the image that can be loaded into a [MemoryImage].
  ///
  /// The resulting image will maintain its aspect ratio and fit
  /// within a [pixelHeight]x[pixelWidth] area.
  Future<Uint8List> getImageBytes(int desiredHeight, int desiredWidth) async {
    return await LocalImageProvider()
        .imageBytes(id, desiredHeight, desiredWidth);
  }

  factory LocalImage.fromJson(Map<String, dynamic> json) =>
      _$LocalImageFromJson(json);
  Map<String, dynamic> toJson() => _$LocalImageToJson(this);
}
