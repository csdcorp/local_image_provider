import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_image_provider/local_image.dart';
import 'package:local_image_provider/local_image_provider.dart';

void main() {
  List<String> photoJsonList = [];
  const MethodChannel channel = MethodChannel('local_image_provider');
  const String firstImageId = "image1";
  const String firstPhotoJson = '{"id":"$firstImageId","creationDate":"2019-01-01 12:12Z","pixelWidth":1920,"pixelHeight":1024}';
  const String secondPhotoJson = '{"id":"image2","creationDate":"2019-01-02 21:07Z","pixelWidth":3324,"pixelHeight":2048}';

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return photoJsonList;
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('empty list returns no photos', () async {
    List<LocalImage> photos = await LocalImageProvider.getLatest(10);
    expect( photos.length, 0 );
  });
  test('single photo returned', () async {
    photoJsonList = [ firstPhotoJson, ];
    List<LocalImage> photos = await LocalImageProvider.getLatest(10);
    expect( photos.length, 1 );
  });
  test('two photos returned', () async {
    photoJsonList = [ firstPhotoJson, secondPhotoJson ];
    List<LocalImage> photos = await LocalImageProvider.getLatest(10);
    expect( photos.length, 2 );
    expect( photos[0].id, firstImageId );
  });
}
