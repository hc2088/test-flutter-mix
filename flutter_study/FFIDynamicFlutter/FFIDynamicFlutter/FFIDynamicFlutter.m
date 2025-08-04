 
#import "FFIDynamicFlutter.h"

/// 同步方法调用，通过executeScriptSyncImpl进行回调
/// @param args 参数
/// @return 返回值
const char *invokeCommonFuncSync(char *args) {
    if ([FFIDynamicFlutter sharedInstance].delegate &&
        [[FFIDynamicFlutter sharedInstance].delegate respondsToSelector:@selector(executeScriptSyncImpl:)]) {
        return [[FFIDynamicFlutter sharedInstance].delegate executeScriptSyncImpl:args];
    }
    return "";
}

@implementation FFIDynamicFlutter

+ (instancetype)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

@end
