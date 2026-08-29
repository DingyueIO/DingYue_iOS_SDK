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

    fileprivate struct DemoSection {
        let title: String
        let footer: String
        let items: [DemoItem]
    }

    fileprivate struct DemoItem {
        let title: String
        let subtitle: String
        let systemImageName: String
        let action: () -> Void
    }

    private struct LocalWebResource {
        let htmlPath: String
        let basePath: String
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let localPaywallFolderName = "7306588143563858788"
    private let localGuideBundleName = "DemoGuide"

    private lazy var sections: [DemoSection] = [
        DemoSection(
            title: "基础能力",
            footer: "展示激活后常用的基础查询、事件上报和远程开关读取。",
            items: [
                DemoItem(
                    title: "读取设备 UUID",
                    subtitle: "DYMobileSDK.requestDeviceUUID()",
                    systemImageName: "number",
                    action: { [weak self] in self?.showDeviceUUIDAction() }
                ),
                DemoItem(
                    title: "读取后台产品配置",
                    subtitle: "DYMobileSDK.getProductItems()",
                    systemImageName: "list.bullet.rectangle",
                    action: { [weak self] in self?.showCachedProductsAction() }
                ),
                DemoItem(
                    title: "上报自定义事件",
                    subtitle: "DYMobileSDK.track(event:extra:user:)",
                    systemImageName: "paperplane",
                    action: { [weak self] in self?.trackDemoEventAction() }
                ),
                DemoItem(
                    title: "查询远程开关",
                    subtitle: "DYMobileSDK.getSwitchStatus(switchName:)",
                    systemImageName: "switch.2",
                    action: { [weak self] in self?.getSwitchStatusAction() }
                )
            ]
        ),
        DemoSection(
            title: "购买与付费墙",
            footer: "包含可视化付费墙、展示样式配置、恢复购买和消耗品购买。",
            items: [
                DemoItem(
                    title: "展示可视化 Paywall",
                    subtitle: "DYMobileSDK.showVisualPaywall(products:rootController:extras:)",
                    systemImageName: "rectangle.stack",
                    action: { [weak self] in self?.goPurchaseSubscriptionAction() }
                ),
                DemoItem(
                    title: "展示本地 Web Paywall",
                    subtitle: "7306588143563858788/index.html + loadNativePaywall",
                    systemImageName: "doc.richtext",
                    action: { [weak self] in self?.showLocalWebPaywallAction() }
                ),
                DemoItem(
                    title: "配置 Paywall 展示样式",
                    subtitle: "DYMConfiguration.shared.paywallConfig",
                    systemImageName: "slider.horizontal.3",
                    action: { [weak self] in self?.showPaywallConfigAction() }
                ),
                DemoItem(
                    title: "恢复购买",
                    subtitle: "DYMobileSDK.restorePurchase(completion:)",
                    systemImageName: "arrow.clockwise",
                    action: { [weak self] in self?.restorePurchaseAction() }
                ),
                DemoItem(
                    title: "消耗品购买",
                    subtitle: "DYMobileSDK.purchaseConsumption(productId:count:)",
                    systemImageName: "cart",
                    action: { [weak self] in self?.goPurchaseConsumptionAction() }
                )
            ]
        ),
        DemoSection(
            title: "引导页",
            footer: "展示 Web Guide 的接入方式，以及 Guide 内购买、恢复、关闭等回调链路。",
            items: [
                DemoItem(
                    title: "展示可视化 Guide",
                    subtitle: "DYMobileSDK.showVisualGuide(products:rootDelegate:extras:)",
                    systemImageName: "sparkles.rectangle.stack",
                    action: { [weak self] in self?.gotoWebGuide() }
                ),
                DemoItem(
                    title: "展示本地 Web Guide",
                    subtitle: "DemoGuide.bundle/index.html + loadNativeGuidePage",
                    systemImageName: "doc.on.doc",
                    action: { [weak self] in self?.showLocalWebGuideAction() }
                )
            ]
        ),
        DemoSection(
            title: "用户与归因",
            footer: "展示用户属性、分群和 Apple Search Ads 归因能力。",
            items: [
                DemoItem(
                    title: "设置用户属性",
                    subtitle: "DYMobileSDK.setCustomPropertiesWith(_:completion:)",
                    systemImageName: "person.crop.circle.badge.plus",
                    action: { [weak self] in self?.setCustomerProperties() }
                ),
                DemoItem(
                    title: "获取用户分群",
                    subtitle: "DYMobileSDK.getSegmentInfo(completion:)",
                    systemImageName: "person.3",
                    action: { [weak self] in self?.getSegmentInfo() }
                ),
                DemoItem(
                    title: "获取 ASA 归因",
                    subtitle: "DYMobileSDK.retrieveAppleSearchAdsAttribution(mode:completion:)",
                    systemImageName: "magnifyingglass.circle",
                    action: { [weak self] in self?.getAppleSearchAdsInfo() }
                )
            ]
        ),
        DemoSection(
            title: "扩展能力",
            footer: "展示 Lua 扩展能力，便于接入方确认脚本调用方式。",
            items: [
                DemoItem(
                    title: "执行 Lua 示例",
                    subtitle: "TestLuaOperation.callLuaFunction(...)",
                    systemImageName: "curlybraces",
                    action: { [weak self] in self?.luaTestAction() }
                )
            ]
        )
    ]

    private var sampleProducts: [Subscription] {
        let week = Subscription(
            type: "SUBSCRIPTION",
            name: "Week",
            platformProductId: "testWeek",
            price: "7.99",
            currencyCode: "USD",
            countryCode: "US"
        )
        let year = Subscription(
            type: "SUBSCRIPTION",
            name: "Year",
            platformProductId: "testYear",
            appleSubscriptionGroupId: nil,
            description: "default product item",
            period: "Year",
            price: "49.99",
            currencyCode: "USD",
            countryCode: "US",
            priceTier: nil,
            gracePeriod: nil,
            icon: nil,
            renewPriceChange: nil
        )
        return [week, year]
    }

    private var sampleExtras: [String: Any] {
        return [
            "phoneNumber": "1999999999",
            "phoneCountry": "国家",
            "purchasedProducts": purchasedProducts,
            "mainColor": "white"
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "DingYue SDK Demo"
        view.backgroundColor = .systemGroupedBackground
        setupTableView()
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DemoFeatureCell.self, forCellReuseIdentifier: DemoFeatureCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemGroupedBackground
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc func showDeviceUUIDAction() {
        showAlert(title: "设备 UUID", message: DYMobileSDK.requestDeviceUUID())
    }

    @objc func showCachedProductsAction() {
        let products = DYMobileSDK.getProductItems() ?? []
        guard !products.isEmpty else {
            showAlert(title: "产品配置", message: "当前没有缓存产品配置。请先确认 SDK activate 已完成，并且后台已下发产品。")
            return
        }

        let message = products
            .map { "\($0.name): \($0.platformProductId) / \($0.price) \($0.currencyCode)" }
            .joined(separator: "\n")
        showAlert(title: "产品配置", message: message)
    }

    @objc func trackDemoEventAction() {
        DYMobileSDK.track(
            event: "demo_sdk_feature_tap",
            extra: #"{"source":"DingYueSDKDemo","feature":"track"}"#,
            user: FCUUID.uuidForDevice()
        )
        showAlert(title: "事件上报", message: "已调用 DYMobileSDK.track(event:extra:user:)，可在日志或后台查看事件。")
    }

    @objc func getSwitchStatusAction() {
        let switchName = "demo_switch"
        let isEnabled = DYMobileSDK.getSwitchStatus(switchName: switchName)
        showAlert(title: "远程开关", message: "\(switchName): \(isEnabled)")
    }

    @objc func goPurchaseSubscriptionAction() {
        presentVisualPaywall()
    }

    @objc func showLocalWebPaywallAction() {
        guard let resource = localFolderWebResource(folderName: localPaywallFolderName) else {
            showAlert(title: "本地 Web Paywall", message: "\(localPaywallFolderName)/index.html 未找到，请确认资源已加入 Example target。")
            return
        }

        DYMobileSDK.loadNativePaywall(paywallFullPath: resource.htmlPath, basePath: resource.basePath)
        presentVisualPaywall()
    }

    private func presentVisualPaywall() {
        DYMobileSDK.showVisualPaywall(products: sampleProducts, rootController: self, extras: sampleExtras) { receipt, purchasedResult, purchasedProduct, error in
            if error == nil {
                print("返回结果：")
                print("订阅购买的产品：\(String(describing: purchasedProduct))\n订阅返回结果:\(String(describing: purchasedResult))")
                self.showAlert(title: "成功", message: "订阅购买成功")
            } else {
                self.showAlert(title: "失败", message: error?.localizedDescription ?? "订阅购买失败，请重试。")
            }
        }
    }

    @objc func restorePurchaseAction() {
        DYMobileSDK.restorePurchase { receipt, purchaseResult, purchasedProduct, error in
            if let error = error {
                self.showAlert(title: "恢复失败", message: error.localizedDescription)
                return
            }

            let receiptStatus = (receipt?.isEmpty == false) ? "已返回" : "无"
            let productStatus = purchasedProduct?.description ?? "无"
            let purchasedCount = purchaseResult?.count ?? 0
            self.showAlert(
                title: "恢复购买",
                message: "receipt: \(receiptStatus)\n恢复订阅数量: \(purchasedCount)\n产品信息: \(productStatus)"
            )
        }
    }

    @objc func goPurchaseConsumptionAction() {
        let testConsumptionProductId = "test.consumablesA"
        DYMobileSDK.purchaseConsumption(productId: testConsumptionProductId, count: 2) { receipt, purchaseResult, purchasedProduct, error in
            if error == nil {
                print("消耗品购买成功")
                self.showAlert(title: "成功", message: "消耗品购买成功")
            } else {
                self.showAlert(title: "失败", message: error?.localizedDescription ?? "购买失败，请重试。")
            }
        }
    }

    @objc func luaTestAction() {
        var didFail = false
        TestLuaOperation.sharedInstance().callLuaFunction("fun5", withParams: [], withReturnCount: 0, withKeepEnv: true) { error in
            didFail = true
            self.showAlert(title: "Lua", message: error.localizedDescription)
        }

        if !didFail {
            showAlert(title: "Lua", message: "已调用 fun5，请查看控制台输出。")
        }

//        DYMLuaScriptManager.downloadLuaScriptZip(url: URL(string: "https://github.com/quantopian/zipline/archive/refs/heads/master.zip")!) { result, error in
//            print("\(result)")
//        }
    }

    @objc func gotoWebGuide() {
        guard let rootDelegate = UIApplication.shared.delegate as? DYMWindowManaging else {
            showAlert(title: "Guide", message: "UIApplication.shared.delegate 未实现 DYMWindowManaging。")
            return
        }

        DYMobileSDK.showVisualGuide(products: sampleProducts, rootDelegate: rootDelegate, extras: sampleExtras) { receipt, purchaseResult, purchasedProduct, error in
            if let error = error {
                self.showAlert(title: "Guide 购买失败", message: error.localizedDescription)
            } else if let purchaseResult = purchaseResult, !purchaseResult.isEmpty {
                self.showAlert(title: "Guide 购买成功", message: "购买结果数量: \(purchaseResult.count)")
            }
            print("Guide receipt: \(String(describing: receipt))")
            print("Guide product: \(String(describing: purchasedProduct))")
        }
    }

    @objc func showLocalWebGuideAction() {
        guard let resource = localBundleWebResource(bundleName: localGuideBundleName) else {
            showAlert(title: "本地 Web Guide", message: "\(localGuideBundleName).bundle/index.html 未找到，请确认资源已加入 Example target。")
            return
        }

        DYMobileSDK.loadNativeGuidePage(paywallFullPath: resource.htmlPath, basePath: resource.basePath)
        gotoWebGuide()
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
            if error != nil {
                print("setCustomProperties failed: \(String(describing: error?.localizedDescription))")
                self.showAlert(title: "失败", message: "setCustomProperties: \(String(describing: error?.localizedDescription))")
            } else {
                print("setCustomProperties success: \(String(describing: result?.status))\n uuid: \(String(describing: FCUUID.uuidForDevice()))")
                self.showAlert(title: "成功", message: "setCustomProperties: \(String(describing: result?.status))\n uuid: \(String(describing: FCUUID.uuidForDevice()))")
            }
        }
    }

    @objc func getSegmentInfo() {
        DYMobileSDK.getSegmentInfo { result, error in
            if error != nil {
                self.showAlert(title: "失败", message: "getSegmentInfo: \(String(describing: error?.localizedDescription))")
            } else {
                let segmentListString = result?.segmentList.joined(separator: ",") ?? "[]"
                self.showAlert(title: "成功", message: "Segments: \(segmentListString)")
                print("\(String(describing: result?.segmentList))")
            }
        }
    }

    @objc func getAppleSearchAdsInfo() {
        DYMobileSDK.retrieveAppleSearchAdsAttribution(mode: .returnCache) { attribution, error in
            if error != nil {
                self.showAlert(title: "失败", message: "getAppleSearchAdsInfo: \(String(describing: error?.localizedDescription))")
            } else {
                let attributionString = self.dictionaryToArrayString(dictionary: attribution ?? [:])
                self.showAlert(title: "成功", message: "Ads:\n\(attributionString)")
                print("\(attributionString)")
            }
        }
    }

    @objc func showPaywallConfigAction() {
        let alertController = UIAlertController(title: "支付页面配置", message: "选择展示样式和手势设置", preferredStyle: .actionSheet)

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

        alertController.addAction(UIAlertAction(title: "下滑手势: \(DYMConfiguration.shared.paywallConfig.enableSwipeToDismiss ? "开启" : "关闭")", style: .default) { _ in
            DYMConfiguration.shared.paywallConfig.enableSwipeToDismiss.toggle()
            self.showPaywallConfigAction()
        })

        alertController.addAction(UIAlertAction(title: "边缘滑动手势: \(DYMConfiguration.shared.paywallConfig.enableSwipeToDismissFromEdge ? "开启" : "关闭")", style: .default) { _ in
            DYMConfiguration.shared.paywallConfig.enableSwipeToDismissFromEdge.toggle()
            self.showPaywallConfigAction()
        })

        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))

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
extension ViewController: DYMPayWallActionDelegate {
    func clickTermsAction(baseViewController: UIViewController) {
        let vc = LBWebViewController.init()
        vc.url = "url"
        vc.title = NSLocalizedString("Terms_of_Service", comment: "")
        let nav = UINavigationController.init(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        baseViewController.present(nav, animated: true)
    }

    func clickPrivacyAction(baseViewController: UIViewController) {
        let vc = LBWebViewController.init()
        vc.url = "url"
        vc.title = NSLocalizedString("Privacy_Policy", comment: "")
        let nav = UINavigationController.init(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        baseViewController.present(nav, animated: true)
    }

    func clickCloseButton(baseViewController: UIViewController) {
        print("点击了关闭按钮")
    }

    func payWallDidAppear(baseViewController: UIViewController) {
        print("内购页显示")
    }

    func payWallDidDisappear(baseViewController: UIViewController) {
        print("内购页消失")
    }
}

// MARK: Custom method
extension ViewController {
    private func localFolderWebResource(folderName: String) -> LocalWebResource? {
        let basePath = (Bundle.main.bundlePath as NSString).appendingPathComponent(folderName)
        let htmlPath = (basePath as NSString).appendingPathComponent("index.html")
        guard FileManager.default.fileExists(atPath: htmlPath) else {
            return nil
        }
        return LocalWebResource(htmlPath: htmlPath, basePath: basePath)
    }

    private func localBundleWebResource(bundleName: String) -> LocalWebResource? {
        guard let bundleURL = Bundle.main.url(forResource: bundleName, withExtension: "bundle"),
              let resourceBundle = Bundle(url: bundleURL),
              let htmlPath = resourceBundle.path(forResource: "index", ofType: "html") else {
            return nil
        }

        return LocalWebResource(htmlPath: htmlPath, basePath: resourceBundle.bundlePath)
    }

    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))

            if let topController = UIApplication.shared.windows.first?.rootViewController {
                var currentController = topController
                while let presentedController = currentController.presentedViewController {
                    currentController = presentedController
                }
                currentController.present(alertController, animated: true, completion: nil)
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footer
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DemoFeatureCell.reuseIdentifier, for: indexPath) as? DemoFeatureCell else {
            return UITableViewCell()
        }

        cell.configure(with: sections[indexPath.section].items[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        sections[indexPath.section].items[indexPath.row].action()
    }
}

// MARK: - DemoFeatureCell
private final class DemoFeatureCell: UITableViewCell {
    static let reuseIdentifier = "DemoFeatureCell"

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()

    private lazy var labelsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        selectionStyle = .default
        contentView.addSubview(iconView)
        contentView.addSubview(labelsStack)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            labelsStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 14),
            labelsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            labelsStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            labelsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func configure(with item: ViewController.DemoItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        iconView.image = UIImage(systemName: item.systemImageName)
    }
}
