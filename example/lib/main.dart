import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_image_provider/device_image.dart';
import 'package:local_image_provider/local_album.dart';
import 'package:local_image_provider/local_image.dart';
import 'package:local_image_provider/local_image_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  LocalImageProvider localImageProvider = LocalImageProvider();
  int _localImageCount = 0;
  bool _hasPermission = false;
  bool _inStress = false;
  List<LocalImage> _localImages = [];
  List<LocalAlbum> _localAlbums = [];
  bool _hasImage = false;
  String _imgSource;
  String _selectedId;
  String _imgHeading = "most recent 100";
  LocalImage _selectedImg;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    bool hasPermission = false;
    List<LocalImage> localImages = [];
    List<LocalAlbum> localAlbums = [];

    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      hasPermission = await localImageProvider.initialize();
      if (hasPermission) {
        localImages = await localImageProvider.findLatest(50);
        localAlbums = await localImageProvider.findAlbums(LocalAlbumType.all);
      }
    } on PlatformException catch (e) {
      print('Local image provider failed: $e');
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _localImages.addAll(localImages);
      _localAlbums.addAll(localAlbums);
      _localImageCount = _localImages.length;
      print('Count is $_localImageCount, length is ${_localImages.length}');
      _hasPermission = hasPermission;
    });
  }

  void switchAlbum(LocalAlbum album) async {
    List<LocalImage> albumImages =
        await localImageProvider.findImagesInAlbum(album.id, 100);
    setState(() {
      _imgHeading = "from album: ${album.title}";
      _localImages.clear();
      _localImages.addAll(albumImages);
    });
    switchImage(album.coverImg, 'Album');
  }

  void switchImage( LocalImage image, String src) {
      setState(() {
        _hasImage = true;
        _imgSource = src;
        _selectedImg = image;
    });
  }

  void stressTest() async {
    if (_inStress) {
      return;
    }
    print("Starting stress test");
    _inStress = false;
    int totalImagesLoaded = 0;
    int totalAlbums = 0;
    int totalBytesLoaded = 0;
    DateTime start = DateTime.now();
    for (int albumLoop = 0; albumLoop < 1000; ++albumLoop) {
      List<LocalAlbum> localAlbums =
          await localImageProvider.findAlbums(LocalAlbumType.all);
      totalAlbums += localAlbums.length;
      for (var album in localAlbums) {
        Uint8List imgBytes =
            await localImageProvider.imageBytes(album.coverImgId, 500, 500);
        totalBytesLoaded += imgBytes.length;
        ++totalImagesLoaded;
        List<LocalImage> albumImages =
            await localImageProvider.findImagesInAlbum(album.id, 100);
        for (var albumImage in albumImages) {
          Uint8List imgBytes =
              await localImageProvider.imageBytes(albumImage.id, 500, 500);
          totalBytesLoaded += imgBytes.length;
          ++totalImagesLoaded;
        }
      }
      DateTime current = DateTime.now();
      int millisSoFar =
          current.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
      double avgLoopTime = millisSoFar / (albumLoop + 1);
      int secondsRemaining =
          (avgLoopTime * (1000 - albumLoop - 1) / 1000).truncate();
      print(
          "$albumLoop, albums: $totalAlbums, images: $totalImagesLoaded, bytes: $totalBytesLoaded, remaining: $secondsRemaining");
    }
    _inStress = false;
    print("Stress test complete");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Local Image Provider Example'),
        ),
        body: _hasPermission
            ? Container(
                padding: EdgeInsets.all(10),
                child: Column(children: [
                  Text(
                    'Found - Images: ${_localImages.length}; Albums: ${_localAlbums.length}.',
                    style: TextStyle(fontSize: 24),
                  ),
                  Divider(),
                  Flexible(
                    child: FlatButton(
                      child: Text('Stress Test'),
                      onPressed: stressTest,
                    ),
                  ),
                  Text('Albums', style: TextStyle(fontSize: 20)),
                  Expanded(
                    child: ListView(
                      children: _localAlbums
                          .map(
                            (album) => GestureDetector(
                                onTap: () => switchAlbum(album),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 5),
                                  child: Text(
                                      'Title: ${album.title}; images: ${album.imageCount}, id: ${album.id}; cover Id: ${album.coverImg}'),
                                )),
                          )
                          .toList(),
                    ),
                  ),
                  Divider(),
                  Text('Images - $_imgHeading', style: TextStyle(fontSize: 20)),
                  Expanded(
                    child: ListView(
                      children: _localImages
                          .map(
                            (img) => GestureDetector(
                              onTap: () => switchImage(img, 'Images'),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 5),
                                child: Text(
                                    'Id: ${img.id}; created: ${img.creationDate}'),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Divider(),
                  Expanded(
                    child: _hasImage
                        ? Column(
                            children: <Widget>[
                              Text('Selected: $_imgSource'),
                              Text('Image id: ${_selectedImg.id}'),
                              Expanded(
                                child: Image( image: DeviceImage( _selectedImg )),
                              ),
                            ],
                          )
                        : Center(
                            child: Text(
                                'Tap on an image or album for a preview',
                                style: TextStyle(
                                    fontSize: 20, fontStyle: FontStyle.italic)),
                          ),
                  ),
                ]),
              )
            : Center(child: Text('No permission')),
      ),
    );
  }
}
