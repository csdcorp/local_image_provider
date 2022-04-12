import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_image_provider/local_image_provider.dart';
import 'package:local_image_provider_platform_interface/local_image_provider_platform_interface.dart';

import 'test_local_image_provider.dart';

void main() {
  TestLocalImageProvider? testProvider;
  late LocalImageProvider localImageProvider;
  const String noSuchImageId = "noSuchImage";
  const String firstImageId = "image1";
  const String firstVideoId = "video1";
  const String firstVideoPath = "/tmp/video1";
  const String firstPhotoJson =
      '{"id":"$firstImageId","creationDate":"2019-01-01 12:12Z","pixelWidth":1920,"pixelHeight":1024}';
  const String secondPhotoJson =
      '{"id":"image2","creationDate":"2019-01-02 21:07Z","pixelWidth":3324,"pixelHeight":2048}';
  const String imageBytesStr = "087imgbytes234";
  Uint8List? imageBytes;
  const String emptyAlbumId = "emptyAlbum1";
  const String firstAlbumId = "album1";
  const String firstAlbumTitle = "My first album";
  final String firstAlbumJson =
      '{"id":"$firstAlbumId","coverImg":$firstPhotoJson,"title":"$firstAlbumTitle","imageCount":2,"videoCount":0,"transferType":${LocalAlbumType.shared.value}}';

  WidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    List<int> imgInt = imageBytesStr.codeUnits;
    imageBytes = Uint8List.fromList(imgInt);
    testProvider = TestLocalImageProvider();
    LocalImageProviderPlatform.instance = testProvider!;
    localImageProvider = LocalImageProvider.testInstance();
    // pluginInvocation = true;
    // switch (methodCall.method) {
    //   case "has_permission":
    //     return hasResponse;
    //     break;
    //   case "initialize":
    //     return initResponse;
    //     break;
    //   case "cleanup":
    //     return cleanupResponse;
    //     break;
    //   case "latest_images":
    //     return photoJsonList;
    //     break;
    //   case "request_permission":
    //     return true;
    //     break;
    //   case "image_bytes":
    //     if (null == methodCall.arguments) {}
    //     String imgId = methodCall.arguments["id"];
    //     if (noSuchImageId == imgId) {
    //       throw PlatformException(
    //           code: "imgNotFound", message: "$noSuchImageId not found");
    //     }
    //     return imageBytes;
    //     break;
    //   case "albums":
    //     return albumJsonList;
    //     break;
    //   case "video_file":
    //     String imgId = methodCall.arguments["id"];
    //     if (noSuchImageId == imgId) {
    //       throw PlatformException(
    //           code: "imgNotFound", message: "$noSuchImageId not found");
    //     }
    //     return firstVideoPath;
    //     break;
    //   case "images_in_album":
    //     if (methodCall.arguments["albumId"] == emptyAlbumId) {
    //       return [];
    //     } else {
    //       return photoJsonList;
    //     }
    //     break;
    //   default:
    //     return Future.value(true);
    // }
  });

  group('hasPermission', () {
    test('true on true return', () async {
      bool has = await localImageProvider.hasPermission;
      expect(has, isTrue);
    });
    test('false on false return', () async {
      testProvider!.permissionResult = false;
      bool has = await localImageProvider.hasPermission;
      expect(has, isFalse);
    });
  });
  group('cacheProperties', () {
    test('changing maxCacheDimension makes cacheAll false', () async {
      localImageProvider.maxCacheDimension =
          LocalImageProvider.cacheSuggestedCutoff;
      expect(localImageProvider.cacheAll, isFalse);
    });
    test('cacheAll defaults to true', () async {
      expect(localImageProvider.cacheAll, isTrue);
    });
    test('maxCacheDimension defaults to 0, which means all images cached',
        () async {
      expect(localImageProvider.maxCacheDimension,
          LocalImageProvider.cacheAtAnySize);
    });
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
      expect(testProvider!.invoked, true);
      testProvider!.invoked = false;
      init = await localImageProvider.initialize();
      expect(init, true);
      expect(testProvider!.invoked, isFalse);
    });
    test('fails on fail return', () async {
      testProvider!.initResult = false;
      bool init = await localImageProvider.initialize();
      expect(init, false);
      expect(localImageProvider.isAvailable, isFalse);
    });
    test('fail return leaves other methods uninitialized', () async {
      testProvider!.initResult = false;
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
      testProvider!.albums = [
        firstAlbumJson,
      ];
      List<LocalAlbum> albums =
          await localImageProvider.findAlbums(LocalAlbumType.all);
      expect(albums.length, 1);
      LocalAlbum album = albums.first;
      expect(album.id, firstAlbumId);
      expect(album.title, firstAlbumTitle);
      expect(album.albumType, LocalAlbumType.shared);
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
      testProvider!.latestImages = [
        firstPhotoJson,
      ];
      List<LocalImage> photos = await localImageProvider.findLatest(10);
      expect(photos.length, 1);
    });
    test('two photos returned', () async {
      await localImageProvider.initialize();
      testProvider!.latestImages = [firstPhotoJson, secondPhotoJson];
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
      testProvider!.albumImages = [firstPhotoJson, secondPhotoJson];
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
      testProvider!.imgBytes = imageBytes;
      Uint8List bytes =
          await localImageProvider.imageBytes(firstImageId, 300, 300);
      expect(bytes, imageBytes);
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

  group('videoFile', () {
    test('fails if not initialized', () async {
      try {
        await localImageProvider.videoFile(firstVideoId);
        fail("Should have thrown");
      } catch (e) {
        // expected
      }
    });
    test('Returns expected video file', () async {
      testProvider!.videoFileResult = firstVideoPath;
      await localImageProvider.initialize();
      var path = await localImageProvider.videoFile(firstVideoId);
      expect(path, firstVideoPath);
    });
  });
  group('cleanup', () {
    test('fails if not initialized', () async {
      try {
        await localImageProvider.cleanup();
        fail("Should have thrown");
      } catch (e) {
        // expected
      }
    });
    test('works silently if initialized', () async {
      await localImageProvider.initialize();
      await localImageProvider.cleanup();
    });
  });
  group('stats', () {
    test('start at 0', () {
      expect(localImageProvider.imgBytesLoaded, 0);
      expect(localImageProvider.totalLoadTime, 0);
      expect(localImageProvider.lastLoadTime, 0);
    });
    test('counts bytes loaded', () async {
      await localImageProvider.initialize();
      testProvider!.imgBytes = imageBytes;
      Uint8List bytes =
          await localImageProvider.imageBytes(firstImageId, 300, 300);
      expect(localImageProvider.imgBytesLoaded, bytes.length);
    });
    test('resets bytes loaded', () async {
      await localImageProvider.initialize();
      testProvider!.imgBytes = imageBytes;
      await localImageProvider.imageBytes(firstImageId, 300, 300);
      localImageProvider.resetStats();
      expect(localImageProvider.imgBytesLoaded, 0);
    });
  });
}
