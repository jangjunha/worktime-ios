//
//  StringExtension.swift
//  worktime
//
//  Created by junha on 2019/09/05.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import Foundation


extension String {
    var urlEscaped: String {
        return addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }

    var utf8Encoded: Data {
        return data(using: .utf8)!
    }
}

extension Collection where Iterator.Element: NSAttributedString {
    func joined(separator: String? = nil) -> NSAttributedString {
        let str = NSMutableAttributedString()
        self.enumerated().forEach { offset, element in
            if let separator = separator, offset > 0 {
                str.append(.init(string: separator))
            }
            str.append(element)
        }
        return str
    }
}
