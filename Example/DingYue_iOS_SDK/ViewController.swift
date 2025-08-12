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
           private let buttonTitles = ["SubscriptionBtn", "ConsumptionBtn", "LuaScriptBtn", "guidePageBtn", "CustomerProperties","GetSegmentInfo","GetAppleSearchAdsInfo", "PaywallConfig"]
    private let buttonActions: [Selector] = [
        #selector(goPurchaseSubscriptionAction),
        #selector(goPurchaseConsumptionAction),
        #selector(luaTestAction),
        #selector(gotoWebGuide),
        #selector(setCustomerProperties),
        #selector(getSegmentInfo),
        #selector(getAppleSearchAdsInfo),
        #selector(showPaywallConfigAction)
    ]
       
       override func viewDidLoad() {
           super.viewDidLoad()
           setupTableView()
//           DYMConfiguration.shared.paywallConfig.presentationStyle = .circleSpread
//           DYMConfiguration.shared.paywallConfig.enableSwipeToDismiss = true
//           DYMConfiguration.shared.paywallConfig.enableSwipeToDismissFromEdge = true
       }
       
       private func setupTableView() {
           tableView.delegate = self
           tableView.dataSource = self
           tableView.register(ButtonCell.self, forCellReuseIdentifier: "ButtonCell")
           tableView.translatesAutoresizingMaskIntoConstraints = false
           tableView.backgroundColor = .white
           view.addSubview(tableView)
           NSLayoutConstraint.activate([
               tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
               tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
               tableView.topAnchor.constraint(equalTo: view.topAnchor),
               tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
           ])
           
           self.view.backgroundColor = .white
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
        
        DYMobileSDK.showVisualPaywall(products: [defaultProuct1,defaultProuct2], rootController: self, extras: extra) { receipt, purchasedResult,purchasedProduct, error in
            if error == nil {
               //购买成功
                print("返回结果：")
                print(" 订阅购买的产品：\(String(describing: purchasedProduct))\n 订阅返回结果:\(String(describing: purchasedResult))")
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
        DYMobileSDK.purchaseConsumption(productId: testConsumptionProductIf, count: 2) { receipt, purchaseResult,purchasedProduct ,error in
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

        
        DYMobileSDK.showVisualGuide(products: [defaultProuct1,defaultProuct2], rootDelegate: UIApplication.shared.delegate as! DYMWindowManaging,extras: extra) { receipt, purchaseResult,purchasedProduct ,error in
            
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
                print("❌setCustomProperties:\(String(describing: error?.localizedDescription))")
                self.showAlert(title:"失败", message: "❌setCustomProperties:\(String(describing: error?.localizedDescription))")
            }else {
                print("✅setCustomProperties:\(String(describing: result?.status))\n uuid: \(String(describing: FCUUID.uuidForDevice()))")
                self.showAlert(title:"成功", message: "✅setCustomProperties:\(String(describing: result?.status))\n uuid: \(String(describing: FCUUID.uuidForDevice()))")

            }
        }
    }
    @objc func getSegmentInfo() {
        DYMobileSDK.getSegmentInfo { result, error in
            if (error != nil) {
                self.showAlert(title:"失败", message: "❌getSegmentInfo:\(String(describing: error?.localizedDescription))")
            }else {
                let segmentListString:String =  result?.segmentList.joined(separator: ",") ?? "[]"
                self.showAlert(title: "成功", message: "✅Segments: \(segmentListString)")
                print("\( String(describing: result?.segmentList))")
            }
        }
    }
    
    @objc func getAppleSearchAdsInfo() {
        

        
        DYMobileSDK.retrieveAppleSearchAdsAttribution(mode: .returnCache) { attribution, error  in
            if (error != nil) {
                self.showAlert(title:"失败", message: "❌getAppleSearchAdsInfo:\(String(describing: error?.localizedDescription))")
            }else {
                let attributionString = self.dictionaryToArrayString(dictionary: attribution ?? [:])
                
                self.showAlert(title: "成功", message: "✅Ads:\n\(attributionString)")
                print("\(attributionString)")
            }
        }
        
    }
    
    @objc func showPaywallConfigAction() {
        let alertController = UIAlertController(title: "支付页面配置", message: "选择展示样式和手势设置", preferredStyle: .actionSheet)
        
        // 展示样式选择
        let styles = [
            ("底部弹出", DYMPaywallConfig.PresentationStyle.bottomSheet),
            ("全屏底部弹出", DYMPaywallConfig.PresentationStyle.bottomSheetFullScreen),
            ("Push样式", DYMPaywallConfig.PresentationStyle.push),
            ("模态居中", DYMPaywallConfig.PresentationStyle.modal),
            ("圆形扩散", DYMPaywallConfig.PresentationStyle.circleSpread)
        ]
        
        for (title, style) in styles {
            alertController.addAction(UIAlertAction(title: title, style: .default) { _ in
                DYMConfiguration.shared.paywallConfig.presentationStyle = style
                self.goPurchaseSubscriptionAction()
            })
        }
        
        // 手势设置
        alertController.addAction(UIAlertAction(title: "下滑手势: \(DYMConfiguration.shared.paywallConfig.enableSwipeToDismiss ? "开启" : "关闭")", style: .default) { _ in
            DYMConfiguration.shared.paywallConfig.enableSwipeToDismiss.toggle()
            self.showPaywallConfigAction()
        })
        
        alertController.addAction(UIAlertAction(title: "边缘滑动手势: \(DYMConfiguration.shared.paywallConfig.enableSwipeToDismissFromEdge ? "开启" : "关闭")", style: .default) { _ in
            DYMConfiguration.shared.paywallConfig.enableSwipeToDismissFromEdge.toggle()
            self.showPaywallConfigAction()
        })
        
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // 适配 iPad
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alertController, animated: true)
    }
    func dictionaryToArrayString(dictionary: [String: Any]) -> String {
        let array = dictionary.map { "\($0.key): \($0.value)" }
        return array.joined(separator: ",\n ")
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
        DispatchQueue.main.async {
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
        contentView.backgroundColor = .white
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
