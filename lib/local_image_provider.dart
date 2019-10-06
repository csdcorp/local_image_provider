import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:local_image_provider/local_album.dart';
import 'package:local_image_provider/local_image.dart';

/// An interface to get information from the local image storage on the device.
///
/// Use LocalImageProvider to query for albums and images
class LocalImageProvider {
  @visibleForTesting
  static const MethodChannel lipChannel =
      const MethodChannel('plugin.csdcorp.com/local_image_provider');

  static final LocalImageProvider _instance =
      LocalImageProvider.withMethodChannel(lipChannel);
  final MethodChannel channel;
  bool _initWorked = false;
  factory LocalImageProvider() => _instance;
  @visibleForTesting
  LocalImageProvider.withMethodChannel(this.channel);

  /// True if [initialize] succeeded
  bool get isAvailable => _initWorked;

  Future<bool> initialize() async {
    if (_initWorked) {
      return Future.value(_initWorked);
    }
    _initWorked = await channel.invokeMethod('initialize');
    return _initWorked;
  }

  /// Returns the list of [LocalAlbum] available on the device matching the [localAlbumType]
  Future<List<LocalAlbum>> getAlbums(LocalAlbumType localAlbumType) async {
    if (!_initWorked) {
      throw LocalImageProviderNotInitializedException();
    }
    final List<dynamic> albums =
        await channel.invokeMethod('albums', localAlbumType.value);
    return albums.map((albumJson) {
      print(albumJson);
      Map<String, dynamic> photoMap = jsonDecode(albumJson);
      return LocalAlbum.fromJson(photoMap);
    }).toList();
  }

  /// Returns the newest images on the local device up to [maxImages] in length.
  ///
  /// This list may be empty if there are no images on the device or the
  /// user has denied permission to see their local images.
  Future<List<LocalImage>> getLatest(int maxImages) async {
    if (!_initWorked) {
      throw LocalImageProviderNotInitializedException();
    }
    final List<dynamic> photos =
        await channel.invokeMethod('latest_images', maxImages);
    return photos.map((photoJson) {
      // print(photoJson);
      Map<String, dynamic> photoMap = jsonDecode(photoJson);
      return LocalImage.fromJson(photoMap);
    }).toList();
  }

  /// Returns the images contained in the given album on the local device
  /// up to [maxImages] in length.
  ///
  /// This list may be empty if there are no images in the album or the
  /// user has denied permission to see their local images.
  Future<List<LocalImage>> getImagesInAlbum(
      String albumId, int maxImages) async {
    if (!_initWorked) {
      throw LocalImageProviderNotInitializedException();
    }
    final List<dynamic> images = await channel.invokeMethod(
        'images_in_album', {'albumId': albumId, 'maxImages': maxImages});
    return images.map((imageJson) {
      // print(photoJson);
      Map<String, dynamic> imageMap = jsonDecode(imageJson);
      return LocalImage.fromJson(imageMap);
    }).toList();
  }

  /// Returns a version of the image at the given size in a jpeg format suitable for loading with
  /// [MemoryImage].
  ///
  /// The returned image will maintain its aspect ratio while fitting within the given dimensions
  /// [height], [width]. The [id] to use is available from a returned LocalImage.
  Future<Uint8List> imageBytes(String id, int height, int width) async {
    if (!_initWorked) {
      throw LocalImageProviderNotInitializedException();
    }
    final Uint8List photoBytes = await channel.invokeMethod(
        'image_bytes', {'id': id, 'pixelHeight': height, 'pixelWidth': width});
    return photoBytes;
  }
}

/// Thrown when a method is called that requires successful
/// initialization first. See [initialize]
class LocalImageProviderNotInitializedException implements Exception {}
