//
//  AppDelegate+Task.swift
//  ios_flutter_app
//
//  Created by huchu on 2025/7/15.
//

import UIKit

extension AppDelegate {
    
    @objc static func appDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
//    @objc static func topMostViewController() -> UIViewController? {
//        //return (UIApplication.shared.delegate as! AppDelegate).tabbarViewController?.selectedViewController?.topMost()
//        return (UIApplication.shared.delegate as! AppDelegate).window.rootViewController?.topMostViewController()
//    }
//    
//    @objc static func currentViewController() -> UIViewController? {
//        return ((UIApplication.shared.delegate as! AppDelegate).tabbarViewController?.selectedViewController as? MiWear_MHNavigationController)?.topViewController
//    }
//    
//    @objc static func currentTabbarVC() -> UITabBarController? {
//        return (UIApplication.shared.delegate as! AppDelegate).tabbarViewController
//    }
//    
//    @objc static func currentNavigationController() -> MiWear_MHNavigationController? {
//        return (UIApplication.shared.delegate as! AppDelegate).tabbarViewController?.selectedViewController as? MiWear_MHNavigationController
//    }
//    
//    @objc public static func appName() -> String {
//        return mhwInfoPlistLocalizedString("CFBundleDisplayName", "App")
//    }
    
    static func getCurrentViewController() -> UIViewController? {
        guard let rootViewController = UIApplication.shared.delegate?.window??.rootViewController else {
            return nil
        }
        return getVisibleViewController(from: rootViewController)
    }
    
    private static func getVisibleViewController(from vc: UIViewController) -> UIViewController? {
        if let navigationController = vc as? UINavigationController {
            return getVisibleViewController(from: navigationController.visibleViewController ?? navigationController)
        } else if let tabBarController = vc as? UITabBarController {
            return getVisibleViewController(from: tabBarController.selectedViewController ?? tabBarController)
        } else if let presentedViewController = vc.presentedViewController {
            return getVisibleViewController(from: presentedViewController)
        } else {
            return vc
        }
    } 
    
}
