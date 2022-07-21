//
//  DYMPayWallController.swift
//  DingYueMobileSDK
//
//  Created by 靖核 on 2022/4/3.
//

import UIKit
import WebKit
import StoreKit

@objc public protocol DYMPayWallActionDelegate: NSObjectProtocol {
    @objc optional func clickTermsAction(baseViewController:UIViewController)//使用协议
    @objc optional func clickPrivacyAction(baseViewController:UIViewController)//隐私政策
}

public class DYMPayWallController: UIViewController {
    var custemedProducts:[Subscription] = []
    var paywalls:[SKProduct] = []
    var completion:DYMPurchaseCompletion?
    weak var delegate: DYMPayWallActionDelegate?
    
    private lazy var webView: WKWebView = {
        let preference = WKPreferences()
        let config = WKWebViewConfiguration()
        config.preferences = preference
        config.userContentController = WKUserContentController()
        config.userContentController.add(self, name: "vip_close")
        config.userContentController.add(self, name: "vip_restore")
        config.userContentController.add(self, name: "vip_terms")
        config.userContentController.add(self, name: "vip_privacy")
        config.userContentController.add(self, name: "vip_purchase")
        config.userContentController.add(self, name: "vip_choose")
        let webView = WKWebView(frame: UIScreen.main.bounds, configuration: config)
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.navigationDelegate = self
        webView.scrollView.bounces = false
        if #available(iOS 11.0, *) { webView.scrollView.contentInsetAdjustmentBehavior = .never }
        return webView
    }()
    
    private lazy var eventManager: DYMEventManager = {
        return DYMEventManager.shared
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.addSubview(webView)
        loadWebView()
    }
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        eventManager.track(event: .ENTER_PURCHASE, user: UserProperties.requestUUID)
    }
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        eventManager.track(event: .EXIT_PURCHASE, user: UserProperties.requestUUID)
    }
    
    private func loadWebView() {
        if DYMDefaultsManager.shared.cachedPaywallPageIdentifier != nil {
            let basePath = UserProperties.pallwallPath ?? ""
            let fullPath = basePath + "/index.html"
            let url = URL(fileURLWithPath: fullPath)
            webView.loadFileURL(url, allowingReadAccessTo: URL(fileURLWithPath: basePath))
        } else {
            let sdkBundle = Bundle(for: DYMobileSDK.self)
            guard let resourceBundleURL = sdkBundle.url(forResource: "DingYue_iOS_SDK", withExtension: "bundle")else { fatalError("DingYue_iOS_SDK.bundle not found, do not display SDK default paywall!") }
            guard let resourceBundle = Bundle(url: resourceBundleURL)else { fatalError("Cannot access DingYue_iOS_SDK.bundle,do not display SDK default paywall!") }
            let path = resourceBundle.path(forResource: "index", ofType: "html")
            let htmlUrl = URL(fileURLWithPath: path!)
            webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl)
        }
    }
    ///刷新页面
    public func refreshView() {
        webView.reload()
    }
}

extension DYMPayWallController: WKNavigationDelegate, WKScriptMessageHandler {
    
    private func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.targetFrame == nil {
            webView .load(navigationAction.request)
        }
        decisionHandler(WKNavigationActionPolicy.allow)
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //系统语言
        let languageCode = NSLocale.preferredLanguages[0]
        //内购项信息
        var cachedProducts:[Subscription] = self.custemedProducts
        if let products = DYMDefaultsManager.shared.cachedProducts {
            if !products.isEmpty {
                cachedProducts = products
            }
        }

        var productsArray = [Dictionary<String,Any>]()
        for item in cachedProducts {
            let array:Dictionary<String, Any> = [
                "type":item.type,
                "name":item.name,
                "platformProductId":item.platformProductId,
                "period":item.period ?? "",
                "currency":item.currencyCode,
                "price": item.price.description.stringValue,
                "description":item.subscriptionDescription ?? ""
            ]
            productsArray.append(array)
        }
        //传给内购页的数据字典
        let dic = [
            "system_language":languageCode,
            "products":productsArray,
        ] as [String : Any]

        let jsonString = getJSONStringFromDictionary(dictionary: dic as NSDictionary)
        let data = jsonString.data(using: .utf8)
        let base64Str:String? = data?.base64EncodedString() as? String
        webView.evaluateJavaScript("iostojs('\(base64Str!)')") { (response, error) in
        }
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let user = UserProperties.requestUUID
        if message.name == "vip_close" {
            eventManager.track(event: .CLOSE_BUTTON, user: user)

            self.dismiss(animated: true, completion: nil)
        }else if message.name == "vip_restore" {
            eventManager.track(event: .PURCHASE_RESTORE, user: user)

            ProgressView.show(rootViewConroller: self)
            DYMobileSDK.restorePurchase { receipt, purchaseResult, error in
                ProgressView.stop()
                self.completion?(receipt,purchaseResult,error)
                if error == nil {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        } else if message.name == "vip_terms" {
            eventManager.track(event: .ABOUT_TERMSOFSERVICE, user: user)
            if ((self.delegate?.clickTermsAction?(baseViewController: self)) != nil) {
                self.delegate?.clickTermsAction!(baseViewController: self)
            }
        }else if message.name == "vip_privacy" {
            eventManager.track(event: .ABOUT_PRIVACYPOLICY, user: user)
            if ((self.delegate?.clickPrivacyAction?(baseViewController: self)) != nil) {
                self.delegate?.clickPrivacyAction!(baseViewController: self)
            }
        }else if message.name == "vip_purchase" {
            eventManager.track(event: .PURCHASE_START, user: user)

            let dic = message.body as? Dictionary<String,Any>
            if let productId = dic?["productId"] as? String {
                self.buyWithProductId(productId)
            }else {
                self.completion?(nil,nil,.noProductIds)
            }
        }
    }

    func buyWithProductId(_ productId:String) {
        ProgressView.show(rootViewConroller: self)
        DYMobileSDK.purchase(productId: productId) { receipt, purchaseResult, error in
            ProgressView.stop()
            self.completion?(receipt,purchaseResult,error)
            if error == nil {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    // 字典转JSONString
    func getJSONStringFromDictionary(dictionary:NSDictionary) -> String {
        if (!JSONSerialization.isValidJSONObject(dictionary)) {
            return ""
        }
        let data : NSData! = try! JSONSerialization.data(withJSONObject: dictionary, options: []) as NSData?
        let JSONString = NSString(data:data as Data,encoding: String.Encoding.utf8.rawValue)
        return JSONString! as String
    }
}
