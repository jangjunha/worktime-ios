//
//  NotificationViewController.swift
//  worktime-noti-content
//
//  Created by junha on 26/07/2019.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import SnapKit
import UIKit
import UserNotifications
import UserNotificationsUI


@objc(NotificationViewController)
class NotificationViewController: UIViewController, UNNotificationContentExtension {
    // MARK: Constants

    enum Constant {
        static let buildTitle = { (dayBefore: Int) -> String in
            switch dayBefore {
            case 0:
                return "오늘의 근무시간을 알려주세요!"
            case 1:
                return "내일 언제 근무하시나요?"
            default:
                assertionFailure("Expects dayBefore is not nil")
                return "근무시간을 알려주세요!"
            }
        }
    }


    // MARK: UNNotificationContentExtension

    func didReceive(_ notification: UNNotification) {
        let isUITests = notification.request.content.userInfo["-UITests"] as? Bool

        let common: CommonDependency
        if isUITests == true {
            common = .resolveForUITests()
        } else {
            common = .resolve()
        }

        let dayBefore: Int = {
            let now = common.timeService.now()
            let hour = calendar.dateComponents([.hour], from: Date()).hour ?? 0
            return hour <= common.preference.dateSeparatorHour ? 0 : 1
        }()
        self.title = Constant.buildTitle(dayBefore)

        let createWorktimeViewController: CreateWorktimeViewController = {
            let viewController = common.createWorktimeViewControllerFactory.create(payload: .init(
                reactor: common.createWorktimeViewReactorFactory.create(payload: .init(
                    dayBefore: dayBefore
                ))
            ))
            viewController.delegate = self
            viewController.notificationIdentifier = notification.request.identifier
            return viewController
        }()
        self.view.addSubview(createWorktimeViewController.view)
        createWorktimeViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.addChild(createWorktimeViewController)
        createWorktimeViewController.didMove(toParent: self)
    }
}

extension NotificationViewController: CreateWorktimeViewDelegate {
    func createWorktimeViewShouldDismiss() {
        self.extensionContext?.dismissNotificationContentExtension()
    }
}
