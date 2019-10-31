// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalImage _$LocalImageFromJson(Map<String, dynamic> json) {
  return LocalImage(
    json['id'] as String,
    json['creationDate'] as String,
    json['pixelHeight'] as int,
    json['pixelWidth'] as int,
  );
}

Map<String, dynamic> _$LocalImageToJson(LocalImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pixelWidth': instance.pixelWidth,
      'pixelHeight': instance.pixelHeight,
      'creationDate': instance.creationDate,
    };
