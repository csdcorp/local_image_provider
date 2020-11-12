import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_image_provider/local_album.dart';
import 'package:local_image_provider/local_image.dart';
import 'package:local_image_provider/local_image_provider.dart';

void main() {
  const String albumId1 = "album1";
  const String albumId2 = "album2";
  const String albumId3 = "album3";
  const String title1 = "title1";
  const String title2 = "title2";
  const String title3 = "title3";
  const String fileName1 = "file1";
  const int fileSize1 = 1024;
  const int imageCount1 = 10;
  const int imageCount2 = 20;
  const int videoCount1 = 0;
  const int videoCount2 = 1;
  const String imgId1 = "img1";
  const String creation1 = "2019-10-25";
  const String expectedToString = "LocalAlbum($albumId1, title: $title1)";
  const int height1 = 100;
  const int width1 = 200;
  const int compression1 = 20;
  const LocalImage coverImg1 = LocalImage(imgId1, creation1, height1, width1,
      fileName1, fileSize1, LocalImage.imageMediaType);
  final LocalAlbum localAlbum1 = LocalAlbum(albumId1, coverImg1, title1,
      imageCount1, videoCount1, LocalAlbumType.album.value);
  final LocalAlbum localAlbum1a = LocalAlbum(albumId1, coverImg1, title1,
      imageCount1, videoCount1, LocalAlbumType.album.value);
  final LocalAlbum localAlbum2 = LocalAlbum(albumId2, coverImg1, title2,
      imageCount2, videoCount2, LocalAlbumType.user.value);
  final LocalAlbum localAlbum3 = LocalAlbum(albumId3, coverImg1, title3,
      imageCount2, videoCount2, LocalAlbumType.shared.value);
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
    test('set as expected', () {
      expect(localAlbum1.id, albumId1);
      expect(localAlbum1.title, title1);
      expect(localAlbum1.coverImg, coverImg1);
      expect(localAlbum1.imageCount, imageCount1);
    });
    test('albumType generated for album', () {
      expect(localAlbum1.albumType, LocalAlbumType.album);
      expect(localAlbum2.albumType, LocalAlbumType.user);
      expect(localAlbum3.albumType, LocalAlbumType.shared);
    });
    test('hash works', () {
      expect(localAlbum1.hashCode, localAlbum1.hashCode);
      expect(localAlbum1.hashCode, localAlbum1a.hashCode);
      expect(localAlbum1.hashCode, isNot(localAlbum2.hashCode));
    });
    test('equals works', () {
      expect(localAlbum1, localAlbum1);
      expect(localAlbum1, localAlbum1a);
      expect(localAlbum1, isNot(localAlbum2));
    });
    test('toString works', () {
      expect(localAlbum1.toString(), expectedToString);
    });
  });

  group('json', () {
    test('roundtrips as expected', () {
      var roundtripAlbum = LocalAlbum.fromJson(localAlbum1.toJson());
      expect(localAlbum1.id, roundtripAlbum.id);
      expect(localAlbum1.title, roundtripAlbum.title);
      expect(localAlbum1.coverImg, roundtripAlbum.coverImg);
      expect(localAlbum1.imageCount, roundtripAlbum.imageCount);
      expect(localAlbum1.transferType, roundtripAlbum.transferType);
      expect(localAlbum1.albumType, roundtripAlbum.albumType);
    });
    test('Handles missing type', () {
      String missingTypeJson =
          '{"id":"album","title":"Album 1","imageCount":1}';
      var jsonMap = jsonDecode(missingTypeJson);
      var roundtripAlbum = LocalAlbum.fromJson(jsonMap);
      expect(roundtripAlbum.albumType, LocalAlbumType.album);
    });
  });
  group('imageBytes', () {
    test('loads cover image', () async {
      var bytes = await localAlbum1.getCoverImage(
          localImageProvider, height1, width1,
          compression: compression1);
      expect(requestedImgId, imgId1);
      expect(requestedHeight, height1);
      expect(requestedWidth, width1);
      expect(requestedCompression, compression1);
      expect(bytes, imageBytes);
    });
  });
  group('LocalAlbumType', () {
    test('correct type returned from int', () {
      expect(LocalAlbumType.fromInt(0), LocalAlbumType.all);
      expect(LocalAlbumType.fromInt(1), LocalAlbumType.album);
      expect(LocalAlbumType.fromInt(2), LocalAlbumType.user);
      expect(LocalAlbumType.fromInt(3), LocalAlbumType.generated);
      expect(LocalAlbumType.fromInt(4), LocalAlbumType.faces);
      expect(LocalAlbumType.fromInt(5), LocalAlbumType.event);
      expect(LocalAlbumType.fromInt(6), LocalAlbumType.imported);
      expect(LocalAlbumType.fromInt(7), LocalAlbumType.shared);
    });
    test('unknown ints convert to generic album type', () {
      expect(LocalAlbumType.fromInt(8), LocalAlbumType.album);
      expect(LocalAlbumType.fromInt(-1), LocalAlbumType.album);
      expect(LocalAlbumType.fromInt(712), LocalAlbumType.album);
    });
  });
}
