import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:local_image_provider/local_image.dart';
import 'package:local_image_provider/local_image_provider.dart';

part 'local_album.g.dart';

class LocalAlbumType {
  const LocalAlbumType._(this.value);
  static LocalAlbumType fromInt(int value) {
    if (value == null) {
      return album;
    }
    if (value < values.length && value >= 0) {
      return values[value];
    }
    return album;
  }

  final int value;

  static const LocalAlbumType all = LocalAlbumType._(0);
  static const LocalAlbumType album = LocalAlbumType._(1);
  static const LocalAlbumType user = LocalAlbumType._(2);
  static const LocalAlbumType generated = LocalAlbumType._(3);
  static const LocalAlbumType faces = LocalAlbumType._(4);
  static const LocalAlbumType event = LocalAlbumType._(5);
  static const LocalAlbumType imported = LocalAlbumType._(6);
  static const LocalAlbumType shared = LocalAlbumType._(7);
  static const List<LocalAlbumType> values = <LocalAlbumType>[
    all,
    album,
    user,
    generated,
    faces,
    event,
    imported,
    shared,
  ];
}

/// A single album of images on the device.
///
/// Each album has an [id] which uniquely identifies it on the
/// local device.
@JsonSerializable(explicitToJson: true)
class LocalAlbum {
  static const int albumTransferType = 1;

  /// A unique identifier for the album on the device
  final String id;

  /// A descriptive title for the album
  final String title;

  /// The number of images contained in the album
  final int imageCount;

  /// The number of videos contained in the album
  final int videoCount;

  /// An image that can be used as a cover for the album.
  ///
  /// The [LocalImageProvider] implementation picks the newest image in the album.
  /// To load the image see the [DeviceImage] class.
  final LocalImage coverImg;

  final int transferType;

  const LocalAlbum(this.id, this.coverImg, this.title, this.imageCount,
      this.videoCount, this.transferType);

  LocalAlbumType get albumType => LocalAlbumType.fromInt(
      transferType != null ? transferType : albumTransferType);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is LocalAlbum) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode => id.hashCode;
  @override
  String toString() => '$runtimeType($id, title: $title)';

  /// Returns a jpeg of the cover image for the album
  /// that can be loaded into a [MemoryImage].
  ///
  /// The resulting image will maintain its aspect ratio and fit
  /// within a [pixelHeight]x[pixelWidth] area.
  Future<Uint8List> getCoverImage(LocalImageProvider localImageProvider,
      int pixelHeight, int pixelWidth, {int compression}) async {
    return localImageProvider.imageBytes(coverImg.id, pixelHeight, pixelWidth, compression: compression);
  }

  factory LocalAlbum.fromJson(Map<String, dynamic> json) =>
      _$LocalAlbumFromJson(json);
  Map<String, dynamic> toJson() => _$LocalAlbumToJson(this);
}
