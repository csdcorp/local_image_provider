# Changelog

## 2.4.1

### Updates
* fix compile error on latest Xcode

## 2.4.0

### Updates
* fix exceptions from null image info columns on Android
* now catches top level exceptions and returns them as platform exceptions on Flutter

## 2.3.1

### Updates
* fix formatting of some files

## 2.3.0

### Updates
* added the optional new parameter `compression` to `imageBytes`, `deviceImage`, `getCoverImage`, and `localImage` to allow the JPEG compression of the fetched image to be controlled. 
* new `hasLimitedPermission` supports detecting when the library has been granted limited access to images 
on iOS 14+. This is always false on Android. 
* now properly handles limited permission on iOS 14+

## 2.2.1

### Updates
* fix for iOS `imageBytes` implementation, width and height were swapped, causing images to be resized incorrectly

## 2.2.0

### Updates
* fix for `findLatest` to include videos in the list of returned latest media
* fix for Android Q SQL issue

## 2.1.0

### New
  * `cleanup` method on `LocalImageProvider` removes all temporary files created by the plugin

### Updates
* fix for `videoFile` call with id that does not exist

## 2.0.0

### Breaking
  * Upgraded to New Swift 1.12 plugin structure, may work with older Flutter version but not guaranteed
  * This version only works with Flutter 1.17.0 and above due to interaction with the Flutter cache
  
### New
* `LocalImage` now includes both images and videos in the returned list
* new `getVideoFile` method on `LocalImageProvider` retrieves a file path for a video. 
* added the `mediaType`, `isVideo` and `isImage` properties to `LocalImage`
* added `fileName` and `fileSize` properties to `LocalImage`
* control cache usage with the new `maxCacheDimension` property on `LocalImageProvider`, requires Flutter 1.17.0
* test coverage improvements
* pubspec changes for Flutter 1.17, minimum version now 1.17.0
* added `videoCount` to `LocalAlbum`
* `findImagesInAlbum` now returns both images and video, use the `isVideo` and `isImage` properties to filter

## 1.0.0

### Updates
* fix for file not found exception in `imageBytes` 
* `DeviceImage` now loads a default image if the load fails 

## 0.9.0

### New
  * Added `albumType` to `LocalAlbum` provides more detail on the album type for iOS, always `album` for Android
  * New options added for `LocalAlbumType`
  * `FindAlbum` now restricts by the requested `LocalAlbumType`
  
### Breaking

  * `coverImgId` on `LocalAlbum` which was deprecated is now gone, use `coverImg` instead

## 0.8.2

### Breaking

  * Upgrade to Swift 5 to match Flutter 1.12. Projects including this plugin must be using Swift 5. 
  
## 0.8.1

### Updates

  * Upgrade Kotlin to 1.3.5 to match the Flutter 1.12 version
  * Upgrade Gradle build to 3.5.0 to match the Flutter 1.12 version

## 0.8.0

### Updates
* updated for Flutter 1.12.x, fix for DeviceImage, likely won't work for earlier Flutter versions

## 0.7.5

### Updates
* findImagesInAlbum was returning non image assets like video, this is fixed now, only images are returned
* the count member of LocalAlbum didn't match the count of images returned by findImagesInAlbum, this is fixed by the change above.
  
## 0.7.4

### Updates
* initialize could return true and still fail to load the first few images, now ensures all init is done before returning
  
## 0.7.3

### Updates
* fix for break in iOS implementation in 0.7.2
  
## 0.7.2

### Updates
* fix for prompt for user photo permission before initialize on iOS 10/11
  
## 0.7.1

### New
* LocalImage hasPermission added

### Updates
* fix for permission handling to ensure it doesn't conflict with other permission requests

## 0.7.0

### Breaking
* LocalAlbum.coverImgId has been deprecated
* reordered height, width parameters on LocalImage constructor to match imageBytes method
* LocalImage.getImageBytes now takes a LocalImageProvider as a parameter to improve testability
* LocalAlbum.getCoverImage now takes a LocalImageProvider as a parameter to improve testability

### New
* LocalAlbum.coverImg has been added
* LocalAlbum.imageCount property
* DeviceImage has been added, use instead of using the getImageBytes method directly
* LocalImage constructor is now const
* LocalAlbum constructor is now const
* added == and hashCode for both LocalImage and LocalAlbum, note they depend only on the id
* LocalImageProvder stats added for image loading, see resetStats(), imgBytesLoaded, lastLoadTime, totalLoadTime 

## 0.6.0

### Breaking
* renamed getLatest -> findLatest
* renamed getAlbums -> findAlbums
  
### New
* findImagesInAlbum to list all the images contained in a particular album


## 0.5.2
### Breaking
* Added initialize method, now required before using the plugin
* Methods are no longer static, you must now create an instance and use that
  
### Updates
* Added permission checking to both iOS and Android
 
## 0.5.1
* Fixes issues pointed out by pub_dev analysis
* updated description in pubspec
* updated json_annotation dependency to 3.0
* ran format on dart files

## 0.5.0

* Initial release with limited functionality, supports only:
  * getting album descriptions
  * getting latest image descriptions
  * getting bytes for image. 
* Android and iOS 10+ support
