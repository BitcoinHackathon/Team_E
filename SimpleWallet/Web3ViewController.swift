//
//  Web3ViewController.swift
//  SimpleWallet
//
//  Created by niwatako on 2018/08/18.
//  Copyright © 2018年 Akifumi Fujita. All rights reserved.
//

import UIKit
import WebKit
import WebKitPlus

class Web3ViewController: UIViewController {
    lazy var configuration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()

        // web3.js をページがロードされるごとにInjectionする
        let scriptURL = Bundle.main.path(forResource: "web3", ofType: "js")
        var scriptContent = try! String(contentsOfFile: scriptURL!, encoding: .utf8)
        let script = WKUserScript(source: scriptContent, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(script)

        return configuration
    }()

    lazy var webView: WKWebView = WKWebView(frame: self.view.frame, configuration: self.configuration)
    lazy var uiDelegate: WKUIDelegatePlus = WKUIDelegatePlus(parentViewController: self)
    lazy var observer: WebViewObserver = WebViewObserver(obserbee: self.webView)

    override func viewDidLoad() {
        super.viewDidLoad()

        webView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(webView, at: 0)
        webView.uiDelegate = uiDelegate
        observer.onTitleChanged = { [weak self] in self?.title = $0 }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        webView.load(URLRequest(url: URL(string: "https://google.co.jp/")!))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
