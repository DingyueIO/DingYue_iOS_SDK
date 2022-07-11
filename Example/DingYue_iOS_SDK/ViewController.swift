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
        btn.frame = CGRect(x: 0, y: 0, width: 100, height: 50)
        btn.center = self.view.center
        btn.setTitle("go Purchase", for: [])
        btn.setTitleColor(UIColor.black, for: [])
        btn.addTarget(self, action: #selector(goPurchase), for: .touchUpInside)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.addSubview(purchaseBtn)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @objc func goPurchase(){
        //显示内购页-可以传复合要求的内购项信息对象
        let product = Subscription(type: "CONSUMABLE", name: "消耗品2", platformProductId: "com.dingyue.consumable2", price: "12.99", currencyCode: "USD",countryCode: "USD")
        let product2 = Subscription(type: "CONSUMABLE", name: "hello test", platformProductId: "com.dingyue.consumable1", appleSubscriptionGroupId: "", description: "消耗", period: "MONTH", price: "34.0", currencyCode: "USD", countryCode: "USD", priceTier: [], gracePeriod: true, icon: "", renewPriceChange: true)
        DYMobileSDK.showVisualPaywall(products: [product,product2], rootController: self) { receipt, purchaseResult, error in
            if error == nil {
               //购买成功
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
        baseViewController.present(nav, animated: true)
    }

//    public func clickPrivacyAction(baseViewController: UIViewController) {
//        let vc = LBWebViewController.init()
//        vc.url = "https://www.caretiveapp.com/pp/1549634329/"
//        vc.title = NSLocalizedString("Privacy_Policy", comment: "")
//        let nav = UINavigationController.init(rootViewController: vc)
//        baseViewController.present(nav, animated: true)
//    }
}

