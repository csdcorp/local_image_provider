import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_image_provider/local_image.dart';
import 'package:local_image_provider/local_image_provider.dart';

import 'device_image_test.dart';

void main() {
  const String testId1 = "id1";
  const String create1 = "2019-11-25";
  const int width1 = 100;
  const int height1 = 200;
  const int compression1 = 20;
  const String testId2 = "id2";
  const String create2 = "2019-10-17";
  const String fileName1 = "file1";
  const String fileName2 = "file2";
  const int width2 = 300;
  const int height2 = 600;
  const double scale80Percent = 0.8;
  const int width80Percent = 80;
  const int height80Percent = 160;
  const int fileSize1 = 1024;
  const int fileSize2 = 2048;
  const String expectedToString =
      "LocalImage($testId1, creation: $create1, height: $height1, width: $width1)";
  const img1 = LocalImage(testId1, create1, height1, width1, fileName1,
      fileSize1, LocalImage.imageMediaType);
  const img1a = LocalImage(testId1, create1, height1, width1, fileName1,
      fileSize1, LocalImage.imageMediaType);
  const img2 = LocalImage(testId2, create2, height2, width2, fileName2,
      fileSize2, LocalImage.imageMediaType);

  String requestedImgId;
  int requestedHeight;
  int requestedWidth;
  int requestedCompression;
  Uint8List imageBytes;
  LocalImageProvider localImageProvider;

  WidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    List<int> imgInt = "087imgbytes234".codeUnits;
    imageBytes = Uint8List.fromList(imgInt);
    localImageProvider =
        LocalImageProvider.withMethodChannel(LocalImageProvider.lipChannel);
    localImageProvider.channel
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == "initialize") {
        return true;
      } else if (methodCall.method == "image_bytes") {
        requestedImgId = methodCall.arguments["id"];
        requestedHeight = methodCall.arguments["pixelHeight"];
        requestedWidth = methodCall.arguments["pixelWidth"];
        requestedCompression = methodCall.arguments["compression"];
        return imageBytes;
      }
      return null;
    });
    await localImageProvider.initialize();
  });

  group('properties', () {
    test(' properties set properly', () {
      var img = LocalImage(testId1, create1, height1, width1, fileName1,
          fileSize1, LocalImage.imageMediaType);
      expect(img.id, testId1);
      expect(img.creationDate, create1);
      expect(img.pixelHeight, height1);
      expect(img.pixelWidth, width1);
      expect(img.isImage, isTrue);
      expect(img.isVideo, isFalse);
      expect(img.compression, null);
    });
    test('hash works', () {
      expect(img1.hashCode, img1.hashCode);
      expect(img1.hashCode, img1a.hashCode);
      expect(img1.hashCode, isNot(img2.hashCode));
    });
    test('equals works', () {
      expect(img1, img1);
      expect(img1, img1a);
      expect(img1, isNot(img2));
    });
    test('toString as expected', () {
      expect(img1.toString(), expectedToString);
    });
  });
  group('json', () {
    test('round trips as expected', () {
      var img = LocalImage(testId1, create1, height1, width1, fileName1,
          fileSize1, LocalImage.imageMediaType);
      var json = img.toJson();
      var img1 = LocalImage.fromJson(json);
      expect(img.id, img1.id);
      expect(img.pixelHeight, img1.pixelHeight);
      expect(img.pixelWidth, img1.pixelWidth);
      expect(img.creationDate, img1.creationDate);
    });
  });
  group('imageBytes', () {
    test('simple get succeeds', () async {
      var img = LocalImage(testId1, create1, height1, width1, fileName1,
          fileSize1, LocalImage.imageMediaType,
          compression: compression1);
      var bytes = await img.getImageBytes(localImageProvider, height1, width1);
      expect(requestedImgId, testId1);
      expect(requestedHeight, height1);
      expect(requestedWidth, width1);
      expect(requestedCompression, compression1);
      expect(bytes, imageBytes);
    });
    test('scaled get succeeds', () async {
      var img = LocalImage(testId1, create1, height1, width1, fileName1,
          fileSize1, LocalImage.imageMediaType);
      var bytes =
          await img.getScaledImageBytes(localImageProvider, scale80Percent);
      expect(requestedImgId, testId1);
      expect(requestedHeight, height80Percent);
      expect(requestedWidth, width80Percent);
      expect(bytes, imageBytes);
    });
  });
  group('scale', () {
    test('returns 1 for same size', () {
      expect(img1.scaleToFit(height1, width1), 1.0);
    });
    test('returns 1 for larger size', () {
      expect(img1.scaleToFit(height1 + 1000, width1 + 1000), 1.0);
    });
    test('returns .5 for half size', () {
      expect(img1.scaleToFit((height1 / 2).round(), (width1 / 2).round()), 0.5);
    });
    test('returns the smaller scale', () {
      expect(img1.scaleToFit((height1 / 2).round(), width1), 0.5);
    });
  });
}
