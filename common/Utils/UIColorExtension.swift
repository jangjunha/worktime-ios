//
//  UIColorExtension.swift
//  worktime
//
//  Created by junha on 29/08/2019.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import UIKit

extension UIColor {
    func lighten(by percentage: CGFloat) -> UIColor {
        return self.adjust(by: abs(percentage))
    }

    func darken(by percentage: CGFloat) -> UIColor {
        return self.adjust(by: -1 * abs(percentage))
    }

    func adjust(by percentage: CGFloat) -> UIColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: min(red + percentage, 1.0),
                           green: min(green + percentage, 1.0),
                           blue: min(blue + percentage, 1.0),
                           alpha: alpha)
        } else {
            assertionFailure("Cannot adjust color \(self)")
            return self
        }
    }
}
