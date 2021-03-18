import 'package:flutter/material.dart';
import 'package:local_image_provider_example/full_size_image_widget.dart';
import 'package:local_image_provider/device_image.dart';
import 'package:local_image_provider/local_image.dart';

class ImagePreviewWidget extends StatelessWidget {
  const ImagePreviewWidget(
      {Key key,
      this.hasImage,
      this.imgSource,
      this.selectedImg,
      this.desiredHeight,
      this.desiredWidth,
      this.heightController,
      this.widthController,
      this.updateDesired})
      : super(key: key);

  final int desiredHeight;
  final int desiredWidth;
  final bool hasImage;
  final String imgSource;
  final TextEditingController heightController;
  final TextEditingController widthController;
  final void Function(String text) updateDesired;
  final LocalImage selectedImg;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: hasImage
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Flexible(
                        flex: 2,
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Selected: $imgSource',
                            style: Theme.of(context).textTheme.headline6,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Height: ',
                            alignLabelWithHint: true,
                            hintText:
                                '$desiredHeight', //the preferred height of the image fetched
                            hintStyle: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          controller: heightController,
                          onChanged: updateDesired,
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Width: ',
                            alignLabelWithHint: true,
                            hintText:
                                '$desiredWidth', //the preferred width of the image fetched
                            hintStyle: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          controller: widthController,
                          onChanged: updateDesired,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Theme.of(context).canvasColor,
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: FlatButton(
                            child: Image(
                              image: DeviceImage(selectedImg, scale: 1),
                              fit: BoxFit.contain,
                            ),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => FullSizeImageWidget(
                                    selectedImg, desiredHeight, desiredWidth),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Image id:\n ${selectedImg.id}\n${selectedImg.mediaType}',
                            softWrap: true,
                            overflow: TextOverflow.clip,
                            style: Theme.of(context).textTheme.caption,
                          ),
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
                style: Theme.of(context).textTheme.headline5,
              ),
            ),
    );
  }
}
