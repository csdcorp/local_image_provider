import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_image_provider/local_album.dart';
import 'package:local_image_provider/local_image.dart';
import 'package:local_image_provider/local_image_provider.dart';

void main() {
  LocalImageProvider localImageProvider;
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
  const String firstAlbumId = "album1";
  const String firstAlbumTitle = "My first album";
  const String firstAlbumJson =
      '{"id":"$firstAlbumId","coverImgId":"$firstImageId","title":"$firstAlbumTitle"}';

  setUp(() {
    List<int> imgInt = imageBytesStr.codeUnits;
    imageBytes = Uint8List.fromList(imgInt);
    localImageProvider = LocalImageProvider.withMethodChannel(LocalImageProvider.lipChannel);
    localImageProvider.channel.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == "latest_images") {
        return photoJsonList;
      } else if (methodCall.method == "request_permission") {
        return true;
      } else if (methodCall.method == "image_bytes") {
        if ( null == methodCall.arguments ) {

        }
        String imgId = methodCall.arguments["id"];
        if (noSuchImageId == imgId) {
          throw PlatformException(
              code: "imgNotFound", message: "$noSuchImageId not found");
        }
        return imageBytes;
      } else if (methodCall.method == "albums") {
        return albumJsonList;
      }
      return Future.value(true);
    });
  });

  tearDown(() {
    localImageProvider.channel.setMockMethodCallHandler(null);
  });

  group('albums', () {
    test('empty list returns none', () async {
      List<LocalAlbum> albums =
          await localImageProvider.getAlbums(LocalAlbumType.all);
      expect(albums.length, 0);
    });

    test('single album returned', () async {
      albumJsonList = [
        firstAlbumJson,
      ];
      List<LocalAlbum> albums =
          await localImageProvider.getAlbums(LocalAlbumType.all);
      expect(albums.length, 1);
      LocalAlbum album = albums.first;
      expect(album.id, firstAlbumId);
      expect(album.title, firstAlbumTitle);
      expect(album.coverImgId, firstImageId);
    });
  });

  group('latest', () {
    test('empty list returns no photos', () async {
      List<LocalImage> photos = await localImageProvider.getLatest(10);
      expect(photos.length, 0);
    });
    test('single photo returned', () async {
      photoJsonList = [
        firstPhotoJson,
      ];
      List<LocalImage> photos = await localImageProvider.getLatest(10);
      expect(photos.length, 1);
    });
    test('two photos returned', () async {
      photoJsonList = [firstPhotoJson, secondPhotoJson];
      List<LocalImage> photos = await localImageProvider.getLatest(10);
      expect(photos.length, 2);
      expect(photos[0].id, firstImageId);
    });
  });

  group('image bytes', () {
    test('returned unchanged', () async {
      photoJsonList = [firstPhotoJson, secondPhotoJson];
      List<LocalImage> photos = await localImageProvider.getLatest(10);
      LocalImage image = photos.first;
      Uint8List bytes = await image.getImageBytes(300, 300);
      expect(bytes, imageBytes);
    });

    test('handles image not found', () async {
      try {
        await localImageProvider.imageBytes(noSuchImageId, 300, 300);
        fail("Expected PlatformException");
      } on PlatformException catch(e) {
        expect( e.code, "imgNotFound"  );
      }
    });
  });
}
