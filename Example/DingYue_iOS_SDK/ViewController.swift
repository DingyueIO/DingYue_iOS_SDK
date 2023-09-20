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
    lazy var purchaseSubscriptionBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("SubscriptionBtn", for: [])
        btn.setTitleColor(UIColor.black, for: [])
        btn.addTarget(self, action: #selector(goPurchaseSubscriptionAction), for: .touchUpInside)
        btn.backgroundColor = .red
        return btn
    }()
    
    lazy var purchaseConsumptionBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("ConsumptionBtn", for: [])
        btn.setTitleColor(UIColor.black, for: [])
        btn.addTarget(self, action: #selector(goPurchaseConsumptionAction), for: .touchUpInside)
        btn.backgroundColor = .blue
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(purchaseSubscriptionBtn)
        self.view.addSubview(purchaseConsumptionBtn)
        
        
        purchaseSubscriptionBtn.translatesAutoresizingMaskIntoConstraints = false
        purchaseSubscriptionBtn.leadingAnchor.constraint(equalTo: self.view.leadingAnchor,constant: 16.0).isActive = true
        purchaseSubscriptionBtn.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        purchaseSubscriptionBtn.heightAnchor.constraint(equalToConstant: 56).isActive = true
        
        purchaseConsumptionBtn.translatesAutoresizingMaskIntoConstraints = false
        purchaseConsumptionBtn.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16.0).isActive = true
        purchaseConsumptionBtn.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        purchaseConsumptionBtn.heightAnchor.constraint(equalToConstant: 56).isActive = true
        purchaseConsumptionBtn.leadingAnchor.constraint(equalTo: purchaseSubscriptionBtn.trailingAnchor, constant: 10).isActive = true
        purchaseConsumptionBtn.widthAnchor.constraint(equalTo: purchaseSubscriptionBtn.widthAnchor).isActive = true
    }
    
    
    @objc func goPurchaseSubscriptionAction(){
        //显示内购页-可以传复合要求的内购项信息对象
        let defaultProuct1 = Subscription(type: "SUBSCRIPTION", name: "Week", platformProductId: "testWeek", price: "7.99", currencyCode: "USD", countryCode: "US")
        let defaultProuct2 = Subscription(type: "SUBSCRIPTION", name: "Year", platformProductId: "testYear", appleSubscriptionGroupId: nil, description: "default product item", period: "Year", price: "49.99", currencyCode: "USD", countryCode: "US", priceTier: nil, gracePeriod: nil, icon: nil, renewPriceChange: nil)
        //显示内购页
        
        let extra:[String:Any] = [
            "phoneNumber": "1999999999",
            "phoneCountry" : "国家",
            "purchasedProducts" : purchasedProducts,
            "mainColor": "white"
        ]
        
        DYMobileSDK.showVisualPaywall(products: [defaultProuct1,defaultProuct2], rootController: self, extras: extra) { receipt, purchasedResult, error in
            if error == nil {
               //购买成功
                print("订阅购买成功")
                DispatchQueue.main.async {
                    self.purchaseSubscriptionBtn.setTitle("订阅购买成功", for: [])
                    
                    DYMobileSDK.activate { results, error in
                        if let res = results, let hasPurchasedItems = res["subscribedOjects"] as? [[String:Any]] {
                            purchasedProducts = hasPurchasedItems
                            
                            for sub in DYMobileSDK.getProductItems() ?? [] {
                                print("test ----, getProductItems = \(sub.platformProductId)")
                            }
                        }
                    }
                }
            } else {
                print("订阅购买失败， error = \(error)")
            }
        }
    }
    
    @objc func goPurchaseConsumptionAction() {
        let testConsumptionProductIf = "test.consumablesA"
        DYMobileSDK.purchaseConsumption(productId: testConsumptionProductIf, count: 2) { receipt, purchaseResult, error in
            if error == nil {
               //购买成功
                print("消耗品购买成功")
                DispatchQueue.main.async {
                    self.purchaseConsumptionBtn.setTitle("消耗品购买成功", for: [])
                }
            } else {
                print("消耗品购买成功， error = \(error)")
            }
        }
    }
}

//implement methods to purchase page user terms and privacy click events
extension UIViewController:DYMPayWallActionDelegate {
    public func clickTermsAction(baseViewController: UIViewController) {
        //do some customed thing
        let vc = LBWebViewController.init()
        vc.url = "url"
        vc.title = NSLocalizedString("Terms_of_Service", comment: "")
        let nav = UINavigationController.init(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        baseViewController.present(nav, animated: true)
    }

    public func clickPrivacyAction(baseViewController: UIViewController) {
        let vc = LBWebViewController.init()
        vc.url = "url"
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

