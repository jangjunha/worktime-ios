//
//  NotificationService.swift
//  worktime
//
//  Created by junha on 2019/09/08.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import UIKit
import UserNotifications


class NotificationService {
    enum Constant {
        static let scheduledNotificationIdentifierFormat = "notification-identifiers.worktime.heek.kr/"
                                                         + "scheduled/weekdays/%d"
        static let categoryIdentifier = "worktimeAlert"
        static let buildNotificationBody = { (dayBefore: Int) -> String in
            switch dayBefore {
            case 1:
                return "내일 언제 근무하시나요?"
            case 0:
                return "오늘의 근무시간을 알려주세요!"
            default:
                return "근무시간을 알려주세요!"
            }
        }
    }


    let userNotificationCenter: UNUserNotificationCenter

    let preference: Preference


    init(userNotificationCenter: UNUserNotificationCenter, preference: Preference) {
        self.userNotificationCenter = userNotificationCenter
        self.preference = preference
    }

    func registerNotification(
        identifier: String,
        dateMatching dateComponents: DateComponents,
        repeats: Bool,
        presentingViewController: UIViewController?,
        completion: @escaping (Error?) -> Void
    ) {
        let request = UNNotificationRequest(
            identifier: identifier,
            content: UNMutableNotificationContent().then {
                $0.categoryIdentifier = Constant.categoryIdentifier
                $0.body = Constant.buildNotificationBody(self.preference.notifiedBefore ?? 0)
            },
            trigger: UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: repeats
            )
        )

        self.userNotificationCenter.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            guard granted, error == nil else {
                let alertController = UIAlertController(
                    title: "권한 없음",
                    message: "권한을 부여하려면 설정 앱에서 알림을 허용해주세요.",
                    preferredStyle: .alert
                )
                alertController.addAction(.init(
                    title: "닫기",
                    style: .default
                ))
                presentingViewController?.present(alertController, animated: true)
                return
            }

            self.userNotificationCenter.add(request, withCompletionHandler: completion)
        }
    }
}
