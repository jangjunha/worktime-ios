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
        static let title = "오늘의 근무시간을 알려주세요!"
    }


    // MARK: UI

    lazy var createWorktimeViewController: CreateWorktimeViewController = {
        let viewController = self.common.createWorktimeViewControllerFactory.create(payload: .init(
            reactor: self.common.createWorktimeViewReactorFactory.create(payload: .init())
        ))
        viewController.delegate = self
        return viewController
    }()


    // MARK: Properties

    let common = CommonDependency.resolve()


    // MARK: View Life Cycle

    override func loadView() {
        self.view = UIView()
        self.view.addSubview(self.createWorktimeViewController.view)
    }


    // MARK: View Life Cycle

    override func viewDidLoad() {
        self.createWorktimeViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.addChild(self.createWorktimeViewController)
        self.createWorktimeViewController.didMove(toParent: self)
    }


    // MARK: UNNotificationContentExtension

    func didReceive(_ notification: UNNotification) {
        self.title = Constant.title
        self.createWorktimeViewController.notificationIdentifier = notification.request.identifier
    }
}

extension NotificationViewController: CreateWorktimeViewDelegate {
    func createWorktimeViewShouldDismiss() {
        self.extensionContext?.dismissNotificationContentExtension()
    }
}
