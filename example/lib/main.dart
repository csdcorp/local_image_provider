import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:local_image_provider/local_image_provider.dart';
import 'package:local_image_provider/local_image.dart';
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
  Uint8List _imgBytes;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    bool hasPermission = false;
    List<LocalImage> localImages = [];
    Uint8List imgBytes;

    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      PermissionStatus permission = await PermissionHandler()
          .checkPermissionStatus(PermissionGroup.storage);
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
      localImages = await LocalImageProvider.getLatest(10);
      imgBytes = await LocalImageProvider.imageBytes( localImages[0].id, 500, 500 );
    } on PlatformException {
      print('Failed to get platform version.');
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _localImages.addAll(localImages);
      _localImageCount = _localImages.length;
      print( 'Count is $_localImageCount, length is ${_localImages.length}');
      print('Total image bytes: ${imgBytes.length}');
      _imgBytes = imgBytes;
      _hasPermission = hasPermission;
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
                Text('Found: ${_localImages.length} images was $_localImageCount.'),
                Image.memory(_imgBytes),
                Expanded(
                  child: ListView(
                    children: _localImages
                        .map((img) => Text('Found: ${img.id}'))
                        .toList(),
                  ),
                )
              ])
            : Center(child: Text('No permission')),
      ),
    );
  }
}
