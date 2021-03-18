import 'dart:typed_data';

import 'package:local_image_provider_platform_interface/local_album_type.dart';
import 'package:local_image_provider_platform_interface/local_image_provider_platform_interface.dart';

class TestLocalImageProvider extends LocalImageProviderPlatform {
  bool permissionResult = true;
  bool hasLimitedResult = false;
  bool initResult = true;
  bool cleanedUp = false;
  bool invoked = false;
  List<String> albums = [];
  List<String> latestImages = [];
  List<String> albumImages = [];
  Uint8List? imgBytes = Uint8List(0);
  String videoFileResult = '';
  String? requestedImgId;
  int? requestedHeight;
  int? requestedWidth;
  int? requestedCompression;

  @override
  Future<bool> hasPermission() async {
    invoked = true;
    return permissionResult;
  }

  @override
  Future<bool> hasLimitedPermission() async {
    invoked = true;
    return hasLimitedResult;
  }

  @override
  Future<bool> initialize() async {
    invoked = true;
    return initResult;
  }

  @override
  Future<List<String>> findAlbums(LocalAlbumType localAlbumType) async {
    invoked = true;
    return albums;
  }

  @override
  Future<List<String>> findLatest(int maxImages) async {
    invoked = true;
    return latestImages;
  }

  @override
  Future<List<String>> findImagesInAlbum(String albumId, int maxImages) async {
    invoked = true;
    return albumImages;
  }

  @override
  Future<Uint8List?> imageBytes(String id, int height, int width,
      {int? compression}) async {
    requestedImgId = id;
    requestedHeight = height;
    requestedWidth = width;
    requestedCompression = compression;
    invoked = true;
    return imgBytes;
  }

  @override
  Future<String> videoFile(String id) async {
    invoked = true;
    return videoFileResult;
  }

  @override
  Future cleanup() async {
    invoked = true;
    cleanedUp = true;
  }
}
