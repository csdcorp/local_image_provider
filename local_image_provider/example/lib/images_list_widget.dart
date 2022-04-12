import 'package:flutter/material.dart';
import 'package:local_image_provider/local_image_provider.dart';

class ImagesListWidget extends StatelessWidget {
  const ImagesListWidget({
    Key? key,
    required this.imgHeading,
    required this.localImages,
    required this.switchImage,
    this.selectedImage,
  }) : super(key: key);

  final String imgHeading;
  final List<LocalImage> localImages;
  final void Function(LocalImage image, String src) switchImage;
  final LocalImage? selectedImage;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(8),
            child: Text(
              'Images - $imgHeading (Images in album: ${localImages.length})',
              style: Theme.of(context).textTheme.headline6,
            ),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).canvasColor,
              padding: EdgeInsets.all(8),
              child: ListView(
                children: localImages
                    .map(
                      (img) => GestureDetector(
                        onTap: () => switchImage(img, 'Images'),
                        child: Container(
                          color: img == selectedImage
                              ? Colors.black12
                              : Theme.of(context).canvasColor,
                          padding: EdgeInsets.all(10),
                          child: Text(
                            'Id: ${img.id} Name: ${img.fileName} created: ${img.creationDate}',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
