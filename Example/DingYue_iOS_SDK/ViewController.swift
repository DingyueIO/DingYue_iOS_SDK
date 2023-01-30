//
//  ViewController.swift
//  DingYue_iOS_SDK
//
//  Created by DingYueIO on 07/07/2022.
//  Copyright (c) 2022 DingYueIO. All rights reserved.
//

import UIKit
import DingYue_iOS_SDK

class ViewController: UIViewController {
    lazy var purchaseBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.frame = CGRect(x: 0, y: 0, width: 200, height: 50)
        btn.center = self.view.center

        let perferLang = NSLocale.preferredLanguages[0]
        var langParamStr = NSLocale.current.languageCode ?? ""
        if (perferLang.range(of: "Hans") != nil) {
            langParamStr = "zh-Hans"
        } else if (perferLang.range(of: "Hant") != nil) {
            langParamStr = "zh-Hant"
        }

        btn.setTitle(NSLocale.preferredLanguages[0], for: [])
        btn.setTitleColor(UIColor.black, for: [])
        btn.addTarget(self, action: #selector(goPurchase), for: .touchUpInside)

        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.addSubview(purchaseBtn)

        let btn2 = UIButton(type: .custom)
        btn2.frame = CGRect(x: 10, y: 20, width: 300, height: 50)
        btn2.setTitle("9999", for: [])
        btn2.setTitleColor(UIColor.black, for: [])
        self.view.addSubview(btn2)

        //创建总开关
        DYMobileSDK.createGlobalSwitch(globalSwitch: GlobalSwitch(showName: "TestDebug2", varName: "TestDebug2", value: true)) { results, error in
            if error == nil {
                if results?.errmsg == nil {
                    print("ok")
                }
            }
        }

        //
        print("dingyue uuid = \(DYMobileSDK.requestDeviceUUID())")

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @objc func goPurchase(){
        let timeInterval: TimeInterval = Date.init(timeIntervalSinceNow: 0).timeIntervalSince1970
        let milli = CLongLong(round(timeInterval*1000))
        print("客户端 时间戳 = \(milli)")

        //显示内购页-可以传复合要求的内购项信息对象
        let defaultProuct1 = Subscription(type: "SUBSCRIPTION", name: "Week", platformProductId: "testWeek", price: "7.99", currencyCode: "USD", countryCode: "US")
        let defaultProuct2 = Subscription(type: "SUBSCRIPTION", name: "Year", platformProductId: "testYear", appleSubscriptionGroupId: nil, description: "default product item", period: "Year", price: "49.99", currencyCode: "USD", countryCode: "US", priceTier: nil, gracePeriod: nil, icon: nil, renewPriceChange: nil)
        DYMobileSDK.showVisualPaywall(products: [defaultProuct1,defaultProuct2], rootController: self) { receipt, purchasedResult, error in
            if error == nil {
               //购买成功
                print("订阅购买成功")
                DispatchQueue.main.async {
                    self.purchaseBtn  .setTitle("订阅购买成功", for: [])
                }
            }
        }
    }

}

//implement methods to purchase page user terms and privacy click events
extension UIViewController:DYMPayWallActionDelegate {
    public func clickTermsAction(baseViewController: UIViewController) {
        //do some customed thing
        let vc = LBWebViewController.init()
        vc.url = "https://www.caretiveapp.com/tou/1549634329/"
        vc.title = NSLocalizedString("Terms_of_Service", comment: "")
        let nav = UINavigationController.init(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        baseViewController.present(nav, animated: true)
    }

    public func clickPrivacyAction(baseViewController: UIViewController) {
        let vc = LBWebViewController.init()
        vc.url = "https://www.caretiveapp.com/pp/1549634329/"
        vc.title = NSLocalizedString("Privacy_Policy", comment: "")
        let nav = UINavigationController.init(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        baseViewController.present(nav, animated: true)
    }

    public func clickCloseButton(baseViewController: UIViewController) {
        print("点击了关闭按钮")
    }

    public func payWallDidAppear(baseViewController: UIViewController) {
        print("内购页显示")
    }
    public func payWallDidDisappear(baseViewController: UIViewController) {
        print("内购页消失")
    }
}

