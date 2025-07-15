//
//  AppDelegate.m
//  ios_flutter_app
//
//  Created by huchu on 2025/7/10.
//

#import "AppDelegate.h"
#import <flutter_boost/FlutterBoost.h>
#import "ios_flutter_app-Swift.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    
    
    //创建代理，做初始化操作
    BoostDelegate *delegate = [[BoostDelegate alloc] init];
    [[FlutterBoost instance] setup:application delegate:delegate callback:^(FlutterEngine *engine) {

        
    }];
    // 创建 UIWindow 并设置 rootViewController 为 storyboard 里的初始控制器
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *initialViewController = [storyboard instantiateInitialViewController];

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = initialViewController;
    [self.window makeKeyAndVisible];

 
    
    return YES;
}



@end
