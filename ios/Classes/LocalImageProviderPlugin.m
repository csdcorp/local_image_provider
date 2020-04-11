#import "LocalImageProviderPlugin.h"
#if __has_include(<local_image_provider/local_image_provider-Swift.h>)
#import <local_image_provider/local_image_provider-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "local_image_provider-Swift.h"
#endif

@implementation LocalImageProviderPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftLocalImageProviderPlugin registerWithRegistrar:registrar];
}
@end
