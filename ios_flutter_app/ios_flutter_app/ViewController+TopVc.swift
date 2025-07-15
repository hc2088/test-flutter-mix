//
//  ViewController+TopVc.swift
//  ios_flutter_app
//
//  Created by huchu on 2025/7/15.
//

import UIKit



extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = self.presentedViewController {
            return presented.topMostViewController()
        } else if let tabBarController = self as? UITabBarController,
                  let selected = tabBarController.selectedViewController {
            return selected.topMostViewController()
        } else if let navigationController = self as? UINavigationController,
                  let visible = navigationController.visibleViewController {
            return visible.topMostViewController()
        } else if let lastChild = self.children.last {
            return lastChild.topMostViewController()
        } else {
            return self
        }
    }
}
