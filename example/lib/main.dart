import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:local_image_provider/local_image_provider.dart';
import 'package:local_image_provider/local_image.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _localImageCount = 0;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    List<LocalImage> localImages = [];
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      localImages = await LocalImageProvider.getLatest(10);
    } on PlatformException {
      print( 'Failed to get platform version.' );
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _localImageCount = localImages.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_localImageCount\n'),
        ),
      ),
    );
  }
}
