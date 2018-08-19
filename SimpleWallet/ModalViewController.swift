//
//  ModalViewController.swift
//  SimpleWallet
//
//  Created by ニシノ on 2018/08/18.
//  Copyright © 2018年 Akifumi Fujita. All rights reserved.
//

import UIKit
import BitcoinKit

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

    struct Output {
        let value: Int64
        let lockScriptTo: Script
    }

    // 送金額、宛先LockScriptを受け取るとそれに対して必要なInputをかき集めて署名して送る
    func sendTransaction(to output: Output) {
        // 1. おつり用のアドレスを決める
        let changeAddress: Address = AppController.shared.wallet!.publicKey.toCashaddr()

        // 2. UTXOの取得
        let legacyAddress: String = AppController.shared.wallet!.publicKey.toLegacy().description
        APIClient().getUnspentOutputs(withAddresses: [legacyAddress], completionHandler: { [weak self] (unspentOutputs: [UnspentOutput]) in
            guard let strongSelf = self else {
                return
            }
            let utxos = unspentOutputs.map { $0.asUnspentTransaction() }
            let unsignedTx = strongSelf.createUnsignedTx(to: output.lockScriptTo, amount: output.value, changeAddress: changeAddress, utxos: utxos)
            let signedTx = strongSelf.signTx(unsignedTx: unsignedTx, keys: [AppController.shared.wallet!.privateKey])
            let rawTx = signedTx.serialized().hex

            // 7. 署名されたtxをbroadcastする
            APIClient().postTx(withRawTx: rawTx, completionHandler: { (txid, error) in
                if let txid = txid {
                    print("txid = \(txid)")
                    print("txhash: https://test-bch-insight.bitpay.com/tx/\(txid)")
                } else {
                    print("error post \(error ?? "error = nil")")
                }
            })
        })
    }

    func selectTx(from utxos: [UnspentTransaction], amount: Int64) -> (utxos: [UnspentTransaction], fee: Int64) {
        return (utxos, 500)
    }

    func createUnsignedTx(to lockScriptTo: Script, amount: Int64, changeAddress: Address, utxos: [UnspentTransaction]) -> UnsignedTransaction {
        // 3. 送金に必要なUTXOの選択
        let (utxos, fee) = selectTx(from: utxos, amount: amount)
        let totalAmount: Int64 = utxos.reduce(0) { $0 + $1.output.value }
        let change: Int64 = totalAmount - amount - fee


        // 4. LockScriptを書いて、TransactionOutputを作成する
        let lockScriptChange = Script(address: changeAddress)!

        let toOutput = TransactionOutput(value: amount, lockingScript: lockScriptTo.data)
        let changeOutput = TransactionOutput(value: change, lockingScript: lockScriptChange.data)

        // 5. UTXOとTransactionOutputを合わせて、UnsignedTransactionを作る
        let unsignedInputs = utxos.map { TransactionInput(previousOutput: $0.outpoint, signatureScript: Data(), sequence: UInt32.max) }
        let tx = Transaction(version: 1, inputs: unsignedInputs, outputs: [toOutput, changeOutput], lockTime: 0)
        return UnsignedTransaction(tx: tx, utxos: utxos)
    }

    // 6. 署名する
    public func signTx(unsignedTx: UnsignedTransaction, keys: [PrivateKey]) -> Transaction {
        var inputsToSign = unsignedTx.tx.inputs
        var transactionToSign: Transaction {
            return Transaction(version: unsignedTx.tx.version, inputs: inputsToSign, outputs: unsignedTx.tx.outputs, lockTime: unsignedTx.tx.lockTime)
        }

        // Signing
        let hashType = SighashType.BCH.ALL
        for (i, utxo) in unsignedTx.utxos.enumerated() {
            let pubkeyHash: Data = Script.getPublicKeyHash(from: utxo.output.lockingScript)

            let keysOfUtxo: [PrivateKey] = keys.filter { $0.publicKey().pubkeyHash == pubkeyHash }
            guard let key = keysOfUtxo.first else {
                continue
            }

            let sighash: Data = transactionToSign.signatureHash(for: utxo.output, inputIndex: i, hashType: SighashType.BCH.ALL)
            let signature: Data = try! Crypto.sign(sighash, privateKey: key)
            let txin = inputsToSign[i]
            let pubkey = key.publicKey()

            // unlockScriptを作る
            let unlockingScript = Script.buildPublicKeyUnlockingScript(signature: signature, pubkey: pubkey, hashType: hashType)

            // TODO: sequenceの更新
            inputsToSign[i] = TransactionInput(previousOutput: txin.previousOutput, signatureScript: unlockingScript, sequence: txin.sequence)
        }
        return transactionToSign
    }
}
