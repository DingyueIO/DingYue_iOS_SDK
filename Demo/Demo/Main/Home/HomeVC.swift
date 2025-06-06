//
//  HomeVC.swift
//  Demo
//
//  Created by ZZ on 2025/6/6.
//

import UIKit

class HomeVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }


    @IBAction func showGuidePage(_ sender: Any) {
        IWDingYueManager.showDingYueGuidePage()
    }
    
    @IBAction func showPayPage(_ sender: Any) {
        IWDingYueManager.showDingYuePayPage()
    }
    

}
