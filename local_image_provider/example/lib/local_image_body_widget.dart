import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_image_provider/local_image_provider.dart';
import 'package:local_image_provider_example/albums_list_widget.dart';
import 'package:local_image_provider_example/image_preview_widget.dart';
import 'package:local_image_provider_example/images_list_widget.dart';

/// Builds a simple UI that shows the functionality of the
/// local_image_provider plugin.
class LocalImageBodyWidget extends StatefulWidget {
  @override
  _LocalImageBodyWidgetState createState() => _LocalImageBodyWidgetState();
}

class _LocalImageBodyWidgetState extends State<LocalImageBodyWidget> {
  LocalImageProvider localImageProvider = LocalImageProvider();
  int _localImageCount = 0;
  bool _hasPermission = false;
  bool _hasLimitedPermission = false;
  bool _inStress = false;
  List<LocalImage> _localImages = [];
  List<LocalAlbum> _localAlbums = [];
  bool _hasImage = false;
  String? _imgSource;
  String _imgHeading = "most recent 100";
  LocalImage? _selectedImg;
  LocalAlbum? _selectedAlbum;
  TextEditingController heightController = TextEditingController();
  TextEditingController widthController = TextEditingController();
  int _desiredHeight = 2000;
  int _desiredWidth = 2000;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  void _updateDesired(String current) {
    _desiredHeight = int.parse(heightController.text);
    _desiredWidth = int.parse(widthController.text);
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    bool hasPermission = false;
    List<LocalImage> localImages = [];
    List<LocalAlbum> localAlbums = [];

    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      hasPermission = await localImageProvider.hasPermission;
      if (hasPermission) {
        print('Already granted, initialize will not ask');
      }
      hasPermission = await localImageProvider.initialize();
      if (hasPermission) {
        await localImageProvider.cleanup();
        localImages = await localImageProvider.findLatest(50);
        localAlbums = await localImageProvider.findAlbums(LocalAlbumType.all);
      }
    } on PlatformException catch (e) {
      print('Local image provider failed: $e');
    }

    if (!mounted) return;

    _hasLimitedPermission = false;
    await localImageProvider.hasLimitedPermission;
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
        await localImageProvider.findImagesInAlbum(album.id!, 100);
    setState(() {
      _imgHeading = "from album: ${album.title}";
      _localImages.clear();
      _localImages.addAll(albumImages);
      _selectedAlbum = album;
    });
    switchImage(album.coverImg!, 'Album');
  }

  void switchImage(LocalImage image, String src) {
    setState(() {
      _hasImage = true;
      _imgSource = src;
      _selectedImg = image;
    });
  }

  /// This runs repeated image loads in a loop to check for
  /// resource allocation/free on iOS and Android.
  ///
  /// No need to run this unless you're curious and have some
  /// time to wait.
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
            await localImageProvider.imageBytes(album.coverImg!.id!, 500, 500);
        totalBytesLoaded += imgBytes.length;
        ++totalImagesLoaded;
        List<LocalImage> albumImages =
            await localImageProvider.findImagesInAlbum(album.id!, 100);
        for (var albumImage in albumImages) {
          Uint8List imgBytes =
              await localImageProvider.imageBytes(albumImage.id!, 500, 500);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Image Provider Example'),
        actions: <Widget>[
          Container(
            margin: EdgeInsets.all(5),
            child: TextButton(
              child: Text(
                'Stress Test',
              ),
              onPressed: stressTest,
            ),
          ),
        ],
      ),
      body: _hasPermission
          ? GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(
                    new FocusNode()); //to take focus out of height/width fields when done updating
              },
              child: Container(
                padding: EdgeInsets.all(20),
                color: Colors.blueGrey[100],
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      AlbumsListWidget(
                        localImageProvider: localImageProvider,
                        localImages: _localImages,
                        localAlbums: _localAlbums,
                        switchAlbum: switchAlbum,
                        selectedAlbum: _selectedAlbum,
                        limited: _hasLimitedPermission,
                      ),
                      ImagesListWidget(
                        imgHeading: _imgHeading,
                        localImages: _localImages,
                        switchImage: switchImage,
                        selectedImage: _selectedImg,
                      ),
                      ImagePreviewWidget(
                          hasImage: _hasImage,
                          imgSource: _imgSource,
                          selectedImg: _selectedImg,
                          desiredHeight: _desiredHeight,
                          desiredWidth: _desiredWidth,
                          heightController: heightController,
                          widthController: widthController,
                          updateDesired: _updateDesired)
                    ]),
              ),
            )
          : Center(
              child: Text('No permission'),
            ),
    );
  }
}
