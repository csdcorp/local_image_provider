import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_image_provider/local_album.dart';
import 'package:local_image_provider/local_image.dart';
import 'package:local_image_provider/local_image_provider.dart';

void main() {
  LocalImageProvider localImageProvider;
  bool initResponse;
  bool pluginInvocation;
  List<String> photoJsonList = [];
  List<String> albumJsonList = [];
  const String noSuchImageId = "noSuchImage";
  const String firstImageId = "image1";
  const String firstPhotoJson =
      '{"id":"$firstImageId","creationDate":"2019-01-01 12:12Z","pixelWidth":1920,"pixelHeight":1024}';
  const String secondPhotoJson =
      '{"id":"image2","creationDate":"2019-01-02 21:07Z","pixelWidth":3324,"pixelHeight":2048}';
  const String imageBytesStr = "087imgbytes234";
  Uint8List imageBytes;
  const String emptyAlbumId = "emptyAlbum1";
  const String firstAlbumId = "album1";
  const String firstAlbumTitle = "My first album";
  const String firstAlbumJson =
      '{"id":"$firstAlbumId","coverImg":$firstPhotoJson,"title":"$firstAlbumTitle"}';

  setUp(() {
    initResponse = true;
    List<int> imgInt = imageBytesStr.codeUnits;
    imageBytes = Uint8List.fromList(imgInt);
    pluginInvocation = false;
    localImageProvider =
        LocalImageProvider.withMethodChannel(LocalImageProvider.lipChannel);
    localImageProvider.channel
        .setMockMethodCallHandler((MethodCall methodCall) async {
      pluginInvocation = true;
      if (methodCall.method == "initialize") {
        return initResponse;
      } else if (methodCall.method == "latest_images") {
        return photoJsonList;
      } else if (methodCall.method == "request_permission") {
        return true;
      } else if (methodCall.method == "image_bytes") {
        if (null == methodCall.arguments) {}
        String imgId = methodCall.arguments["id"];
        if (noSuchImageId == imgId) {
          throw PlatformException(
              code: "imgNotFound", message: "$noSuchImageId not found");
        }
        return imageBytes;
      } else if (methodCall.method == "albums") {
        return albumJsonList;
      } else if (methodCall.method == "images_in_album") {
        if (methodCall.arguments["albumId"] == emptyAlbumId) {
          return [];
        } else {
          return photoJsonList;
        }
      }
      return Future.value(true);
    });
  });

  tearDown(() {
    localImageProvider.channel.setMockMethodCallHandler(null);
  });

  group('initialize', () {
    test('succeeds on success return', () async {
      bool init = await localImageProvider.initialize();
      expect(init, true);
      expect(localImageProvider.isAvailable, isTrue);
    });
    test('second call does not invoke', () async {
      bool init = await localImageProvider.initialize();
      expect(init, true);
      expect(pluginInvocation, true);
      pluginInvocation = false;
      init = await localImageProvider.initialize();
      expect(init, true);
      expect(pluginInvocation, isFalse);
    });
    test('fails on fail return', () async {
      initResponse = false;
      bool init = await localImageProvider.initialize();
      expect(init, false);
      expect(localImageProvider.isAvailable, isFalse);
    });
    test('fail return leaves other methods uninitialized', () async {
      initResponse = false;
      await localImageProvider.initialize();
      try {
        await localImageProvider.findAlbums(LocalAlbumType.all);
        fail("Should have thrown");
      } catch (e) {
        // expected
      }
    });
  });
  group('albums', () {
    test('empty list returns none', () async {
      await localImageProvider.initialize();
      List<LocalAlbum> albums =
          await localImageProvider.findAlbums(LocalAlbumType.all);
      expect(albums.length, 0);
    });

    test('single album returned', () async {
      await localImageProvider.initialize();
      albumJsonList = [
        firstAlbumJson,
      ];
      List<LocalAlbum> albums =
          await localImageProvider.findAlbums(LocalAlbumType.all);
      expect(albums.length, 1);
      LocalAlbum album = albums.first;
      expect(album.id, firstAlbumId);
      expect(album.title, firstAlbumTitle);
      expect(album.coverImgId, firstImageId);
    });
    test('failed or missing initialize throws', () async {
      try {
        await localImageProvider.findAlbums(LocalAlbumType.all);
        fail("Should have thrown");
      } catch (e) {
        // expected
      }
    });
  });

  group('latest', () {
    test('empty list returns no photos', () async {
      await localImageProvider.initialize();
      List<LocalImage> photos = await localImageProvider.findLatest(10);
      expect(photos.length, 0);
    });
    test('single photo returned', () async {
      await localImageProvider.initialize();
      photoJsonList = [
        firstPhotoJson,
      ];
      List<LocalImage> photos = await localImageProvider.findLatest(10);
      expect(photos.length, 1);
    });
    test('two photos returned', () async {
      await localImageProvider.initialize();
      photoJsonList = [firstPhotoJson, secondPhotoJson];
      List<LocalImage> photos = await localImageProvider.findLatest(10);
      expect(photos.length, 2);
      expect(photos[0].id, firstImageId);
    });
    test('failed or missing initialize throws', () async {
      try {
        await localImageProvider.findLatest(10);
        fail("Should have thrown");
      } catch (e) {
        // expected
      }
    });
  });

  group('imagesInAlbums', () {
    test('empty list returns no photos', () async {
      await localImageProvider.initialize();
      List<LocalImage> photos =
          await localImageProvider.findImagesInAlbum(emptyAlbumId, 10);
      expect(photos.length, 0);
    });
    test('expected photos returned', () async {
      await localImageProvider.initialize();
      photoJsonList = [firstPhotoJson, secondPhotoJson];
      List<LocalImage> photos =
          await localImageProvider.findImagesInAlbum(firstAlbumId, 10);
      expect(photos.length, 2);
      expect(photos[0].id, firstImageId);
    });
    test('failed or missing initialize throws', () async {
      try {
        await localImageProvider.findImagesInAlbum(firstAlbumId, 10);
        fail("Should have thrown");
      } catch (e) {
        // expected
      }
    });
  });

  group('image bytes', () {
    test('returned unchanged', () async {
      await localImageProvider.initialize();
      photoJsonList = [firstPhotoJson, secondPhotoJson];
      Uint8List bytes =
          await localImageProvider.imageBytes(firstImageId, 300, 300);
      expect(bytes, imageBytes);
    });

    test('handles image not found', () async {
      await localImageProvider.initialize();
      try {
        await localImageProvider.imageBytes(noSuchImageId, 300, 300);
        fail("Expected PlatformException");
      } on PlatformException catch (e) {
        expect(e.code, "imgNotFound");
      }
    });
    test('failed or missing initialize throws', () async {
      try {
        await localImageProvider.imageBytes(noSuchImageId, 300, 300);
        fail("Should have thrown");
      } catch (e) {
        // expected
      }
    });
  });
}
