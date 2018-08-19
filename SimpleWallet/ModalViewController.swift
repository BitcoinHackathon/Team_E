//
//  ModalViewController.swift
//  SimpleWallet
//
//  Created by ニシノ on 2018/08/18.
//  Copyright © 2018年 Akifumi Fujita. All rights reserved.
//

import UIKit



class ModalViewController: UIViewController {

    @IBOutlet weak var balanceLabel: UILabel!
    
    var didCompleteAction: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
   
        setBalance()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func tappedOK(_ sender: Any) {
        self.dismiss(animated: true, completion: {
            self.didCompleteAction?()
        })
    }
    
    @IBAction func tappedCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func setBalance() {
        guard let legacyPubAddressString = AppController.shared.wallet?.publicKey.toLegacy().base58 else { return }
        APIClient().getUnspentOutputs(withAddresses: [legacyPubAddressString], completionHandler: { [weak self] (utxos: [UnspentOutput]) in
            let balance = utxos.reduce(0) { $0 + $1.amount }
            DispatchQueue.main.async {
                self?.balanceLabel.text = "残高:\n　\(balance) tBCH"
            }
        })
    }
}
