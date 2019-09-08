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
