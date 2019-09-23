import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:local_image_provider/local_image_provider.dart';
import 'package:local_image_provider/local_image.dart';
import 'package:local_image_provider/local_album.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _localImageCount = 0;
  bool _hasPermission = false;
  List<LocalImage> _localImages = [];
  List<LocalAlbum> _localAlbums = [];
  Uint8List _imgBytes;
  bool _hasImage = false;
  String _imgSource;

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
      PermissionStatus permission = PermissionStatus.granted;
      if (Platform.isAndroid) {
        permission = await PermissionHandler()
            .checkPermissionStatus(PermissionGroup.storage);
      } else if (Platform.isIOS) {
        permission = await PermissionHandler()
            .checkPermissionStatus(PermissionGroup.photos);
      }
      if (permission != PermissionStatus.granted) {
        Map<PermissionGroup, PermissionStatus> permissions =
            await PermissionHandler().requestPermissions(
                [PermissionGroup.photos, PermissionGroup.storage]);
        PermissionStatus status = permissions[PermissionGroup.photos];
        if (null != status && status == PermissionStatus.granted) {
          hasPermission = true;
        }
      } else {
        hasPermission = true;
      }
      localImages = await LocalImageProvider.getLatest(2);
      localAlbums = await LocalImageProvider.getAlbums(LocalAlbumType.all);
    } on PlatformException {
      print('Failed to get platform version.');
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

  void switchImage( String imageId, String src ) {
    LocalImageProvider.imageBytes(imageId, 500, 500 ).then((img){
    setState(() {
      _imgBytes = img;
      _hasImage = true;
      _imgSource = src;
    });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: _hasPermission
            ? Column(children: [
                Text(
                  'Images: ${_localImages.length}, Albums: ${_localAlbums.length}.',
                  style: TextStyle(fontSize: 24),
                ),
                Expanded(
                  child: ListView(
                    children: _localImages
                        .map((img) =>
                            GestureDetector( onTap: () => switchImage( img.id, "Image"), child: Text('Found: ${img.id}, date: ${img.creationDate}')))
                        .toList(),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: _localAlbums
                        .map(
                          (album) =>
                              GestureDetector( onTap: () => switchImage( album.coverImgId, "Album"),child: Text('Found: ${album.title}, id: ${album.id}, coverImgId: ${album.coverImgId}')),
                        )
                        .toList(),
                  ),
                ),
                Expanded( child: Column(
                  children: <Widget>[
                    Text('Selected image: $_imgSource'),
                    Expanded(child: _hasImage ? Image.memory(_imgBytes ) : Placeholder()),
                  ],
                ))
              ])
            : Center(child: Text('No permission')),
      ),
    );
  }
}
