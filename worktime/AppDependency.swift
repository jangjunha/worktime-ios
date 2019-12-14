//
//  AppDependencyType.swift
//  worktime
//
//  Created by junha on 2019/09/08.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import Foundation
import UserNotifications

struct AppDependency {
    let userNotificationCenter: UNUserNotificationCenter
    let preference: Preference

    let googleClientID: String
    let googleProvider: GoogleProvider

    let googleLoginService: GoogleLoginServiceType

    let settingsViewControllerFactory: SettingsViewController.Factory
    let selectCalendarViewControllerFactory: SelectCalendarViewController.Factory
    let scrollableCreateWorktimeViewControllerFactory: ScrollableCreateWorktimeViewController.Factory
}
