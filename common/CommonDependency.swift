//
//  CommonDependency.swift
//  worktime
//
//  Created by junha on 2019/09/06.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import Moya
import Pure
import Then
import UserNotifications


typealias GoogleProvider = MoyaProvider<GoogleAPI>

struct CommonDependency {
    let userNotificationCenter: UNUserNotificationCenter
    let notificationService: NotificationService
    let preference: Preference

    let googleClientID: String
    let googleProvider: GoogleProvider

    let createWorktimeViewControllerFactory: CreateWorktimeViewController.Factory
    let createWorktimeViewReactorFactory: CreateWorktimeViewReactor.Factory
}

extension CommonDependency {
    static func resolve() -> CommonDependency {
        let userNotificationCenter = UNUserNotificationCenter.current()
        let notificationService = NotificationService(userNotificationCenter: userNotificationCenter)
        let preference = Preference(
            userDefaults: UserDefaults(suiteName: "group.kr.heek.worktime")!
        )

        let googleClientID = "1066855526531-mpbptb2kmdhkclq4sula8r1rofn2dakl.apps.googleusercontent.com"
        let googleProvider = GoogleProvider(plugins: [
            AccessTokenPlugin(tokenClosure: { () in
                return preference.googleUser?.accessToken ?? ""
            })
        ])

        let createWorktimeViewControllerFactory = CreateWorktimeViewController.Factory(dependency: .init())
        let createWorktimeViewReactorFactory = CreateWorktimeViewReactor.Factory(dependency: .init(
            preference: preference,
            userNotificationCenter: userNotificationCenter,
            googleProvider: googleProvider,
            googleClientID: googleClientID
        ))

        return CommonDependency(
            userNotificationCenter: userNotificationCenter,
            notificationService: notificationService,
            preference: preference,
            googleClientID: googleClientID,
            googleProvider: googleProvider,
            createWorktimeViewControllerFactory: createWorktimeViewControllerFactory,
            createWorktimeViewReactorFactory: createWorktimeViewReactorFactory
        )
    }

    static func resolveForUITests() -> CommonDependency {
        let userNotificationCenter = UNUserNotificationCenter.current()
        let notificationService = NotificationService(userNotificationCenter: userNotificationCenter)
        let preference = Preference(
            userDefaults: UserDefaults(suiteName: "group.kr.heek.worktime")!
        )

        let googleClientID = "MOCK-CLIENT-ID"
        let stubGoogleProvider = GoogleProvider(stubClosure: MoyaProvider.immediatelyStub)

        let createWorktimeViewControllerFactory = CreateWorktimeViewController.Factory(dependency: .init())
        let createWorktimeViewReactorFactory = CreateWorktimeViewReactor.Factory(dependency: .init(
            preference: preference,
            userNotificationCenter: userNotificationCenter,
            googleProvider: stubGoogleProvider,
            googleClientID: googleClientID
        ))

        return CommonDependency(
            userNotificationCenter: userNotificationCenter,
            notificationService: notificationService,
            preference: preference,
            googleClientID: googleClientID,
            googleProvider: stubGoogleProvider,
            createWorktimeViewControllerFactory: createWorktimeViewControllerFactory,
            createWorktimeViewReactorFactory: createWorktimeViewReactorFactory
        )
    }
}
