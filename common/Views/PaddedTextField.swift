//
//  PaddedTextField.swift
//  worktime
//
//  Created by junha on 2019/09/21.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import UIKit

class PaddedTextField: UITextField {
    var contentInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(
            x: bounds.origin.x + self.contentInsets.left,
            y: bounds.origin.y + self.contentInsets.top,
            width: bounds.size.width - (self.contentInsets.left + self.contentInsets.right),
            height: bounds.size.height - (self.contentInsets.top + self.contentInsets.bottom)
        )
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return self.textRect(forBounds: bounds)
    }
}
