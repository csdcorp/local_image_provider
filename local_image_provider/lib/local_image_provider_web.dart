import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:typed_data';

import 'package:local_image_provider_platform_interface/local_album_type.dart';
import 'package:local_image_provider_platform_interface/local_image_provider_platform_interface.dart';

/// An implementation of [LocalImageProviderPlatform] that uses method channels.
class WebLocalImageProviderPlugin extends LocalImageProviderPlatform {
  /// Registers this class as the default instance of [UrlLauncherPlatform].
  static void registerWith(Registrar registrar) {
    LocalImageProviderPlatform.instance = WebLocalImageProviderPlugin();
  }

  @override
  Future<bool> hasPermission() async {
    return true;
  }

  @override
  Future<bool> hasLimitedPermission() async {
    return false;
  }

  @override
  Future<bool> initialize() async {
    return true;
  }

  @override
  Future<List<String>> findAlbums(LocalAlbumType localAlbumType) async {
    return [];
  }

  @override
  Future<List<String>> findLatest(int maxImages) async {
    return [];
  }

  @override
  Future<List<String>> findImagesInAlbum(String albumId, int maxImages) async {
    return [];
  }

  @override
  Future<Uint8List> imageBytes(String id, int height, int width,
      {int? compression}) async {
    return Uint8List(0);
  }

  @override
  Future<String> videoFile(String id) async {
    return '';
  }

  @override
  Future cleanup() async {}
}
