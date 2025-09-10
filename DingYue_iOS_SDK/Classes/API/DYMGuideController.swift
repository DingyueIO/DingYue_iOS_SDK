//
//  DYMGuideController.swift
//  DingYue_iOS_SDK
//
//  Created by 王勇 on 2024/9/2.
//

import UIKit
import WebKit
import StoreKit
import NVActivityIndicatorView
@objc public protocol DYMGuideActionDelegate: NSObjectProtocol {
    @objc optional func guideDidAppear(baseViewController:UIViewController)//引导页显示
    @objc optional func guideDidDisappear(baseViewController:UIViewController)//引导页消失
    @objc optional func clickGuideTermsAction(baseViewController:UIViewController)//使用协议
    @objc optional func clickGuidePrivacyAction(baseViewController:UIViewController)//隐私政策
    @objc optional func clickGuideCloseButton(baseViewController:UIViewController,closeType:String)//关闭按钮事件
    @objc optional func clickGuidePurchaseButton(baseViewController:UIViewController)//购买
    @objc optional func clickGuideRestoreButton(baseViewController:UIViewController)//恢复
    
    /// 引导页点击继续按钮
    /// - Parameters:
    ///   - baseViewController: 当前引导页
    ///   - currentIndex: 当前页 index
    ///   - nextIndex: 下一页 index
    ///   - swiperSize: 总页数
    @objc optional func clickGudieContinueButton(baseViewController:UIViewController ,currentIndex:Int,nextIndex:Int ,swiperSize:Int)
}
 
@objc public protocol DYMWindowManaging: NSObjectProtocol {
    var window: UIWindow? { get set }
}


public class DYMGuideController: UIViewController {
    var custemedProducts:[Subscription] = []
    var tempCachedProducts:[Dictionary<String,Any>] = []
    var paywalls:[SKProduct] = []
    var completion:DYMPurchaseCompletion?
    public weak var delegate: DYMGuideActionDelegate?
    var loadingTimer:Timer?
    var currentGuidePageId:String?
    var extras:[String:Any]?
    var guidePageSwiperSize:Int?

    
    lazy var customIndicatiorV:NVActivityIndicatorView =  {
       let view = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 64, height: 34))
        view.type =  GuidePageConfig.type(from: DYMConfiguration.shared.guidePageConfig.indicatorType)
        view.color = DYMConfiguration.shared.guidePageConfig.indicatorColor
        view.startAnimating()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
 
    private let scriptMessageHandlerNames = [
        "guide_close",
        "guide_restore",
        "guide_terms",
        "guide_privacy",
        "guide_purchase",
        "guide_continue"
    ]    
    private lazy var webCustomConfiguration: WKWebViewConfiguration = {
        let preference = WKPreferences()
        let config = WKWebViewConfiguration()
        config.preferences = preference
        config.userContentController = WKUserContentController()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
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

    
    //     懒加载 LaunchScreen view
    lazy var launchScreenView: UIView? = {
        guard let launchView = self.loadLaunchScreen() else {
                  return nil
        }
        // 设置 launchScreenView 的 frame 以适应整个屏幕
        launchView.frame = self.view.bounds
        return launchView
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .white
        view.addSubview(webView)
        // 使用 launchScreenView
        if let launchView = launchScreenView {
            self.view.addSubview(launchView)
        }
        view.addSubview(customIndicatiorV)
        NSLayoutConstraint.activate([
            customIndicatiorV.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            customIndicatiorV.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -DYMConfiguration.shared.guidePageConfig.bottomSpacing)
        ])
      
        if DYMDefaultsManager.shared.guideLoadingStatus == true {
            customIndicatiorV.isHidden = true
            loadWebView()
        } else {
            if DYMConfiguration.shared.guidePageConfig.isVisible {
                customIndicatiorV.isHidden = false
            }
            loadingTimer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(changeLoadingStatus), userInfo: nil, repeats: true)
        }
        
    }

    @objc func changeLoadingStatus() {
        if DYMDefaultsManager.shared.guideLoadingStatus == true {
            customIndicatiorV.isHidden = true
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
        self.currentGuidePageId = DYMDefaultsManager.shared.cachedGuidePageIdentifier
        self.trackWithPayWallInfo(eventName: "ENTER_GUIDE")
        self.delegate?.guideDidAppear?(baseViewController: self)
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.trackWithPayWallInfo(eventName: "EXIT_GUIDE")
        stopLoadingTimer()
        removeScriptMessageHandlers()
        self.delegate?.guideDidDisappear?(baseViewController: self)
    }
    
    public func loadWebView() {

        if DYMDefaultsManager.shared.isUseNativeGuide {
            if let nativeGuideFullPath = DYMDefaultsManager.shared.nativeGuidePath, let basePath = DYMDefaultsManager.shared.nativeGuideBasePath {
                let url = URL(fileURLWithPath: nativeGuideFullPath)
                webView.loadFileURL(url, allowingReadAccessTo: URL(fileURLWithPath: basePath))
            } else {
                /*
                let sdkBundle = Bundle(for: DYMobileSDK.self)
                guard let resourceBundleURL = sdkBundle.url(forResource: "Guide", withExtension: "bundle")else { fatalError("Guide.bundle not found, do not display SDK default GuidePage!") }
                guard let resourceBundle = Bundle(url: resourceBundleURL)else { fatalError("Cannot access Guide.bundle,do not display SDK default GuidePage!") }
                let path = resourceBundle.path(forResource: "index", ofType: "html")
                let htmlUrl = URL(fileURLWithPath: path!)
                webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl)
                */
                self.trackWithPayWallInfo(eventName: "NO_LOCAL_WEB_GUIDE_CLOSE")
                self.delegate?.clickGuideCloseButton?(baseViewController: self,closeType: "NO_LOCAL_WEB_GUIDE_CLOSE")
            }
        } else {
            if DYMDefaultsManager.shared.cachedGuides != nil && DYMDefaultsManager.shared.cachedGuidePageIdentifier != nil {
                let basePath = UserProperties.guidePath ?? ""
                let fullPath = basePath + "/index.html"
                let url = URL(fileURLWithPath: fullPath)
                webView.loadFileURL(url, allowingReadAccessTo: URL(fileURLWithPath: basePath))
            } else {
                if let defaultGuidePath = DYMDefaultsManager.shared.defaultGuidePath {
                    let url = URL(fileURLWithPath: defaultGuidePath)
                    webView.loadFileURL(url, allowingReadAccessTo: url)
                } else {
                    /*
                    let sdkBundle = Bundle(for: DYMobileSDK.self)
                    guard let resourceBundleURL = sdkBundle.url(forResource: "Guide", withExtension: "bundle")else { fatalError("Guide.bundle not found, do not display SDK default GuidePage!") }
                    guard let resourceBundle = Bundle(url: resourceBundleURL)else { fatalError("Cannot access Guide.bundle,do not display SDK default GuidePage!") }
                    let path = resourceBundle.path(forResource: "index", ofType: "html")
                    let htmlUrl = URL(fileURLWithPath: path!)
                    webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl)
                    */
                    self.trackWithPayWallInfo(eventName: "NO_LOCAL_WEB_GUIDE_CLOSE")
                    self.delegate?.clickGuideCloseButton?(baseViewController: self,closeType: "NO_LOCAL_WEB_GUIDE_CLOSE")
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
        DYMLogManager.debugLog("DYMGuideController deinit")
    }
}
extension DYMGuideController: WKNavigationDelegate, WKScriptMessageHandler {
    
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
        //是否显示套路引导页
        var purchaseSwitch:Bool = false
        if let guides:[DYMGuideObject] = DYMDefaultsManager.shared.cachedGuides,guides.count > 0 {
            let guideModel:DYMGuideObject = guides.first!
            purchaseSwitch = guideModel.purchaseSwitch
            self.guidePageSwiperSize = guideModel.swiperSize
            let subscriptions = guideModel.subscriptions
            if subscriptions.count > 0 {
                var tempProudcts:[Subscription] = []
                for item in subscriptions {
                    tempProudcts.append(item.subscription!)
                }
                cachedProducts = tempProudcts
            }
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
            "products":productsArray,
            "purchaseSwitch":purchaseSwitch
        ] as [String : Any]
        
        if let extra = extras {
            dic["extra"] = extra
        }
        dic["isVIP"] = DYMConfiguration.shared.guidePageConfig.isVIP
        let jsonString = getJSONStringFromDictionary(dictionary: dic as NSDictionary)
        
        let data = jsonString.data(using: .utf8)
        let base64Str:String? = data?.base64EncodedString() as? String
        webView.evaluateJavaScript("iostojs('\(base64Str!)')") { (response, error) in
        }
        
        DispatchQueue.main.async {
            if let launchView = self.launchScreenView {
                self.fadeView(launchView, hide: true)
            }
        }
    }
    
    func fadeView(_ view: UIView, hide: Bool, duration: TimeInterval = 0.6) {
        if hide {
            // 进行淡出动画
            UIView.animate(withDuration: duration, animations: {
                view.alpha = 0
            }) { _ in
                view.isHidden = true  // 动画完成后将视图隐藏
            }
        } else {
            // 取消隐藏并进行淡入动画
            view.isHidden = false
            view.alpha = 0
            UIView.animate(withDuration: duration, animations: {
                view.alpha = 1
            })
        }
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "guide_close" {
            self.trackWithPayWallInfo(eventName: "GUIDE_CLOSE")
            var type = ""
            if let useInfo = message.body as? [String:Any] {
                type = useInfo["type"] as! String
            }
            self.dismiss(animated: true) {
                self.delegate?.clickGuideCloseButton?(baseViewController: self,closeType: type)
            }
        }else if message.name == "guide_restore" {

            ProgressView.show(rootViewConroller: self)
            DYMobileSDK.restorePurchase { receipt, purchaseResult, purchasedProduct,error in
                ProgressView.stop()
                self.completion?(receipt,purchaseResult,purchasedProduct,error)
                if error == nil {
                    self.trackWithPayWallInfo(eventName: "GUIDE_RESTORE_PURCHASE_SUCCESS")
                    self.dismiss(animated: true, completion: nil)
                } else {
                    self.trackWithPayWallInfo(eventName: "GUIDE_RESTORE_PURCHASE_FAIL")
                }
            }
            self.delegate?.clickGuideRestoreButton?(baseViewController: self)
        } else if message.name == "guide_terms" {
            eventManager.track(event: "GUIDE_ABOUT_TERMSOFSERVICE")
            if let delegate = self.delegate, delegate.responds(to: #selector(delegate.clickGuideTermsAction(baseViewController:))) {
                   delegate.clickGuideTermsAction?(baseViewController: self)
               }
        }else if message.name == "guide_privacy" {
            eventManager.track(event: "GUIDE_ABOUT_PRIVACYPOLICY")
            if let delegate = self.delegate, delegate.responds(to: #selector(delegate.clickGuidePrivacyAction(baseViewController:))) {
                  delegate.clickGuidePrivacyAction?(baseViewController: self)
              }
            
        }else if message.name == "guide_purchase" {

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
                self.eventManager.track(event: "GUIDE_PURCHASE_FAIL_DETAIL", extra: "no productId from guide h5")
            }
            
            self.delegate?.clickGuidePurchaseButton?(baseViewController: self)
        }else if message.name == "guide_continue" {
            
            var currentIndex:Int = 0
            var nextIndex:Int = 0
            if let useInfo = message.body as? [String:Any] {
                if let currentIndexValue = useInfo["currentIndex"] as? Int {
                      currentIndex = currentIndexValue
                  }
                  if let nextIndexValue = useInfo["nextIndex"] as? Int {
                      nextIndex = nextIndexValue
                  }
            }
            
            if let delegate = self.delegate, delegate.responds(to: #selector(delegate.clickGudieContinueButton(baseViewController:currentIndex:nextIndex:swiperSize:))) {
                delegate.clickGudieContinueButton?(baseViewController: self, currentIndex: currentIndex, nextIndex: nextIndex, swiperSize: self.guidePageSwiperSize ?? 0)
              }
            
        }
    }

    func buyWithProductId(_ productId:String, productPrice:String? = nil) {
        ProgressView.show(rootViewConroller: self)
        UserProperties.userSubscriptionPurchasedSourcesType = .DYPaywall//以更新用户购买来源属性
        DYMobileSDK.purchase(productId: productId, productPrice: productPrice) { receipt, purchaseResult,purchasedProduct, error in
            ProgressView.stop()
            self.completion?(receipt,purchaseResult,purchasedProduct,error)
            if error == nil {
                self.trackWithPayWallInfo(eventName: "GUIDE_PURCHASE_SUCCESS")

                self.dismiss(animated: true, completion: nil)
            } else {
                self.trackWithPayWallInfo(eventName: "GUIDE_PURCHASE_FAIL")
                self.eventManager.track(event: "GUIDE_PURCHASE_FAIL_DETAIL", extra: error?.debugDescription)
            }
        }
    }

    func trackWithPayWallInfo(eventName:String) {
        if let guidePageId = self.currentGuidePageId {
            let middleIndex = guidePageId.firstIndex(of: "/")
            let id = String(guidePageId[..<middleIndex!])
            let version = String(guidePageId[guidePageId.index(after: middleIndex!)...])

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
//MARK: Private Method
extension DYMGuideController {
    func loadLaunchScreen() -> UIView? {
        let nibName = "LaunchScreen"
        // 检查 .storyboard 文件
        if let storyboardPath = Bundle.main.path(forResource: nibName, ofType: "storyboardc") {
            print("Storyboard path: \(storyboardPath)")
            let storyboard = UIStoryboard(name: nibName, bundle: nil)
            if let view = storyboard.instantiateInitialViewController()?.view {
                return view
            } else {
                print("Failed to instantiate storyboard view")
            }
        } else {
            if let view = Bundle.main.loadNibNamed(nibName, owner: nil, options: nil)?.first as? UIView {
                return view
            } else {
                print("Failed to load XIB")
            }
        }
        
        return nil
    }

}

