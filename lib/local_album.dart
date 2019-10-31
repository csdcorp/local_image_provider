import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:local_image_provider/local_image.dart';
import 'package:local_image_provider/local_image_provider.dart';

part 'local_album.g.dart';

class LocalAlbumType {
  const LocalAlbumType._(this.value);
  static LocalAlbumType fromInt(int value) {
    if (value < values.length) {
      return values[value];
    }
    return null;
  }

  final int value;

  static const LocalAlbumType all = LocalAlbumType._(0);
  static const LocalAlbumType user = LocalAlbumType._(1);
  static const LocalAlbumType generated = LocalAlbumType._(0);
  static const List<LocalAlbumType> values = <LocalAlbumType>[
    all,
    user,
    generated,
  ];
}

/// A single album of images on the device.
///
/// Each album has an [id] which uniquely identifies it on the
/// local device.
@JsonSerializable(explicitToJson: true)
class LocalAlbum {
  /// A unique identifier for the album on the device
  final String id;

  /// A descriptive title for the album
  final String title;

  /// The number of images contained in the album
  final int imageCount;
  @Deprecated('The [coverImg] property will replace this in the next version.')
  String get coverImgId => coverImg.id;

  /// An image that can be used as a cover for the album.
  ///
  /// The [LocalImageProvider] implementation picks the newest image in the album.
  /// To load the image see the [DeviceImage] class.
  final LocalImage coverImg;

  const LocalAlbum(this.id, this.coverImg, this.title, this.imageCount);

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
      int pixelHeight, int pixelWidth) async {
    return localImageProvider.imageBytes(coverImg.id, pixelHeight, pixelWidth);
  }

  factory LocalAlbum.fromJson(Map<String, dynamic> json) =>
      _$LocalAlbumFromJson(json);
  Map<String, dynamic> toJson() => _$LocalAlbumToJson(this);
}
