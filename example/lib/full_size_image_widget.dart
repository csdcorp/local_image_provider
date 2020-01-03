import 'package:flutter/material.dart';
import 'package:local_image_provider/device_image.dart';
import 'package:local_image_provider/local_image.dart';

class FullSizeImageWidget extends StatelessWidget {
  FullSizeImageWidget(this.selectedImg, this.desiredHeight, this.desiredWidth);

  final LocalImage selectedImg;
  final int desiredHeight;
  final int desiredWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Image Provider Example'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Image(
              image: DeviceImage(selectedImg, scale: 1),
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
