/*
 * Copyright (C) 2005-present, 58.com.  All rights reserved.
 * Use of this source code is governed by a BSD type license that can be
 * found in the LICENSE file.
 */

#import "FfiBridgeFlutterPlugin.h"
#import "FfiProcessManager.h"

@implementation FfiBridgeFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
//    FlutterMethodChannel* channel = [FlutterMethodChannel
//                                     methodChannelWithName:@"ffi_bridge_flutter_plugin"
//                                           binaryMessenger:[registrar messenger]];
//    FfiBridgeFlutterPlugin* instance = [[FfiBridgeFlutterPlugin alloc] init];
//    [registrar addMethodCallDelegate:instance channel:channel];
    
    [[FfiProcessManager sharedInstance] startFfiProcessWithRegistrar:registrar];
}

//- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
//    if ([call.method isEqualToString:@"getPlatformVersion"]) {
//        NSString *version = [@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]];
//        result(version);
//    } else {
//        result(FlutterMethodNotImplemented);
//    }
//}

@end
