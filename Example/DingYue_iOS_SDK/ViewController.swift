//
//  ViewController.swift
//  DingYue_iOS_SDK
//
//  Created by DingYueIO on 07/07/2022.
//  Copyright (c) 2022 DingYueIO. All rights reserved.
//

import UIKit
import DingYue_iOS_SDK
import FCUUID

class ViewController: UIViewController {
 
    
    private let tableView = UITableView()
       private let buttonTitles = ["SubscriptionBtn", "ConsumptionBtn", "LuaScriptBtn", "guidePageBtn", "CustomerProperties","GetSegmentInfo"]
       private let buttonActions: [Selector] = [
           #selector(goPurchaseSubscriptionAction),
           #selector(goPurchaseConsumptionAction),
           #selector(luaTestAction),
           #selector(gotoWebGuide),
           #selector(setCustomerProperties),
           #selector(getSegmentInfo)
       ]
       
       override func viewDidLoad() {
           super.viewDidLoad()
           setupTableView()
       }
       
       private func setupTableView() {
           tableView.delegate = self
           tableView.dataSource = self
           tableView.register(ButtonCell.self, forCellReuseIdentifier: "ButtonCell")
           tableView.translatesAutoresizingMaskIntoConstraints = false
           
           view.addSubview(tableView)
           NSLayoutConstraint.activate([
               tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
               tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
               tableView.topAnchor.constraint(equalTo: view.topAnchor),
               tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
           ])
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
                    self.showAlert(title: "成功", message: "订阅购买成功")
                    
                }
            } else {
                self.showAlert(title: "失败", message: error?.localizedDescription ?? "订阅购买失败，请重试。")

            }
        }
    }
    
    @objc func goPurchaseConsumptionAction() {
        let testConsumptionProductIf = "test.consumablesA"
        DYMobileSDK.purchaseConsumption(productId: testConsumptionProductIf, count: 2) { receipt, purchaseResult, error in
            if error == nil {
               //购买成功
                print("消耗品购买成功")
                self.showAlert(title: "成功", message: "消耗品购买成功")
            }else  {
                self.showAlert(title: "失败", message: error?.localizedDescription ?? "购买失败，请重试。")
            }
        }
    }
    @objc func luaTestAction() {
        TestLuaOperation.sharedInstance().callLuaFunction("fun5", withParams: [], withReturnCount: 0, withKeepEnv: true) { error in
            
        }
        
//        DYMLuaScriptManager.downloadLuaScriptZip(url: URL(string: "https://github.com/quantopian/zipline/archive/refs/heads/master.zip")!) { result, error in
//            print("\(result)")
//        }
    }
    
    @objc func gotoWebGuide() {
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

        
        DYMobileSDK.showVisualGuide(products: [defaultProuct1,defaultProuct2], rootDelegate: UIApplication.shared.delegate as! DYMWindowManaging,extras: extra) { receipt, purchaseResult, error in
            
        }
    }
    
    
    
    @objc func setCustomerProperties() {
        let properties: [String: Any] = [
            "customProperties": [
                [
                    "key": "test0",
                    "value": "123131313"
                ],
                [
                    "key": "test1",
                    "value": "123131313"
                ],
                [
                    "key": "test2",
                    "value": "123131313"
                ],
                [
                    "key": "test3",
                    "value": "00000"
                ],
                [
                    "key": "88888",
                    "value": "99999"
                ]
            ]
        ]
        DYMobileSDK.setCustomPropertiesWith(properties as NSDictionary) { result, error in
            if (error != nil) {
                print("❌setCustomProperties:\(error?.localizedDescription)")
                self.showAlert(title:"失败", message: "❌setCustomProperties:\(error?.localizedDescription)")
            }else {
                print("✅setCustomProperties:\(result?.status)\n uuid: \(FCUUID.uuidForDevice())")
                self.showAlert(title:"成功", message: "✅setCustomProperties:\(result?.status)\n uuid: \(FCUUID.uuidForDevice())")

            }
        }
    }
    @objc func getSegmentInfo() {
        DYMobileSDK.getSegmentInfo { result, error in
            if (error != nil) {
                self.showAlert(title:"失败", message: "❌getSegmentInfo:\(error?.localizedDescription)")
            }else {
                let segmentListString:String =  result?.segmentList.joined(separator: ",") ?? "[]"
                self.showAlert(title: "成功", message: "✅Segments: \(segmentListString)")
                print("\( result?.segmentList)")
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
// MARK: Custom method
extension ViewController {
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
        // 获取当前 window 的顶层 ViewController
         if let topController = UIApplication.shared.windows.first?.rootViewController {
             var currentController = topController
             while let presentedController = currentController.presentedViewController {
                 currentController = presentedController
             }
             // 在最上层的控制器上展示弹窗
             currentController.present(alertController, animated: true, completion: nil)
         }
    }
}
// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return buttonTitles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath) as? ButtonCell else {
            return UITableViewCell()
        }
        
        cell.button.setTitle(buttonTitles[indexPath.row], for: .normal)
        cell.button.addTarget(self, action: buttonActions[indexPath.row], for: .touchUpInside)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70 // Set the desired height for the cells
    }
}

// MARK: - Custom Button Cell
class ButtonCell: UITableViewCell {
    let button: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitleColor(.black, for: .normal)
        btn.layer.borderColor = UIColor.black.cgColor
        btn.layer.borderWidth = 1.0
        btn.layer.cornerRadius = 5.0
        return btn
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton() {
        contentView.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            button.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
}
