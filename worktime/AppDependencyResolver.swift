//
//  AppDependency.swift
//  worktime
//
//  Created by junha on 2019/09/05.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import GoogleSignIn
import Moya
import Then
import UIKit
import UserNotifications

extension AppDependency {
    static func resolve() -> AppDependency {
        let common = CommonDependency.resolve()

        let gidSignIn = GIDSignIn.sharedInstance()!.then {
            $0.clientID = common.googleClientID
            $0.scopes.append(contentsOf: [
                "https://www.googleapis.com/auth/calendar.readonly",
                "https://www.googleapis.com/auth/calendar.events"
            ])
        }
        let googleLoginService = GoogleLoginService(gidSignIn: gidSignIn, preference: common.preference)

        let selectCalendarViewControllerFactory = SelectCalendarViewController.Factory(dependency: .init(
            preference: common.preference,
            googleProvider: common.googleProvider
        ))
        let selectNotificationTimeViewControllerFactory = SelectNotificationTimeViewController.Factory(
            dependency: .init(
                preference: common.preference,
                userNotificationCenter: common.userNotificationCenter,
                notificationService: common.notificationService,
                timeService: common.timeService
            )
        )
        let settingsViewControllerFactory = SettingsViewController.Factory(dependency: .init(
            preference: common.preference,
            userNotificationCenter: common.userNotificationCenter,
            notificationService: common.notificationService,
            googleLoginService: googleLoginService,
            selectCalendarViewControllerFactory: selectCalendarViewControllerFactory,
            selectNotificationTimeViewControllerFactory: selectNotificationTimeViewControllerFactory
        ))
        let scrollableCreateWorktimeViewControllerFactory = ScrollableCreateWorktimeViewController.Factory(
            dependency: .init(
                preference: common.preference,
                timeService: common.timeService,
                createWorktimeViewControllerFactory: common.createWorktimeViewControllerFactory,
                createWorktimeViewReactorFactory: common.createWorktimeViewReactorFactory
            )
        )

        return AppDependency(
            userNotificationCenter: common.userNotificationCenter,
            preference: common.preference,
            googleClientID: common.googleClientID,
            googleProvider: common.googleProvider,
            googleLoginService: googleLoginService,
            settingsViewControllerFactory: settingsViewControllerFactory,
            selectCalendarViewControllerFactory: selectCalendarViewControllerFactory,
            scrollableCreateWorktimeViewControllerFactory: scrollableCreateWorktimeViewControllerFactory
        )
    }
}
