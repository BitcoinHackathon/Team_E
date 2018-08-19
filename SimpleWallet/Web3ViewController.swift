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
import BitcoinKit

enum JS2NativeMessageName: String, CustomStringConvertible {
    case getAddress = "getAddress"
    case sendTransaction = "sendTransaction"
    
    var description: String {
        return rawValue
    }
}

class Web3ViewController: UIViewController {
    @IBOutlet weak var searchbar: UISearchBar!

    fileprivate var previousSearchText = ""
    
    lazy var configuration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()

        // web3.js をページがロードされるごとにInjectionする
        let scriptURL = Bundle.main.path(forResource: "web3", ofType: "js")
        var scriptContent = try! String(contentsOfFile: scriptURL!, encoding: .utf8)
        let script = WKUserScript(source: scriptContent, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(script)

        configuration.userContentController.add(self, js2NativeMessage: .getAddress)
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
        webView.allowsBackForwardNavigationGestures = true
        view.insertSubview(webView, at: 0)
        webView.uiDelegate = uiDelegate
        observer.onTitleChanged = { [weak self] in self?.title = $0 }
        observer.onURLChanged = { [weak self] url in
            self?.searchbar.text = url?.absoluteString
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let googleUrl = "https://google.co.jp/"
        webView.load(URLRequest(url: URL(string: googleUrl)!))
        previousSearchText = googleUrl
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func showModalViewController() {
        if let modalVC = storyboard?.instantiateViewController(withIdentifier: "ModalViewController") as? ModalViewController {
            modalVC.didCompleteAction = {
                self.showAlertControllert(with: "署名が完了しました。")
            }
            self.present(modalVC, animated: true, completion: nil)
        }
    }
    
    fileprivate func showAlertControllert(with titleText: String) {
        let alert = UIAlertController(title: titleText, message: "", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler:{
            (action: UIAlertAction!) -> Void in
            print("OKが押された")
        })
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}

extension Web3ViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        searchBar.showsCancelButton = true

        print(searchBar.text ?? "")
        if let url = URL(string: searchBar.text ?? "") {
            webView.load(URLRequest(url: url))
        } else {
            searchBar.text = previousSearchText
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        self.view.endEditing(true)
        searchBar.text = previousSearchText
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        previousSearchText = searchBar.text ?? ""
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
        case .getAddress:
            let cashAddress = AppController.shared.wallet!.publicKey.toCashaddr().base58
            receive(cashAddress, to: message)
        }
    }

    func receive(_ string: String, to message: WKScriptMessage) {
        guard let messages = (message.body as? Dictionary<String, Any>), let promiseId = messages["promiseId"] as? String else {
            return
        }
        webView.evaluateJavaScript("web3.resolvePromise('\(promiseId)\', '\(string)', null)")
    }

    func receive(_ value: Int64, message: WKScriptMessage) {
        guard let messages = (message.body as? Dictionary<String, Any>), let promiseId = messages["promiseId"] as? String else {
            return
        }

        webView.evaluateJavaScript("web3.resolvePromise('\(promiseId)\', \(String(value)), null)")
    }
}

private extension WKUserContentController {
    func add(_ scriptMessageHandler: WKScriptMessageHandler, js2NativeMessage message: JS2NativeMessageName) {
        self.add(scriptMessageHandler, name: message.rawValue)
    }
}
