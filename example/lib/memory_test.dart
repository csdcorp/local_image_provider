import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_image_provider_example/local_image_body_widget.dart';
import 'package:local_image_provider/local_image_provider.dart';
import 'package:local_image_provider/local_image.dart';
import 'package:local_image_provider/device_image.dart';

void main() {
  CustomImageCache();
  runApp(MemoryApp());
}

class CustomImageCache extends WidgetsFlutterBinding {
  @override
  ImageCache createImageCache() {
    print("Making my own cache");
    return MyImageCache();
  }
}

class MyImageCache extends ImageCache {
  MyImageCache() {
    // super.maximumSize = 0;
  }
}

/// A simple application that shows the functionality of the
/// local_image_provider plugin.
///
/// See [LocalImageBodyWidget] for the main part of the
/// example app.
class MemoryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(body: LIPMemoryWidget()));
  }
}

class LIPMemoryWidget extends StatefulWidget {
  const LIPMemoryWidget({
    Key key,
  }) : super(key: key);

  @override
  _LIPMemoryWidgetState createState() => _LIPMemoryWidgetState();
}

class _LIPMemoryWidgetState extends State<LIPMemoryWidget> {
  LocalImageProvider localImageProvider;
  ImageProvider _currentImg;
  File _fileImg;
  List<ImageProvider> _loadedImages = [];
  int _nextImgIndex = 0;
  int _totalBytes = 0;
  int _totalImages = 0;

  void _doMemory() async {
    bool available = await localImageProvider.initialize();
    if (available) {
      List<LocalImage> images = await localImageProvider.findLatest(100);
      print("available, got ${images.length}");
      _totalBytes = 0;
      _totalImages = 0;
      for (LocalImage image in images) {
        Uint8List bytes =
            await localImageProvider.imageBytes(image.id, 2000, 2000);
        print("Got bytes ${bytes.length}");
        setState(() {
          _totalImages++;
          _totalBytes += bytes.length;
        });
      }
      print("Total bytes retrieved = $_totalBytes");
    } else {
      print("Not available");
    }
  }

  void _doImageMemory() async {
    _nextImgIndex = 0;
    bool available = await localImageProvider.initialize();
    if (available) {
      List<LocalImage> images = await localImageProvider.findLatest(100);
      print("available, got ${images.length}");
      _loadedImages.clear();
      _totalImages = 0;
      _totalBytes = 0;
      for (LocalImage image in images) {
        _loadedImages.add(DeviceImage(image, scale: 1));
        setState(() {
          _totalImages++;
        });
      }
    } else {
      print("Not available");
    }
  }

  void _nextImage() {
    if (null == _loadedImages) {
      return;
    }
    if (_nextImgIndex >= _loadedImages.length) {
      _nextImgIndex = 0;
    }
    setState(() {
      _currentImg = _loadedImages[_nextImgIndex++];
      _totalBytes = localImageProvider.imgBytesLoaded;
    });
  }

  void _clearCache() {
    imageCache.clear();
    setState(() {});
  }

  void _clearImage() {
    setState(() {
      _currentImg = null;
      _fileImg = null;
    });
  }

  void _pickImage() async {
    // add the image_picker dependency and uncomment this to compare to
    // native Flutter image handling overhead.
    // var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    var image = await ImagePicker.pickVideo(source: ImageSource.gallery);
    setState(() {
      _fileImg = image;
    });
  }

  @override
  void initState() {
    super.initState();
    localImageProvider = LocalImageProvider();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Container(
          child: Text(
              'Total images: $_totalImages, bytes: $_totalBytes, cachedBytes: ${imageCache.currentSizeBytes}'),
        ),
        Container(
          child:
              RaisedButton(child: Text('Memory Check'), onPressed: _doMemory),
        ),
        Container(
          child: Row(
            children: <Widget>[
              RaisedButton(child: Text('Pick Image'), onPressed: _pickImage),
              RaisedButton(
                  child: Text('Image Memory Check'), onPressed: _doImageMemory),
              RaisedButton(child: Text('Next Image'), onPressed: _nextImage),
              RaisedButton(child: Text('Clear Cache'), onPressed: _clearCache),
              RaisedButton(child: Text('Clear Image'), onPressed: _clearImage),
            ],
          ),
        ),
        Expanded(
          child: Container(
            child: null != _currentImg
                ? Image(
                    image: _currentImg,
                  )
                : null != _fileImg ? Image.file(_fileImg) : Text('N/A'),
          ),
        ),
      ],
    );
  }
}
