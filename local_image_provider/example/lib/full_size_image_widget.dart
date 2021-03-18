import 'dart:io';

import 'package:flutter/material.dart';
import 'package:local_image_provider/device_image.dart';
import 'package:local_image_provider/local_image.dart';
import 'package:local_image_provider/local_image_provider.dart';
import 'package:video_player/video_player.dart';

class FullSizeImageWidget extends StatefulWidget {
  FullSizeImageWidget(this.selectedImg, this.desiredHeight, this.desiredWidth);

  final LocalImage selectedImg;
  final int desiredHeight;
  final int desiredWidth;

  @override
  _FullSizeImageWidgetState createState() => _FullSizeImageWidgetState();
}

class _FullSizeImageWidgetState extends State<FullSizeImageWidget> {
  VideoPlayerController? _controller;
  bool _isVideoReady = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedImg.isVideo) {
      setupVideo();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> setupVideo() async {
    String videoPath =
        await LocalImageProvider().videoFile(widget.selectedImg.id!);
    print(videoPath);
    File videoFile = File(videoPath);
    if (videoFile.existsSync()) {
      print("The file does exist");
    } else {
      print("No such file");
    }
    _controller = VideoPlayerController.file(videoFile)
      ..initialize().then((_) {
        print("The video controller initialized");
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {
          _isVideoReady = true;
        });
      });
    _controller?.addListener(_onVideoChange);
  }

  void _onVideoChange() async {
    if (_done) {
      return;
    }
    var currentPosition = await _controller?.position;
    var duration = _controller?.value.duration;
    print(
        "Notified by video: $currentPosition, duration: ${_controller?.value.duration}");
    print("Playing ${_controller?.value.isPlaying}");
    if (null != currentPosition &&
        duration != null &&
        currentPosition >= duration) {
      print("I think it's done");
      _done = true;
    }
  }

  void _startVideo() {
    _controller?.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Image Provider Example'),
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: widget.selectedImg.isVideo
                ? _isVideoReady
                    ? AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: Center(
                          child: VideoPlayer(_controller!),
                        ),
                      )
                    : Container()
                : Image(
                    image: DeviceImage(widget.selectedImg, scale: 1),
                    fit: BoxFit.contain,
                  ),
          ),
          _isVideoReady
              ? ElevatedButton(onPressed: _startVideo, child: Text('Play'))
              : Container(),
          _isVideoReady
              ? ElevatedButton(
                  onPressed: () => _controller?.pause(), child: Text('Play'))
              : Container()
        ],
      ),
    );
  }
}
