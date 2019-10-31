import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_image_provider/device_image.dart';
import 'package:local_image_provider/local_image.dart';
import 'package:local_image_provider/local_image_provider.dart';

void main() {
  const String testId1 = "id1";
  const String create1 = "2019-11-25";
  const int width1 = 100;
  const int height1 = 200;
  const String testId2 = "id2";
  const String create2 = "2019-10-17";
  const int width2 = 300;
  const int height2 = 600;
  const double scale80Percent = 0.8;
  const int width80Percent = 80;
  const int height80Percent = 160;
  const img1 = LocalImage(testId1, create1, height1, width1);
  const img2 = LocalImage(testId2, create2, height2, width2);
  String expectedToString =
      "DeviceImage(${img1.toString()}, scale: $scale80Percent)";
  String requestedImgId;
  int requestedHeight;
  int requestedWidth;
  Uint8List imageBytes;
  LocalImageProvider localImageProvider;

  setUp(() async {
    List<int> imgInt = "GIF89a,,,,,,,,,,,,,,,,;".codeUnits;
    imageBytes = Uint8List.fromList(imgInt);
    localImageProvider = LocalImageProvider();
    localImageProvider.channel
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == "initialize") {
        return true;
      } else if (methodCall.method == "image_bytes") {
        requestedImgId = methodCall.arguments["id"];
        requestedHeight = methodCall.arguments["pixelHeight"];
        requestedWidth = methodCall.arguments["pixelWidth"];
        return imageBytes;
      }
      return null;
    });
    await localImageProvider.initialize();
  });

  group('properties', () {
    test('set properly by constructor', () {
      var dImg1 = DeviceImage(img1);
      expect(dImg1.localImage, img1);
      expect(dImg1.scale, 1.0);
    });
    test('scale can be overridden', () {
      var dImg1 = DeviceImage(img1, scale: scale80Percent);
      expect(dImg1.localImage, img1);
      expect(dImg1.scale, scale80Percent);
    });
    test('hash works', () {
      var dImg1 = DeviceImage(img1);
      var dImg1a = DeviceImage(img1);
      var dImg2 = DeviceImage(img2);
      expect(dImg1.hashCode, dImg1.hashCode);
      expect(dImg1.hashCode, dImg1a.hashCode);
      expect(dImg1.hashCode, isNot(dImg2.hashCode));
    });
    test('equals works', () {
      var dImg1 = DeviceImage(img1);
      var dImg1a = DeviceImage(img1);
      var dImg2 = DeviceImage(img2);
      expect(dImg1, dImg1);
      expect(dImg1, dImg1a);
      expect(dImg1, isNot(dImg2));
    });
    test('equals differs by scale ', () {
      var dImg1 = DeviceImage(img1);
      var dImg1a = DeviceImage(img1, scale: scale80Percent);
      expect(dImg1, dImg1);
      expect(dImg1, isNot(dImg1a));
    });
    test('toString as expected', () {
      var dImg1 = DeviceImage(img1, scale: scale80Percent);
      expect(dImg1.toString(), expectedToString);
    });
    test('key as expected', () async {
      var dImg1 = DeviceImage(img1, scale: scale80Percent);
      var key = await dImg1.obtainKey(null);
      expect(key, dImg1);
    });
  });

  group('load', () {
    test('returns expected object', () {
      var dImg1 = DeviceImage(img1, scale: scale80Percent);
      var completer = dImg1.load(dImg1);
      expect(completer, isNotNull);
    });
  });
}
