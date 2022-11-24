import 'package:flutter/material.dart';
import 'package:local_image_provider/local_image_provider.dart';

class AlbumsListWidget extends StatelessWidget {
  const AlbumsListWidget({
    Key? key,
    required this.localImages,
    required this.localAlbums,
    required this.switchAlbum,
    required this.localImageProvider,
    this.selectedAlbum,
    required this.limited,
  }) : super(key: key);

  final List<LocalImage> localImages;
  final List<LocalAlbum> localAlbums;
  final void Function(LocalAlbum album) switchAlbum;
  final LocalAlbum? selectedAlbum;
  final bool limited;
  final LocalImageProvider localImageProvider;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            limited
                ? 'Found(limited) - Images: ${localImages.length}; Albums: ${localAlbums.length}.'
                : 'Found - Images: ${localImages.length}; Albums: ${localAlbums.length}.',
            style: Theme.of(context).textTheme.headline6,
            textAlign: TextAlign.center,
          ),
          Container(
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Albums',
                  style: Theme.of(context).textTheme.headline6,
                ),
                // ElevatedButton(
                //   onPressed: () => _newAlbum(context),
                //   child: Icon(Icons.add),
                // )
              ],
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
                              'Title: ${album.title}; images: ${album.imageCount}, id: ${album.id}; cover Id: ${album.coverImg?.id}',
                              style: Theme.of(context).textTheme.subtitle1,
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

  _newAlbum(BuildContext context) {
    String _title = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('New Album'),
          content: TextField(
            decoration: InputDecoration(
              labelText: 'Title',
            ),
            onChanged: (value) {
              _title = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            // // TextButton(
            // //   onPressed: () {
            // //     Navigator.of(context).pop();
            // //     localImageProvider.newAlbum(_title, false);
            // //   },
            //   child: Text('Create'),
            // ),
          ],
        );
      },
    );
  }
}
