//
//  DateExtension.swift
//  worktime
//
//  Created by junha on 2019/09/06.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import Foundation

extension ISO8601DateFormatter {
    convenience init(_ formatOptions: Options, timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!) {
        self.init()
        self.formatOptions = formatOptions
        self.timeZone = timeZone
    }
}

extension Formatter {
    static let iso8601 = ISO8601DateFormatter([.withInternetDateTime, .withFractionalSeconds])
}

extension Date {
    var isoFormat: String {
        return Formatter.iso8601.string(from: self)
    }
}

extension String {
    var date: Date? {
        return Formatter.iso8601.date(from: self)
    }
}
