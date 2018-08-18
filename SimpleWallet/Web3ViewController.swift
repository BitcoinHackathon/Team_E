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

enum JS2NativeMessageName: String, CustomStringConvertible {
    case sendTransaction = "sendTransaction"
    
    var description: String {
        return rawValue
    }
}

class Web3ViewController: UIViewController {
    @IBOutlet weak var searchbar: UISearchBar!

    lazy var configuration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()

        // web3.js をページがロードされるごとにInjectionする
        let scriptURL = Bundle.main.path(forResource: "web3", ofType: "js")
        var scriptContent = try! String(contentsOfFile: scriptURL!, encoding: .utf8)
        let script = WKUserScript(source: scriptContent, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(script)

        // window.webkit.messageHandlers.sendTransaction.postMessage("{transaction data}") でネイティブコードを呼び出せるようにする
        configuration.userContentController.add(self, js2NativeMessage: .sendTransaction)

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
}

extension Web3ViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        searchBar.showsCancelButton = true
        print(searchBar.text ?? "")
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        self.view.endEditing(true)
        searchBar.text = ""
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        return true
    }
}

extension Web3ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let name = JS2NativeMessageName(rawValue: message.name) else {
            return
        }
        switch name {
        case .sendTransaction:
            if let transaction = message.body as? String {
                print(transaction)
            }
        }
    }
}

private extension WKUserContentController {
    func add(_ scriptMessageHandler: WKScriptMessageHandler, js2NativeMessage message: JS2NativeMessageName) {
        self.add(scriptMessageHandler, name: message.rawValue)
    }
}
