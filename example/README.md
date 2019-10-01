# local_image_provider_example

Demonstrates how to use the local_image_provider plugin. This example requires that the plugin has been installed and that the user has granted the application the required permissions. It then lists the available albums and images on the device. Permission detection is not shown in this example. The example application in the plugin package uses the [permission_handler](https://pub.dev/packages/permission_handler) plugin package. 


## Source

```dart

import 'package:local_image_provider/local_album.dart';
import 'package:local_image_provider/local_image.dart';
import 'package:local_image_provider/local_image_provider.dart';

void main() async {
  print('In main.');
  List<LocalAlbum> albums =
      await LocalImageProvider.getAlbums(LocalAlbumType.all);
  print('Got albums: ${albums.length}');
  albums.forEach((album) => print(
      'Title: ${album.title}, id: ${album.id}, coverImgId: ${album.coverImgId}'));

  List<LocalImage> images = await LocalImageProvider.getLatest(10);
  print('Got images: ${images.length}');
  images.forEach((image) => print(
      'id: ${image.id}, height: ${image.pixelHeight}, width: ${image.pixelWidth}'));
}
```