//
//  ModalViewController.swift
//  SimpleWallet
//
//  Created by ニシノ on 2018/08/18.
//  Copyright © 2018年 Akifumi Fujita. All rights reserved.
//

import UIKit

class ModalViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func setAddress() {
        if let cashAddress = AppController.shared.wallet?.publicKey.toCashaddr().cashaddr {
//            cashAddress
        }
    }
    
    fileprivate func setBalance() {
        let legacyPubAddressString = AppController.shared.wallet!.publicKey.toLegacy().base58
        APIClient().getUnspentOutputs(withAddresses: [legacyPubAddressString], completionHandler: { [weak self] (utxos: [UnspentOutput]) in
            let balance = utxos.reduce(0) { $0 + $1.amount }
            DispatchQueue.main.async {
//                "\(balance) tBCH"
            }
        })
    }
}
