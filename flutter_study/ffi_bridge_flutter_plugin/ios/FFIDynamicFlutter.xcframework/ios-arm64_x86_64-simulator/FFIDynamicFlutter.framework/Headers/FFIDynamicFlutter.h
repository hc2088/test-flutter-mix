 

#import <Foundation/Foundation.h>

#if defined(__cplusplus)
#define FFI_EXTERN extern "C" __attribute__((visibility("default"))) __attribute__((used))
#else
#define FFI_EXTERN extern __attribute__((visibility("default"))) __attribute__((used))
#endif


/// 同步方法调用
FFI_EXTERN const char *invokeCommonFuncSync(char *args);

/// FFI协议
@protocol FFIProtocol <NSObject>

/// 同步方法调用
/// @param args 参数
- (const char *)executeScriptSyncImpl:(char *)args;

@end

@interface FFIDynamicFlutter : NSObject

@property (nonatomic, weak) id<FFIProtocol> delegate;

+ (instancetype)sharedInstance;

@end
