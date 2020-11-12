import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_image_provider/device_image.dart';
import 'package:local_image_provider/local_image.dart';
import 'package:local_image_provider/local_image_provider.dart';

String requestedImgId;
int requestedHeight;
int requestedWidth;
int requestedCompression;

void main() {
  const String testId1 = "id1";
  const String create1 = "2019-11-25";
  const int width1 = 100;
  const int height1 = 200;
  const String testId2 = "id2";
  const String missingId = "missing1";
  const String create2 = "2019-10-17";
  const String fileName1 = "file1";
  const String fileName2 = "file2";
  const int width2 = 300;
  const int height2 = 600;
  const int fileSize1 = 1024;
  const int fileSize2 = 2048;
  const double scale80Percent = 0.8;
  const double scale20Percent = 0.2;
  const int width80Percent = 80;
  const int height80Percent = 160;
  const int height20Percent = 40;
  const int compression20Percent = 20;
  const int minPixelsWidth = 30;
  const int minPixelsHeight = 50;
  const img1 = LocalImage(testId1, create1, height1, width1, fileName1,
      fileSize1, LocalImage.imageMediaType);
  const img2 = LocalImage(testId2, create2, height2, width2, fileName2,
      fileSize2, LocalImage.imageMediaType);
  const missingImg = LocalImage(missingId, create2, height2, width2, fileName2,
      fileSize2, LocalImage.imageMediaType);
  String expectedToString =
      "DeviceImage(${img1.toString()}, scale: $scale80Percent)";
  Uint8List imageBytes;
  LocalImageProvider localImageProvider;

  WidgetsFlutterBinding.ensureInitialized();

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
        requestedCompression = methodCall.arguments["compression"];
        if (missingId == requestedImgId) {
          throw PlatformException(code: "missing");
        }
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
    test('compression can be overridden', () {
      var dImg1 = DeviceImage(img1, compression: compression20Percent);
      expect(dImg1.localImage, img1);
      expect(dImg1.compression, compression20Percent);
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

  group('shouldCache', () {
    test('true when all cached is true', () {
      var dImg1 = DeviceImage(img1);
      expect(dImg1.shouldCache(), isTrue);
    });
    test('false when image size exceeds maxCacheSize', () {
      var dImg1 = DeviceImage(img1);
      localImageProvider.maxCacheDimension = img1.pixelHeight - 1;
      expect(dImg1.shouldCache(), isFalse);
    });
    test('true when image size equals maxCacheSize', () {
      var dImg1 = DeviceImage(img1);
      localImageProvider.maxCacheDimension = img1.pixelHeight;
      expect(dImg1.shouldCache(), isTrue);
    });
  });
  group('load', () {
    test('loads expected image', () {
      var dImg1 = DeviceImage(img1, scale: scale80Percent);
      loadAndExpect(dImg1, height80Percent, width80Percent);
    });
    test('1:1 scale by default', () {
      var dImg1 = DeviceImage(img1);
      loadAndExpect(dImg1, height1, width1);
    });
    test('respects min pixels on height', () {
      var dImg1 =
          DeviceImage(img1, scale: scale20Percent, minPixels: minPixelsHeight);
      loadAndExpect(dImg1, minPixelsHeight, minPixelsHeight);
    });
    test('respects min pixels on width', () {
      var dImg1 =
          DeviceImage(img1, scale: scale20Percent, minPixels: minPixelsWidth);
      loadAndExpect(dImg1, height20Percent, minPixelsWidth);
    });
    test('min pixels below actual has no effect', () {
      var dImg1 =
          DeviceImage(img1, scale: scale80Percent, minPixels: minPixelsWidth);
      loadAndExpect(dImg1, height80Percent, width80Percent);
    });
    test('compression can be set', () {
      var dImg1 = DeviceImage(img1, compression: compression20Percent);
      loadAndExpect(dImg1, height1, width1, compression20Percent);
    });
    test('platform exception returns default image', () {
      var dImg1 = DeviceImage(missingImg);
      loadAndExpect(dImg1, height2, width2);
    });
  });
  group('resolve', () {
    test('caches by default', () {
      var dImg1 = DeviceImage(img1);
      ImageStream stream = ImageStream();
      dImg1.resolveStreamForKey(
          ImageConfiguration.empty, stream, dImg1, (exception, stackTrace) {});
      expect(stream.completer, isNotNull);
    });
    test('works when not cached', () {
      localImageProvider.maxCacheDimension = 1;
      var dImg1 = DeviceImage(img1);
      ImageStream stream = ImageStream();
      dImg1.resolveStreamForKey(
          ImageConfiguration.empty, stream, dImg1, (exception, stackTrace) {});
      expect(stream.completer, isNotNull);
    });
  });
}

void loadAndExpect(DeviceImage dImg, int expectedHeight, int expectedWidth,
    [int expectedCompression]) {
  var completer = dImg.load(dImg, decoderCallback);
  expect(completer, isNotNull);
  expect(requestedHeight, expectedHeight);
  expect(requestedWidth, expectedWidth);
  expect(requestedCompression, expectedCompression);
}

Future<Codec> decoderCallback(Uint8List bytes,
    {bool allowUpscaling, int cacheHeight, int cacheWidth}) async {
  return instantiateImageCodec(bytes,
      targetHeight: cacheHeight, targetWidth: cacheWidth);
}
