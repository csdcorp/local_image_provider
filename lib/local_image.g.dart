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
    json['fileName'] as String,
    json['fileSize'] as int,
    json['mediaType'] as String,
    compression: json['compression'] as int,
  );
}

Map<String, dynamic> _$LocalImageToJson(LocalImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pixelHeight': instance.pixelHeight,
      'pixelWidth': instance.pixelWidth,
      'creationDate': instance.creationDate,
      'fileName': instance.fileName,
      'fileSize': instance.fileSize,
      'mediaType': instance.mediaType,
      'compression': instance.compression,
    };
