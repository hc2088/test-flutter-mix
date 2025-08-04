/*
 * Copyright (C) 2005-present, 58.com.  All rights reserved.
 * Use of this source code is governed by a BSD type license that can be
 * found in the LICENSE file.
 */

#import "FfiDartBridge.h"
#import "FfiDefine.h"
#import <Flutter/Flutter.h>


@interface FfiDartBridge ()


/// binaryMessenger
@property (nonatomic, weak) NSObject<FlutterBinaryMessenger> *binaryMessenger;

@end

@implementation FfiDartBridge

FfiSingletonM(FfiDartBridge);


- (void)setDartChannelWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    // 设置同步执行代理
    [FFIDynamicFlutter sharedInstance].delegate = self;

    self.binaryMessenger = (id <FlutterBinaryMessenger>)registrar.messenger;



}



#pragma mark - FfiFFIProtocol

- (const char *)executeScriptSyncImpl:(char *)args
{
    NSString *str = [NSString stringWithUTF8String:args];
    NSLog(@"str = %@", str);
    return str.UTF8String;
}

@end
