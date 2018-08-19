//
//  CustomButton.swift
//  SimpleWallet
//
//  Created by nishino on 2018/08/19.
//  Copyright © 2018年 Akifumi Fujita. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable class CustomButton: UIButton {
    
    @IBInspectable var cornerRadius: CGFloat = 0.0
    @IBInspectable var borderColor: UIColor = UIColor.clearColor()
    @IBInspectable var borderWidth: CGFloat = 0.0
    
    override func drawRect(rect: CGRect) {
        
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = (cornerRadius > 0)
        
        self.layer.borderColor = borderColor.CGColor
        self.layer.borderWidth = borderWidth
        
        super.drawRect(rect)
    }
}
