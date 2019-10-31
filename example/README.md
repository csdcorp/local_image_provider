# Local Image Provider Example

Demonstrates how to use the local_image_provider plugin. This example requires that the plugin has been installed and that the app has had the required permission declarations added. The example lists the available albums and images on the device.  


## Source

```dart

import 'package:local_image_provider/local_album.dart';
import 'package:local_image_provider/local_image.dart';
import 'package:local_image_provider/local_image_provider.dart';

void main() async {
  print('In main.');
  LocalImageProvider imageProvider = LocalImageProvider();
  bool hasPermission = await imageProvider.initialize();
  if ( hasPermission ) {
    List<LocalAlbum> albums =
        await imageProvider.findAlbums(LocalAlbumType.all);
    print('Got albums: ${albums.length}');
    albums.forEach((album) => print(
        'Title: ${album.title}, id: ${album.id}, coverImgId: ${album.coverImg}'));

    List<LocalImage> images = await imageProvider.findLatest(10);
    print('Got images: ${images.length}');
    images.forEach((image) => print(
        'id: ${image.id}, height: ${image.pixelHeight}, width: ${image.pixelWidth}'));
  }
  else {
        print("The user has denied access to images on their device.");
  }
}
```