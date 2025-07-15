//
//  ViewController.swift
//  ios_flutter_app
//
//  Created by huchu on 2025/7/15.
//

import UIKit
import flutter_boost

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func openMainPageVc(_ sender: Any) {
        let options = FlutterBoostRouteOptions()
        options.pageName = "mainPage"
        options.arguments = ["key" :"value"]
 
        //页面是否透明（用于透明弹窗场景），若不设置，默认情况下为true
        options.opaque = true

        //这个是push操作完成的回调，而不是页面关闭的回调！！！！
        options.completion = { completion in
            print("open operation is completed")
        }

        //这个是页面关闭并且返回数据的回调，回调实际需要根据您的Delegate中的popRoute来调用
        options.onPageFinished = { dic in
            print(dic)
        }

        FlutterBoost.instance().open(options)
        
        
    }
    
    @IBAction func openSimplePageVc(_ sender: Any) {
        
        let options = FlutterBoostRouteOptions()
        options.pageName = "simplePage"
        options.arguments = ["key" :"value"]

        //页面是否透明（用于透明弹窗场景），若不设置，默认情况下为true
        options.opaque = true

        //这个是push操作完成的回调，而不是页面关闭的回调！！！！
        options.completion = { completion in
            print("open operation is completed")
        }

        //这个是页面关闭并且返回数据的回调，回调实际需要根据您的Delegate中的popRoute来调用
        options.onPageFinished = { dic in
            print(dic)
        }

        FlutterBoost.instance().open(options)
        
        
    }
    
 
    

}
