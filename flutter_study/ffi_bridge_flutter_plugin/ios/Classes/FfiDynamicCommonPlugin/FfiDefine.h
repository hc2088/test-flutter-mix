/*
 * Copyright (C) 2005-present, 58.com.  All rights reserved.
 * Use of this source code is governed by a BSD type license that can be
 * found in the LICENSE file.
 */

/*  管理常量及通用宏函数的定义 */

#import <Foundation/Foundation.h>

#ifdef DEBUG
/// 调试状态
#define FfiLog(formatString,...) NSLog(@"[Ffi]:\n\tFile:%@, \n\tFunction:%s, \n\tLine:%d >>\n\t" formatString, [[NSString stringWithUTF8String:__FILE__] lastPathComponent] , __func__, __LINE__, ##__VA_ARGS__)
#else
/// 发布状态
#define FfiLog(...)
#endif

/// 弱引用
#define FfiWeakSelf(weakSelf) __weak typeof(self) weakSelf = self;
#define FfiWeakObject(weakObj, obj) __weak typeof(obj) weakObj = obj;
/// 强引用
#define FfiStrongObject(strongObj, obj) __strong typeof(obj) strongObj = obj;

/// h中的单例
#define FfiSingletonH() + (instancetype)sharedInstance;
/// m中的单例，需要传入类
#define FfiSingletonM(name) \
\
static id _FfiInstance = nil;\
+ (instancetype)sharedInstance{\
    if (_FfiInstance == nil) {\
        _FfiInstance = [[self alloc] init]; \
    } \
    return _FfiInstance; \
}\
+ (instancetype)allocWithZone:(NSZone *)zone\
{\
    static dispatch_once_t onceToken;\
    dispatch_once(&onceToken, ^{\
        _FfiInstance = [super allocWithZone:zone];\
    });\
    return _FfiInstance;\
}\
- (id)copyWithZone:(NSZone *)zone {\
    return [name sharedInstance];\
}\
- (id)mutableCopyWithZone:(NSZone *)zone {\
    return [name sharedInstance];\
}\


/// 结果回调
typedef void (^FfiCallback)(id result, NSError *error);

@interface FfiDefine : NSObject


@end
