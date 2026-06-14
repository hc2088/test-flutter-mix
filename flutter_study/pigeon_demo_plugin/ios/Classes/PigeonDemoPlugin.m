#import "PigeonDemoPlugin.h"
#import "messages.g.h"
#import <UIKit/UIKit.h>

@interface PigeonDemoPlugin () <PGNNativeDemoApi>
@end

@implementation PigeonDemoPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  PigeonDemoPlugin* instance = [[PigeonDemoPlugin alloc] init];
  SetUpPGNNativeDemoApi(registrar.messenger, instance);
}

- (nullable PGNDeviceInfoReply*)getDeviceInfoRequest:(PGNDeviceInfoRequest*)request
                                               error:(FlutterError *_Nullable *_Nonnull)error {
  UIDevice* device = [UIDevice currentDevice];
  NSString* prefix = request.prefix ?: @"Flutter";
  PGNDeviceInfoReply* reply = [[PGNDeviceInfoReply alloc] init];
  reply.platform = @"iOS";
  reply.osVersion = device.systemVersion;
  reply.model = device.model;
  reply.message = [NSString stringWithFormat:@"%@ from Objective-C via Pigeon", prefix];
  return reply;
}

- (nullable PGNCounterReply*)incrementRequest:(PGNCounterRequest*)request
                                        error:(FlutterError *_Nullable *_Nonnull)error {
  NSInteger nextValue = [request.value integerValue] + 1;
  PGNCounterReply* reply = [[PGNCounterReply alloc] init];
  reply.value = @(nextValue);
  reply.message = [NSString stringWithFormat:@"Objective-C calculated %ld", (long)nextValue];
  return reply;
}
@end
