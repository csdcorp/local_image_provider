// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_album.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalAlbum _$LocalAlbumFromJson(Map<String, dynamic> json) {
  return LocalAlbum(json['id'] as String, json['coverImgId'] as String,
      json['title'] as String);
}

Map<String, dynamic> _$LocalAlbumToJson(LocalAlbum instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'coverImgId': instance.coverImgId
    };
