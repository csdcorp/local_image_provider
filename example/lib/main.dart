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
  String _imgHeading = "most recent 100";
  LocalImage _selectedImg;
  int _desiredHeight = 500;
  int _desiredWidth = 500;
  TextEditingController heightController = TextEditingController();
  TextEditingController widthController = TextEditingController();

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

  void switchImage(LocalImage image, String src) {
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
            await localImageProvider.imageBytes(album.coverImg.id, 500, 500);
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

  void _updateDesired(String current) {
    _desiredHeight = int.parse(heightController.text);
    _desiredWidth = int.parse(widthController.text);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Local Image Provider Example'),
          actions: <Widget>[
            Container(
              margin: EdgeInsets.all(5),
              child: FlatButton(
                child: Text(
                  'Stress Test',
                ),
                onPressed: stressTest,
                color: Colors.white30,
              ),
            ),
          ],
        ),
        body: _hasPermission
            ? Container(
                padding: EdgeInsets.all(20),
                color: Colors.blueGrey[100],
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Flexible(
                        child: Text(
                          'Found - Images: ${_localImages.length}; Albums: ${_localAlbums.length}.',
                          style: Theme.of(context).textTheme.display1,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  hintText: 'Height',
                                  hintStyle: TextStyle(
                                    fontSize: 18.0,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                controller: heightController,
                                onChanged: _updateDesired,
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  hintText: 'Width',
                                  hintStyle: TextStyle(
                                    fontSize: 18.0,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                controller: widthController,
                                onChanged: _updateDesired,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Albums',
                          style: Theme.of(context).textTheme.headline,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          color: Theme.of(context).canvasColor,
                          padding: EdgeInsets.all(8),
                          child: ListView(
                            children: _localAlbums
                                .map(
                                  (album) => GestureDetector(
                                      onTap: () => switchAlbum(album),
                                      child: Container(
                                        padding: EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          'Title: ${album.title}; images: ${album.imageCount}, id: ${album.id}; cover Id: ${album.coverImg.id}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .subhead,
                                        ),
                                      )),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Images - $_imgHeading \n (Images in album: ${_localImages.length})',
                          style: Theme.of(context).textTheme.headline,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          color: Theme.of(context).canvasColor,
                          padding: EdgeInsets.all(8),
                          child: ListView(
                            children: _localImages
                                .map(
                                  (img) => GestureDetector(
                                    onTap: () => switchImage(img, 'Images'),
                                    child: Container(
                                      color: Theme.of(context).canvasColor,
                                      padding: EdgeInsets.all(10),
                                      child: Text(
                                        'Id: ${img.id}; created: ${img.creationDate}',
                                        style:
                                            Theme.of(context).textTheme.subhead,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: _hasImage
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                                    child: Text(
                                      'Selected: $_imgSource',
                                      style: Theme.of(context).textTheme.title,
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      color: Theme.of(context).canvasColor,
                                      padding: EdgeInsets.all(16),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Image(
                                            image: DeviceImage(_selectedImg,
                                                scale: _selectedImg.scaleToFit(
                                                    _desiredHeight,
                                                    _desiredWidth)),
                                            fit: BoxFit.contain,
                                          ),
                                          Text(
                                            'Image id:\n ${_selectedImg.id}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .body1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Text(
                                  'Tap on an image or album for a preview',
                                  style: Theme.of(context).textTheme.headline,
                                ),
                              ),
                      )
                    ]),
              )
            : Center(child: Text('No permission')),
      ),
    );
  }
}
