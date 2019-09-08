//
//  StubAppDependency.swift
//  worktime
//
//  Created by junha on 2019/09/08.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import Moya


class StubGoogleLoginService: GoogleLoginServiceType {
    fileprivate let preference: Preference

    var presentingViewController: UIViewController? {
        get {
            return nil
        }
        set(value) {}  // swiftlint:disable:this unused_setter_value
    }

    init(preference: Preference) {
        self.preference = preference
    }

    func signIn() {
        // TODO: Stubber 등 이용해서 수정하기
        self.preference.googleUser = GoogleUser(
            accessToken: "MOCK-ACCESS-TOKEN",
            accessTokenExpirationDate: Date().addingTimeInterval(3600),
            refreshToken: "MOCK-REFRESH-TOKEN",
            name: "junha"
        )
    }

    func signOut() {
        self.preference.googleUser = nil
    }
}

extension AppDependency {
    static func resolveForUITests() -> AppDependency {
        let common = CommonDependency.resolveForUITests()

        let stubGoogleLoginService = StubGoogleLoginService(preference: common.preference)

        let selectCalendarViewControllerFactory = SelectCalendarViewController.Factory(dependency: .init(
            preference: common.preference,
            googleProvider: common.googleProvider
        ))
        let selectNotificationTimeViewControllerFactory = SelectNotificationTimeViewController.Factory(
            dependency: .init(
                preference: common.preference,
                userNotificationCenter: common.userNotificationCenter,
                notificationService: common.notificationService
            )
        )
        let settingsViewControllerFactory = SettingsViewController.Factory(dependency: .init(
            preference: common.preference,
            userNotificationCenter: common.userNotificationCenter,
            notificationService: common.notificationService,
            googleLoginService: stubGoogleLoginService,
            selectCalendarViewControllerFactory: selectCalendarViewControllerFactory,
            selectNotificationTimeViewControllerFactory: selectNotificationTimeViewControllerFactory
        ))

        return AppDependency(
            userNotificationCenter: common.userNotificationCenter,
            preference: common.preference,
            googleClientID: common.googleClientID,
            googleProvider: common.googleProvider,
            googleLoginService: stubGoogleLoginService,
            settingsViewControllerFactory: settingsViewControllerFactory,
            selectCalendarViewControllerFactory: selectCalendarViewControllerFactory,
            createWorktimeViewControllerFactory: common.createWorktimeViewControllerFactory,
            createWorktimeViewReactorFactory: common.createWorktimeViewReactorFactory
        )
    }
}
