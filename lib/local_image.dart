import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:local_image_provider/local_image_provider.dart';

part 'local_image.g.dart';

/// A single photo on the device.
/// 
/// Each photo has an id which uniquely identifies it on the 
/// local device. Using that id other information about the 
/// photo can be retrieved. 
@JsonSerializable()
class LocalImage {
  String id;
  int pixelWidth;
  int pixelHeight;
  String creationDate;

  LocalImage( this.id, this.creationDate, this.pixelWidth, this.pixelHeight);

  Future<Uint8List> getImageBytes( int desiredHeight, int desiredWidth ) async {
    return await LocalImageProvider.imageBytes(id, desiredHeight, desiredWidth);
  }

  factory LocalImage.fromJson(Map<String, dynamic> json) =>
      _$LocalImageFromJson(json);
  Map<String, dynamic> toJson() => _$LocalImageToJson(this);
}