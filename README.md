# Local Image Provider Plugin

A library for searching and retrieving the metadata and contents of the images and 
albums on a mobile device. 

This plugin contains a set of classes that make it easy to discover the metadata of the images 
and albums on the mobile device. It supports both Android and iOS. The content of images can be 
retrieved in a format compatible with the ImageProvider. Note that this plugin has no UI 
components, it provides information about local photos that can be used to develop other 
applications.

## Recent Updates
The 0.6.0 version changed some methods from 'get' to 'find' to better match the functionality. 

The 0.5.2 version of this plugin added permission handling. Previous versions used an external 
permission plugin to handle the required platform permissions but those dependencies were 
causing problems so they've been removed. The initialize method now handles permission 
checking and is required as the first call to the plugin. 

*Note*: This plugin is under development and will be extended over the coming weeks. It is not 
yet fully tested on multiple platforms. If you have any compatibility results you'd like to share please 
post them as [issues](https://github.com/csdcorp/local_image_provider/issues). 

## Using

To retrieve the list of latest local images just import the package and call the plugin, like so: 

```dart
import 'package:local_image_provider/local_image_provider.dart' as lip;

    lip.LocalImageProvider imageProvider = lip.LocalImageProvider();
    bool hasPermission = await imageProvider.initialize();
    if ( hasPermission) {
        List<lip.LocalImage> images = await imageProvider.findLatest(10);
        images.forEach((image) => print( image.id));
    }
    else {
        print("The user has denied access to images on their device.");
    }
```

Get an ImageProvider for an image like so: 

```dart
import 'package:local_image_provider/local_image_provider.dart' as lip;
import 'package:flutter/painting.dart';
// ...

    lip.LocalImageProvider imageProvider = lip.LocalImageProvider();
    bool hasPermission = await imageProvider.initialize();
    if ( hasPermission) {
        List<lip.LocalImage> images = await imageProvider.findLatest(1);
        if ( !images.isEmpty ) {
            lip.LocalImage image = images.first;
            MemoryImage mImg = MemoryImage( await image.getImageBytes( 300, 300 ));
        }
        else {
            print("No images found on the device.");
        }
    else {
        print("The user has denied access to images on their device.");
    }
```
## Permissions

Applications using this plugin require the following user permissions. 
### iOS

Add the following key to your _Info.plist_ file, located in `<project root>/ios/Runner/Info.plist`:

* `NSPhotoLibraryUsageDescription` - describe why your app needs permission for the photo library. This is called _Privacy - Photo Library Usage Description_ in the visual editor. This permission is required for the app to read the image and album information. 

### Android

Add the storage permission to your _AndroidManifest.xml_ file, located in `<project root>/android/app/src/main/AndroidManifest.xml`:

* `android.permission.READ_EXTERNAL_STORAGE` - this allows the app to query and read the image and album information.
