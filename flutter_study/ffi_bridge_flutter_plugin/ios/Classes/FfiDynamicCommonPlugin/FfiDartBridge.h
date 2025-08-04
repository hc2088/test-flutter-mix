/*
 * Copyright (C) 2005-present, 58.com.  All rights reserved.
 * Use of this source code is governed by a BSD type license that can be
 * found in the LICENSE file.
 */

/* 主要负责Dart及Native的通信 */

#import <Foundation/Foundation.h>
#import <FFIDynamicFlutter/FFIDynamicFlutter.h>

#import "FfiDefine.h"
#import <Flutter/FlutterPlugin.h>



@interface FfiDartBridge : NSObject<FFIProtocol>



/// 单例
FfiSingletonH();


/// 设置channel
- (void)setDartChannelWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;

@end
