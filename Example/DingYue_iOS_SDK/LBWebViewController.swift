//
//  LBWebViewController.swift
//  WalkMoney
//
//  Created by GM on 2020/9/3.
//  Copyright © 2020 GM. All rights reserved.
//

import UIKit
import WebKit

class LBWebViewController: UIViewController {
    
    var url : String = ""
    
    @objc var webView = WKWebView()
    
    lazy var myProgressView : UIProgressView = {
        let ProgressView = UIProgressView.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 1))
        ProgressView.tintColor = UIColor.blue
        ProgressView.trackTintColor = UIColor.white
        return ProgressView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.webView = WKWebView.init()
        self.view.addSubview(self.webView)
        
        let request = URLRequest.init(url: URL.init(string: self.url)!)
        self.webView.load(request)

        self.webView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        self.webView.center = self.view.center
        
        // 进度条
        self.view.addSubview(self.myProgressView)
        self.webView.addObserver(self, forKeyPath: "estimatedProgress", options: NSKeyValueObservingOptions.new, context: nil)


        //close btn
        if #available(iOS 13.0, *) {

        } else {
            let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            btn.setTitle("close", for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.addTarget(self, action: #selector(backUp), for: .touchUpInside)
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: btn)
        }
    }
    @objc func backUp(){
        self.dismiss(animated: true)
    }
    
    deinit {
//        self.webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            self.myProgressView.progress = Float(webView.estimatedProgress)
            if (self.myProgressView.progress >= 1.0) {
                let deadline = DispatchTime.now() + 0.3
                DispatchQueue.global().asyncAfter(deadline: deadline) {
                    DispatchQueue.main.async {
                        self.myProgressView.progress = 0;
                    }
                }
            }
        }else{

        }
    }
}
