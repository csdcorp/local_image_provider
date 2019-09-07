import 'dart:async';

import 'package:flutter/services.dart';

class LocalImageProvider {
  static const MethodChannel _channel =
      const MethodChannel('local_image_provider');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
