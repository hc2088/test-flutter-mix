/*
 * Copyright (C) 2005-present, 58.com.  All rights reserved.
 * Use of this source code is governed by a BSD type license that can be
 * found in the LICENSE file.
 */

/*  Ffi通信流程管理类 */

#import <Foundation/Foundation.h>



#import <Flutter/FlutterPlugin.h>

NS_ASSUME_NONNULL_BEGIN

@interface FfiProcessManager : NSObject

+ (FfiProcessManager *)sharedInstance;

/// 开始Ffi流程
- (void)startFfiProcessWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;

@end

NS_ASSUME_NONNULL_END

