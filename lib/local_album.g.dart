// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_album.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalAlbum _$LocalAlbumFromJson(Map<String, dynamic> json) {
  return LocalAlbum(
    json['id'] as String,
    json['coverImg'] == null
        ? null
        : LocalImage.fromJson(json['coverImg'] as Map<String, dynamic>),
    json['title'] as String,
    json['imageCount'] as int,
  );
}

Map<String, dynamic> _$LocalAlbumToJson(LocalAlbum instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'imageCount': instance.imageCount,
      'coverImg': instance.coverImg?.toJson(),
    };
