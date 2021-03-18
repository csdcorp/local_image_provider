import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:local_image_provider_platform_interface/local_album_type.dart';

import 'local_image_provider_platform_interface.dart';

const MethodChannel _channel =
    MethodChannel('plugin.csdcorp.com/local_image_provider');

/// An implementation of [LocalImageProviderPlatform] that uses method channels.
class MethodChannelLocalImageProvider extends LocalImageProviderPlatform {
  @override
  Future<bool> hasPermission() {
    return _channel.invokeMethod<bool>('has_permission');
  }

  @override
  Future<bool> hasLimitedPermission() {
    return _channel.invokeMethod<bool>('has_limited_permission');
  }

  @override
  Future<bool> initialize() {
    return _channel.invokeMethod<bool>('initialize');
  }

  @override
  Future<List<String>> findAlbums(LocalAlbumType localAlbumType) async {
    return _toStringList(await _channel.invokeMethod<List<dynamic>>(
        'albums', localAlbumType.value));
  }

  @override
  Future<List<String>> findLatest(int maxImages) async {
    return _toStringList(
        await _channel.invokeMethod<List<dynamic>>('latest_images', maxImages));
  }

  @override
  Future<List<String>> findImagesInAlbum(String albumId, int maxImages) async {
    return _toStringList(await _channel.invokeMethod<List<dynamic>>(
        'images_in_album', {'albumId': albumId, 'maxImages': maxImages}));
  }

  @override
  Future<Uint8List> imageBytes(String id, int height, int width,
      {int compression}) async {
    return _channel.invokeMethod<Uint8List>('image_bytes', {
      'id': id,
      'pixelHeight': height,
      'pixelWidth': width,
      'compression': compression
    });
  }

  @override
  Future<String> videoFile(String id) {
    return _channel.invokeMethod<String>('video_file', {'id': id});
  }

  @override
  Future cleanup() {
    return _channel.invokeMethod<void>('cleanup');
  }

  List<String> _toStringList(List<dynamic> dynList) {
    return dynList
        .where((element) => element is String)
        .map((element) => element as String)
        .toList();
  }
}
