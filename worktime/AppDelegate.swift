//
//  AppDelegate.swift
//  worktime
//
//  Created by junha on 26/07/2019.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import GoogleSignIn
import UIKit
import UserNotifications


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // MARK: Properties

    let dependency: AppDependency


    // MARK: UI

    var window: UIWindow?


    // MARK: Initialize

    override init() {
        if CommandLine.arguments.contains("-UITests") {
            print("Running UI test")
            UserDefaults.standard.removePersistentDomain(forName: "group.kr.heek.worktime")
            self.dependency = AppDependency.resolveForUITests()
        } else {
            self.dependency = AppDependency.resolve()
        }
        super.init()
    }


    // MARK: UIApplicationDelegate

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        self.dependency.userNotificationCenter.delegate = self

        let settingsViewController = self.dependency.settingsViewControllerFactory.create(payload: .init())
        let navigationController = UINavigationController(rootViewController: settingsViewController).then {
            $0.view.backgroundColor = UIColor.compat.systemBackground
        }

        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = navigationController
        self.window?.makeKeyAndVisible()
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        if GIDSignIn.sharedInstance().handle(url) {
            return true
        }
        return false
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.alert, .badge, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        guard let topViewController = UIApplication.shared.keyWindow?.rootViewController else {
            completionHandler()
            return
        }

        switch response.notification.request.content.categoryIdentifier {
        case "worktimeAlert":
            let createWorktimeViewController = self.dependency.scrollableCreateWorktimeViewControllerFactory.create(
                payload: .init()
            )
            let navigationController = UINavigationController(rootViewController: createWorktimeViewController)
            topViewController.present(navigationController, animated: true)
        default:
            break
        }

        completionHandler()
    }
}
