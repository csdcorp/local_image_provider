import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:local_image_provider/local_album.dart';
import 'package:local_image_provider/local_image.dart';

/// An interface to get information from the local image storage on the device.
class LocalImageProvider {
  static const MethodChannel _channel =
      const MethodChannel('local_image_provider');


  static Future<List<LocalAlbum>> getAlbums( LocalAlbumType localAlbumType ) async {
    final List<dynamic> albums = await _channel.invokeMethod('albums', localAlbumType.value );
    return albums.map((albumJson)  { 
      print( albumJson );
      Map<String,dynamic> photoMap = jsonDecode(albumJson );
      return LocalAlbum.fromJson(photoMap);}
      ).toList();
  }

  /// The newest images on the local device up to [maxPhotos] in length.
  /// 
  /// This list may be empty if there are no photos on the device or the 
  /// user has denied permission to see their local photos. 
  static Future<List<LocalImage>> getLatest( int maxPhotos ) async {
    final List<dynamic> photos = await _channel.invokeMethod('latest_images', maxPhotos );
    return photos.map((photoJson)  { 
      print( photoJson );
      Map<String,dynamic> photoMap = jsonDecode(photoJson );
      return LocalImage.fromJson(photoMap);}
      ).toList();
  }

  /// Returns a version of the image at the given size in a format suitable for loading with 
  /// [MemoryImage]. 
  /// 
  /// The returned image will maintain its aspect ratio while fitting within the given dimensions
  /// [height], [width]. The [id] provided is available from a returned LocalImage.
  static Future<Uint8List> imageBytes( String id, int height, int width ) async {
    final Uint8List photoBytes = await _channel.invokeMethod('image_bytes', {'id':id,'pixelHeight':height,'pixelWidth':width });
    return photoBytes;
  }
}
