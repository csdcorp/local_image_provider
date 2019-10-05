# Changelog


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
