/*
 * Copyright (C) 2005-present, 58.com.  All rights reserved.
 * Use of this source code is governed by a BSD type license that can be
 * found in the LICENSE file.
 */

/*  Ffi整个流程管理类 */

#import "FfiProcessManager.h"
#import "FfiDartBridge.h"


@interface FfiProcessManager()


@end

@implementation FfiProcessManager


+ (FfiProcessManager *)sharedInstance {
    
    static FfiProcessManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[FfiProcessManager alloc] init];
    });
    return sharedInstance;
}

/// 开始Ffi的整个流程
- (void)startFfiProcessWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar
{
    // 设置和dart的通信
    [[FfiDartBridge sharedInstance] setDartChannelWithRegistrar:registrar];


}



@end
