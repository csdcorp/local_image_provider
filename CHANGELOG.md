# Changelog

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
