import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:local_image_provider/local_image.dart';

class LocalImageProvider {
  static const MethodChannel _channel =
      const MethodChannel('local_image_provider');

  static Future<bool> requestPermission( ) async {
    final bool permission = await _channel.invokeMethod('request_permission');
    return permission;
  }

  static Future<List<LocalImage>> getLatest( int maxPhotos ) async {
    final List<dynamic> photoIds = await _channel.invokeMethod('latest_images', maxPhotos );
    return photoIds.map((photoJson)  { 
      print( photoJson );
      Map<String,dynamic> photoMap = jsonDecode(photoJson );
      return LocalImage.fromJson(photoMap);}
      ).toList();
  }

  static Future<Uint8List> photoImage( String id, int height, int width ) async {
    final Uint8List photoBytes = await _channel.invokeMethod('photo_image', {'id':id,'pixelHeight':height,'pixelWidth':width });
    return photoBytes;
  }
}
