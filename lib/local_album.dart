import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:local_image_provider/local_image_provider.dart';

part 'local_album.g.dart';

class LocalAlbumType {
  const LocalAlbumType._(this.value);
  static LocalAlbumType fromInt( int value ) {
    if ( value < values.length ) {
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

/// A single album on the device.
///
/// Each album has an id which uniquely identifies it on the
/// local device. Using that id other information about the
/// album can be retrieved.
@JsonSerializable()
class LocalAlbum {
  String id;
  String title;
  String coverImgId;

  LocalAlbum(this.id, this.coverImgId, this.title);
  Future<Uint8List> getCoverImage( int pixelHeight, int pixelWidth ) async {
    return LocalImageProvider.imageBytes(coverImgId, pixelHeight, pixelWidth );
  }

  factory LocalAlbum.fromJson(Map<String, dynamic> json) =>
      _$LocalAlbumFromJson(json);
  Map<String, dynamic> toJson() => _$LocalAlbumToJson(this);
}
