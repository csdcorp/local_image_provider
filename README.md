# Local Image Provider Plugin

A library for searching and retrieving the metadata and contents of the images and 
albums on a mobile device. 

This plugin contains a set of classes that make it easy to discover the metadata of the images 
and albums on the mobile device. It supports both Android and iOS. The content of images can be 
retrieved in a format compatible with the ImageProvider. Note that this plugin has no UI 
components, it provides information about local photos that can be used to develop other 
applications.

## Recent Updates
The 0.7.0 version adds the DeviceImage class which can be used to more easily and efficiently display a LocalImage in a Flutter Image widget. This version also provides the count of images in each LocalAlbum and exposes the cover image for an album as LocalImage so that it can be used with a DeviceImage. Test coverage has also improved substantially. Check the change log for some breaking changes in 0.7.0. 

The 0.6.0 version changed some methods from 'get' to 'find' to better match the functionality. 

*Note*: This plugin is under development and will be extended over the coming weeks. It is not 
yet fully tested on multiple platforms. If you have any compatibility results you'd like to share please 
post them as [issues](https://github.com/csdcorp/local_image_provider/issues). 

## Using

To retrieve the list of the ten latest local images just import the package and call the plugin, like so: 

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
            DeviceImage deviceImg = DeviceImage( image );
        }
        else {
            print("No images found on the device.");
        }
    else {
        print("The user has denied access to images on their device.");
    }
```

The DeviceImage can be used directly as an ImageProvider in an Image widget in Flutter. Assuming that _selectedImg is a LocalImage then that image can be displayed in a Flutter Widget tree like so:  
```dart
    Container(
        child: Image( image: DeviceImage( _selectedImg ),
        ),
    ),
```

## Permissions

Applications using this plugin require the following user permissions. 
### iOS

Add the following key to your _Info.plist_ file, located in `<project root>/ios/Runner/Info.plist`:

* `NSPhotoLibraryUsageDescription` - describe why your app needs permission for the photo library. This is called _Privacy - Photo Library Usage Description_ in the visual editor. This permission is required for the app to read the image and album information. 

### Android

Add the storage permission to your _AndroidManifest.xml_ file, located in `<project root>/android/app/src/main/AndroidManifest.xml`:

* `android.permission.READ_EXTERNAL_STORAGE` - this allows the app to query and read the image and album information.
