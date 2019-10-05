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
  factory LocalImageProvider() => _instance;
  @visibleForTesting
  LocalImageProvider.withMethodChannel(this.channel);

  /// Returns the list of [LocalAlbum] available on the device matching the [localAlbumType]
  Future<List<LocalAlbum>> getAlbums(
      LocalAlbumType localAlbumType) async {
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
  /// This list may be empty if there are no photos on the device or the
  /// user has denied permission to see their local photos.
  Future<List<LocalImage>> getLatest(int maxImages) async {
    final List<dynamic> photos =
        await channel.invokeMethod('latest_images', maxImages);
    return photos.map((photoJson) {
      print(photoJson);
      Map<String, dynamic> photoMap = jsonDecode(photoJson);
      return LocalImage.fromJson(photoMap);
    }).toList();
  }

  /// Returns a version of the image at the given size in a jpeg format suitable for loading with
  /// [MemoryImage].
  ///
  /// The returned image will maintain its aspect ratio while fitting within the given dimensions
  /// [height], [width]. The [id] to use is available from a returned LocalImage.
  Future<Uint8List> imageBytes(String id, int height, int width) async {
    final Uint8List photoBytes = await channel.invokeMethod(
        'image_bytes', {'id': id, 'pixelHeight': height, 'pixelWidth': width});
    return photoBytes;
  }
}
