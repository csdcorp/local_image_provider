import 'package:flutter/material.dart';
import 'package:local_image_provider/local_image.dart';
import 'package:local_image_provider/local_album.dart';

class AlbumsListWidget extends StatelessWidget {
  const AlbumsListWidget({
    Key key,
    this.localImages,
    this.localAlbums,
    this.switchAlbum,
    this.selectedAlbum,
  }) : super(key: key);

  final List<LocalImage> localImages;
  final List<LocalAlbum> localAlbums;
  final void Function(LocalAlbum album) switchAlbum;
  final LocalAlbum selectedAlbum;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Found - Images: ${localImages.length}; Albums: ${localAlbums.length}.',
            style: Theme.of(context).textTheme.title,
            textAlign: TextAlign.center,
          ),
          Container(
            padding: EdgeInsets.all(8),
            child: Text(
              'Albums',
              style: Theme.of(context).textTheme.title,
            ),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).canvasColor,
              padding: EdgeInsets.all(8),
              child: ListView(
                children: localAlbums
                    .map(
                      (album) => GestureDetector(
                          onTap: () => switchAlbum(album),
                          child: Container(
                            color: album == selectedAlbum
                                ? Colors.black12
                                : Theme.of(context).canvasColor,
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'Title: ${album.title}; images: ${album.imageCount}, id: ${album.id}; cover Id: ${album.coverImg.id}',
                              style: Theme.of(context).textTheme.subhead,
                            ),
                          )),
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
