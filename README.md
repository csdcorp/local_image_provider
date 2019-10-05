# local_image_provider

A library for searching and retrieving the metadata and contents of the images and 
albums on a mobile device. 

This plugin contains a set of classes that make it easy to discover the metadata of the photos 
and galleries on the mobile device. It supports both Android and iOS. Photos can retrieve their 
bytes in a format compatible with the ImageProvider. Note that this plugin has no UI components, 
it provides information about local photos that can be used to develop other applications.

*Note*: This plugin is under development and will be extended over the coming weeks. 

## Using

To retrieve the list of latest local images just import the package and call the plugin, like so: 

```dart
import 'package:local_image_provider/local_image_provider.dart' as lip;

    bool hasPermission = await lip.LocalImageProvider.requestPermission();
    if ( hasPermission) {
        List<lip.LocalImage> images = await lip.LocalImageProvider.getLatest(10);
        images.forEach((image) => print( image.id));
    }
    else {
        print("The user has denied access to their local device.");
    }
```

Get an ImageProvider for an image like so: 

```dart
import 'package:local_image_provider/local_image_provider.dart' as lip;
import 'package:flutter/painting.dart';
// ...

List<lip.LocalImage> images = await lip.LocalImageProvider.getLatest(1);
if ( !images.isEmpty ) {
    lip.LocalImage image = images.first;
    MemoryImage mImg = MemoryImage( await image.getImageBytes( 300, 300 ));
}
else {
    print("No images found on the device.");
}
```
## Permissions

Applications using this plugin require user permissions. 
### iOS

Add the following keys to your _Info.plist_ file, located in `<project root>/ios/Runner/Info.plist`:

* `NSPhotoLibraryUsageDescription` - describe why your app needs permission for the photo library. This is called _Privacy - Photo Library Usage Description_ in the visual editor.

### Android

Add the storage permission to your _AndroidManifest.xml_ file, located in `<project root>/android/app/src/main/AndroidManifest.xml`:

* `android.permission.READ_EXTERNAL_STORAGE` - this allows the app to query and read the image and gallery information.
