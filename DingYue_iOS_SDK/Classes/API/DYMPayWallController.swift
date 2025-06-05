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
    @objc optional func payWallDidAppear(baseViewController:UIViewController)//内购页显示
    @objc optional func payWallDidDisappear(baseViewController:UIViewController)//内购页消失
    @objc optional func clickTermsAction(baseViewController:UIViewController)//使用协议
    @objc optional func clickPrivacyAction(baseViewController:UIViewController)//隐私政策
    @objc optional func clickCloseButton(baseViewController:UIViewController)//关闭按钮事件
    @objc optional func clickPurchaseButton(baseViewController:UIViewController)//购买
    @objc optional func clickRestoreButton(baseViewController:UIViewController)//恢复
}

public class DYMPayWallController: UIViewController {
    var custemedProducts:[Subscription] = []
    var tempCachedProducts:[Dictionary<String,Any>] = []
    var paywalls:[SKProduct] = []
    var completion:DYMPurchaseCompletion?
    weak var delegate: DYMPayWallActionDelegate?
    var loadingTimer:Timer?
    var currentPaywallId:String?
    var extras:[String:Any]?

    
    lazy var activity:UIActivityIndicatorView = {
        let activity = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activity.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        activity.center = self.view.center
        activity.backgroundColor = .white
        activity.color = .gray
        activity.startAnimating()
        return activity
    }()
    private let scriptMessageHandlerNames = [
        "vip_close",
        "vip_restore",
        "vip_terms",
        "vip_privacy",
        "vip_purchase",
        "vip_choose"
    ]
    private lazy var webCustomConfiguration: WKWebViewConfiguration = {
        let preference = WKPreferences()
        let config = WKWebViewConfiguration()
        config.preferences = preference
        config.userContentController = WKUserContentController()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        return config
    }()
    private lazy var webView: WKWebView = {
        let webView = WKWebView(frame: UIScreen.main.bounds, configuration: self.webCustomConfiguration)
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
        self.view.backgroundColor = .white
        view.addSubview(webView)
        view.addSubview(activity)

        if DYMDefaultsManager.shared.isLoadingStatus == true {
            activity.isHidden = true
            loadWebView()
        } else {
            activity.isHidden = false
            loadingTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(changeLoadingStatus), userInfo: nil, repeats: true)
        }
    }

    @objc func changeLoadingStatus() {
        if DYMDefaultsManager.shared.isLoadingStatus == true {
            activity.isHidden = true
            loadWebView()
            stopLoadingTimer()
        }
    }

    func stopLoadingTimer() {
        if loadingTimer != nil {
            loadingTimer?.invalidate()
            loadingTimer = nil
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.registerScriptMessageHandlers()
    }
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.currentPaywallId = DYMDefaultsManager.shared.cachedPaywallPageIdentifier
        self.trackWithPayWallInfo(eventName: "ENTER_PAYWALL")
        self.delegate?.payWallDidAppear?(baseViewController: self)
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.trackWithPayWallInfo(eventName: "EXIT_PAYWALL")
        stopLoadingTimer()
        removeScriptMessageHandlers()
        self.delegate?.payWallDidDisappear?(baseViewController: self)
    }
    
    public func loadWebView() {

       
        if DYMDefaultsManager.shared.isUseNativePaywall {
            if let nativePaywallFullPath = DYMDefaultsManager.shared.nativePaywallPath, let basePath = DYMDefaultsManager.shared.nativePaywallBasePath {
                let url = URL(fileURLWithPath: nativePaywallFullPath)
                webView.loadFileURL(url, allowingReadAccessTo: URL(fileURLWithPath: basePath))
            } else {
                let sdkBundle = Bundle(for: DYMobileSDK.self)
                guard let resourceBundleURL = sdkBundle.url(forResource: "DingYue_iOS_SDK", withExtension: "bundle")else { fatalError("DingYue_iOS_SDK.bundle not found, do not display SDK default paywall!") }
                guard let resourceBundle = Bundle(url: resourceBundleURL)else { fatalError("Cannot access DingYue_iOS_SDK.bundle,do not display SDK default paywall!") }
                let path = resourceBundle.path(forResource: "index", ofType: "html")
                let htmlUrl = URL(fileURLWithPath: path!)
                webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl)
            }
        } else {
            if DYMDefaultsManager.shared.cachedPaywalls != nil && DYMDefaultsManager.shared.cachedPaywallPageIdentifier != nil {
                let basePath = UserProperties.pallwallPath ?? ""
                let fullPath = basePath + "/index.html"
                let url = URL(fileURLWithPath: fullPath)
                webView.loadFileURL(url, allowingReadAccessTo: URL(fileURLWithPath: basePath))
            } else {
                
                if let defaultPaywallPath = DYMDefaultsManager.shared.defaultPaywallPath {
                    let url = URL(fileURLWithPath: defaultPaywallPath)
                    webView.loadFileURL(url, allowingReadAccessTo: url)
                } else {
                    let sdkBundle = Bundle(for: DYMobileSDK.self)
                    guard let resourceBundleURL = sdkBundle.url(forResource: "DingYue_iOS_SDK", withExtension: "bundle")else { fatalError("DingYue_iOS_SDK.bundle not found, do not display SDK default paywall!") }
                    guard let resourceBundle = Bundle(url: resourceBundleURL)else { fatalError("Cannot access DingYue_iOS_SDK.bundle,do not display SDK default paywall!") }
                    let path = resourceBundle.path(forResource: "index", ofType: "html")
                    let htmlUrl = URL(fileURLWithPath: path!)
                    webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl)
                }
            }
        }
    }
    ///刷新页面
    public func refreshView() {
        webView.reload()
    }
    private func registerScriptMessageHandlers() {
        removeScriptMessageHandlers() //先移除旧的脚本消息处理器
        for name in scriptMessageHandlerNames {
            self.webCustomConfiguration.userContentController.add(self, name: name)
        }
    }

    private func removeScriptMessageHandlers() {
        for name in scriptMessageHandlerNames {
            self.webCustomConfiguration.userContentController.removeScriptMessageHandler(forName: name)
        }
    }
    deinit {
        DYMLogManager.debugLog("DYMPayWallController deinit")
    }
}

extension DYMPayWallController: WKNavigationDelegate, WKScriptMessageHandler {
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        //跳转到应用
        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url{
            UIApplication.shared.open(url)
            decisionHandler(WKNavigationActionPolicy.cancel)
        } else {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            decisionHandler(WKNavigationActionPolicy.allow)
        }
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let videoPlayJS = """
              var videos = document.querySelectorAll('video');
              videos.forEach(function(video) {
                  video.play();
              });
              """
        webView.evaluateJavaScript(videoPlayJS) { (result, error) in
            if let error = error {
                print("Error executing JavaScript: \(error)")
            } else {
                print("All videos should now play.")
            }
        }
        //系统语言
        let languageCode = NSLocale.preferredLanguages[0]
        //内购项信息
        var cachedProducts:[Subscription] = self.custemedProducts
        if let products = DYMDefaultsManager.shared.cachedProducts, !products.isEmpty{
            cachedProducts = products
        }
        
        var productsArray = [Dictionary<String,Any>]()
        for item in cachedProducts {
            var array:Dictionary<String, Any> = [
                "type":item.type,
                "name":item.name,
                "platformProductId":item.platformProductId,
                "period":item.period ?? "",
                "currency":item.currencyCode,
                "price": item.price.description.stringValue,
                "description":item.subscriptionDescription ?? ""
            ]
            if let groupId = item.appleSubscriptionGroupId {
                array["appleSubscriptionGroupId"] = groupId
            }
            productsArray.append(array)
        }
        self.tempCachedProducts = productsArray
        //传给内购页的数据字典
        var dic = [
            "system_language":languageCode,
            "products":productsArray
        ] as [String : Any]
        
        if let extra = extras {
            dic["extra"] = extra
        }
        
        let jsonString = getJSONStringFromDictionary(dictionary: dic as NSDictionary)
        let data = jsonString.data(using: .utf8)
        let base64Str:String? = data?.base64EncodedString() as? String
        webView.evaluateJavaScript("iostojs('\(base64Str!)')") { (response, error) in
        }
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "vip_close" {
            self.trackWithPayWallInfo(eventName: "EXIT_PURCHASE")

            self.dismiss(animated: true, completion: nil)

            self.delegate?.clickCloseButton?(baseViewController: self)
        }else if message.name == "vip_restore" {

            ProgressView.show(rootViewConroller: self)
            DYMobileSDK.restorePurchase {[weak self] receipt, purchaseResult,purchasedProduct ,error in
                ProgressView.stop()
                guard let self = self else { return }
                self.completion?(receipt,purchaseResult,purchasedProduct,error)
                if error == nil {
                    self.trackWithPayWallInfo(eventName: "RESTORE_PURCHASE_SUCCESS")
                    self.dismiss(animated: true, completion: nil)
                } else {
                    self.trackWithPayWallInfo(eventName: "RESTORE_PURCHASE_FAIL")
                }
            }
            
            self.delegate?.clickRestoreButton?(baseViewController: self)
        } else if message.name == "vip_terms" {
            eventManager.track(event: "ABOUT_TERMSOFSERVICE")
            if let delegate = self.delegate, delegate.responds(to: #selector(delegate.clickTermsAction(baseViewController:))) {
                   delegate.clickTermsAction?(baseViewController: self)
               }
        }else if message.name == "vip_privacy" {
            eventManager.track(event: "ABOUT_PRIVACYPOLICY")
            if let delegate = self.delegate, delegate.responds(to: #selector(delegate.clickPrivacyAction(baseViewController:))) {
                  delegate.clickPrivacyAction?(baseViewController: self)
              }
            
        }else if message.name == "vip_purchase" {

            let dic = message.body as? Dictionary<String,Any>
            if let productId = dic?["productId"] as? String {
                var productPrice:String?
                if self.tempCachedProducts.count > 0 {
                    for dic in self.tempCachedProducts {
                        if productId == dic["platformProductId"] as? String {
                            productPrice = dic["price"] as? String
                        }
                    }
                }
                self.buyWithProductId(productId, productPrice: productPrice)
            } else {
                self.completion?(nil,nil,nil,.noProductIds)
                self.eventManager.track(event: "PURCHASE_FAIL_DETAIL", extra: "no productId from h5")
            }
            
            self.delegate?.clickPurchaseButton?(baseViewController: self)
        }
    }

    func buyWithProductId(_ productId:String, productPrice:String? = nil) {
        ProgressView.show(rootViewConroller: self)
        UserProperties.userSubscriptionPurchasedSourcesType = .DYPaywall//以更新用户购买来源属性
        DYMobileSDK.purchase(productId: productId, productPrice: productPrice) { [weak self] receipt, purchaseResult,purchasedProduct, error in
            ProgressView.stop()
            guard let self = self else { return }
            self.completion?(receipt,purchaseResult,purchasedProduct,error)
            if error == nil {
                self.trackWithPayWallInfo(eventName: "PURCHASE_SUCCESS")

                self.dismiss(animated: true, completion: nil)
            } else {
                self.trackWithPayWallInfo(eventName: "PURCHASE_FAIL")
                self.eventManager.track(event: "PURCHASE_FAIL_DETAIL", extra: error?.debugDescription)
            }
        }
    }

    func trackWithPayWallInfo(eventName:String) {
        if let paywallId = self.currentPaywallId {
            let middleIndex = paywallId.firstIndex(of: "/")
            let id = String(paywallId[..<middleIndex!])
            let version = String(paywallId[paywallId.index(after: middleIndex!)...])

            self.eventManager.track(event: eventName, extra: version, user: id)
        } else {
            self.eventManager.track(event: eventName)
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
 
