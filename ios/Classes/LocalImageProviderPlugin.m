#import "LocalImageProviderPlugin.h"
#import <local_image_provider/local_image_provider-Swift.h>

@implementation LocalImageProviderPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftLocalImageProviderPlugin registerWithRegistrar:registrar];
}
@end
