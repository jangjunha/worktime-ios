//
//  NotificationService.swift
//  worktime
//
//  Created by junha on 2019/09/08.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import UserNotifications


class NotificationService {
    enum Constant {
        static let scheduledNotificationIdentifierFormat = "notification-identifiers.worktime.heek.kr/"
                                                         + "scheduled/weekdays/%d"
        static let categoryIdentifier = "worktimeAlert"
        static let notificationBody = "⏰ 오늘의 근무시간을 알려주세요!"
    }


    let userNotificationCenter: UNUserNotificationCenter


    init(userNotificationCenter: UNUserNotificationCenter) {
        self.userNotificationCenter = userNotificationCenter
    }

    func registerNotification(
        identifier: String,
        dateMatching dateComponents: DateComponents,
        repeats: Bool,
        completion: @escaping (Error?) -> Void
    ) {
        let request = UNNotificationRequest(
            identifier: identifier,
            content: UNMutableNotificationContent().then {
                $0.categoryIdentifier = Constant.categoryIdentifier
                $0.body = Constant.notificationBody
            },
            trigger: UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: repeats
            )
        )
        self.userNotificationCenter.add(request, withCompletionHandler: completion)
    }
}
