//
//  TimeService.swift
//  worktime
//
//  Created by junha on 2019/12/01.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import Foundation

protocol TimeServiceType: class {
    func now() -> Date
}

class TimeService: TimeServiceType {
    func now() -> Date {
        return Date()
    }
}

class MockTimeService: TimeServiceType {
    var _now: Date = Date()  // swiftlint:disable:this identifier_name

    func now() -> Date {
        return _now
    }
}
