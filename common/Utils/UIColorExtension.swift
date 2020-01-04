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

    static let compat = CompatColor()

    static let labelDisabled = UIColor.compat.systemGray2
}

struct CompatColor {
    var link: UIColor {
        if #available(iOS 13.0, *) {
            return .link
        } else {
            return .systemBlue
        }
    }

    var label: UIColor {
        if #available(iOS 13.0, *) {
            return .label
        } else {
            return .black
        }
    }

    var systemGray: UIColor {
        if #available(iOS 13.0, *) {
            return .systemGray
        } else {
            return .init(red: 142, green: 142, blue: 147, alpha: 1)
        }
    }

    var systemGray2: UIColor {
        if #available(iOS 13.0, *) {
            return .systemGray
        } else {
            return .init(red: 174, green: 174, blue: 178, alpha: 1)
        }
    }

    var systemGray3: UIColor {
        if #available(iOS 13.0, *) {
            return .systemGray
        } else {
            return .init(red: 199, green: 199, blue: 204, alpha: 1)
        }
    }

    var systemGray4: UIColor {
        if #available(iOS 13.0, *) {
            return .systemGray
        } else {
            return .init(red: 209, green: 209, blue: 214, alpha: 1)
        }
    }

    var systemGray5: UIColor {
        if #available(iOS 13.0, *) {
            return .systemGray
        } else {
            return .init(red: 229, green: 229, blue: 234, alpha: 1)
        }
    }

    var systemGray6: UIColor {
        if #available(iOS 13.0, *) {
            return .systemGray
        } else {
            return .init(red: 242, green: 242, blue: 247, alpha: 1)
        }
    }

    var systemBackground: UIColor {
        if #available(iOS 13.0, *) {
            return .systemBackground
        } else {
            return .white
        }
    }
}
