//
//  GoogleLoginService.swift
//  worktime
//
//  Created by junha on 2019/09/08.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import GoogleSignIn

final class GoogleLoginService: NSObject, GoogleLoginServiceType {
    fileprivate let gidSignIn: GIDSignIn
    fileprivate let preference: Preference

    var presentingViewController: UIViewController? {
        get {
            return self.gidSignIn.presentingViewController
        }
        set(newValue) {
            self.gidSignIn.presentingViewController = newValue
        }
    }

    init(gidSignIn: GIDSignIn, preference: Preference) {
        self.gidSignIn = gidSignIn
        self.preference = preference

        super.init()

        self.gidSignIn.delegate = self
        self.gidSignIn.restorePreviousSignIn()
    }

    func signIn() {
        self.gidSignIn.signIn()
    }

    func signOut() {
        self.gidSignIn.signOut()
    }
}

extension GoogleLoginService: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
                print("The user has not signed in before or they have since signed out.")
            } else {
                print("\(error.localizedDescription)")
            }
            return
        }
        print("signed in. exp date: \(user.authentication.accessTokenExpirationDate)")
        self.preference.googleUser = GoogleUser(
            accessToken: user.authentication.accessToken,
            accessTokenExpirationDate: user.authentication.accessTokenExpirationDate,
            refreshToken: user.authentication.refreshToken,
            email: user.profile.email,
            name: user.profile.name
        )
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print("\(error.localizedDescription)")
            return
        }
        self.preference.googleUser = nil
        self.preference.selectedCalendarID = nil
        self.preference.scheduledNotificationTime = nil
    }
}
