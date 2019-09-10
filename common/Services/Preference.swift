//
//  Preference.swift
//  worktime
//
//  Created by junha on 2019/09/05.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa


class Preference {
    enum Key {
        static let gidAuthAccessToken = "GID_AUTH_ACCESS_TOKEN"
        static let gidAuthAccessTokenExpirationDate = "GID_AUTH_ACCESS_TOKEN_EXPIRATION_DATE"
        static let gidAuthRefreshToken = "GID_AUTH_REFRESH_TOKEN"
        static let gidProfileEmail = "GID_PROFILE_EMAIL"
        static let gidProfileName = "GID_PROFILE_NAME"

        static let selectedCalendarID = "SELECTED_CALENDAR_ID"

        static let scheduledNotificationTime = "SCHEDULED_NOTIFICATION_TIME"
    }

    fileprivate let userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    var googleUser: GoogleUser? {
        get {
            guard let accessToken = self.userDefaults.string(forKey: Key.gidAuthAccessToken),
                  let accessTokenExpirationDate = self.userDefaults.string(
                    forKey: Key.gidAuthAccessTokenExpirationDate
                  )?.date,
                  let refreshToken = self.userDefaults.string(forKey: Key.gidAuthRefreshToken),
                  let email = self.userDefaults.string(forKey: Key.gidProfileEmail),
                  let name = self.userDefaults.string(forKey: Key.gidProfileName) else {
                return nil
            }
            return GoogleUser(
                accessToken: accessToken,
                accessTokenExpirationDate: accessTokenExpirationDate,
                refreshToken: refreshToken,
                email: email,
                name: name
            )
        }
        set(newValue) {
            self.userDefaults.set(newValue?.accessToken, forKey: Key.gidAuthAccessToken)
            self.userDefaults.set(
                newValue?.accessTokenExpirationDate.isoFormat,
                forKey: Key.gidAuthAccessTokenExpirationDate
            )
            self.userDefaults.set(newValue?.refreshToken, forKey: Key.gidAuthRefreshToken)
            self.userDefaults.set(newValue?.email, forKey: Key.gidProfileEmail)
            self.userDefaults.set(newValue?.name, forKey: Key.gidProfileName)
        }
    }

    var selectedCalendarID: String? {
        get {
            return self.userDefaults.string(forKey: Key.selectedCalendarID)
        }
        set(newValue) {
            self.userDefaults.set(newValue, forKey: Key.selectedCalendarID)
        }
    }

    // 0시 0분 0초 부터 초단위 시간
    var scheduledNotificationTime: Int? {
        get {
            return self.userDefaults.integer(forKey: Key.scheduledNotificationTime)
        }
        set(newValue) {
            self.userDefaults.set(newValue, forKey: Key.scheduledNotificationTime)
        }
    }
}

extension Preference: ReactiveCompatible {}

extension Reactive where Base: Preference {
    var googleUser: ControlProperty<GoogleUser?> {
        let source = Observable.combineLatest(
            self.base.userDefaults.rx.observe(String.self, Preference.Key.gidAuthAccessToken),
            self.base.userDefaults.rx.observe(String.self, Preference.Key.gidAuthAccessTokenExpirationDate),
            self.base.userDefaults.rx.observe(String.self, Preference.Key.gidAuthRefreshToken),
            self.base.userDefaults.rx.observe(String.self, Preference.Key.gidProfileEmail),
            self.base.userDefaults.rx.observe(String.self, Preference.Key.gidProfileName)
        ).map { accessToken, accessTokenExpirationDate, refreshToken, email, name -> GoogleUser? in
            guard let accessToken = accessToken,
                  let accessTokenExpirationDate = accessTokenExpirationDate?.date,
                  let refreshToken = refreshToken,
                  let email = email,
                  let name = name else {
                return nil
            }
            return GoogleUser(
                accessToken: accessToken,
                accessTokenExpirationDate: accessTokenExpirationDate,
                refreshToken: refreshToken,
                email: email,
                name: name
            )
        }
        let binder = Binder(self.base) { (base, value) in
            base.googleUser = value
        }
        return ControlProperty(values: source, valueSink: binder)
    }

    var selectedCalendarID: ControlProperty<String?> {
        let source = self.base.userDefaults.rx.observe(String.self, Preference.Key.selectedCalendarID)
        let binder = Binder(self.base) { (base, value) in
            base.selectedCalendarID = value
        }
        return ControlProperty(values: source, valueSink: binder)
    }

    var scheduledNotificationTime: ControlProperty<Int?> {
        let source = self.base.userDefaults.rx.observe(Int.self, Preference.Key.scheduledNotificationTime)
        let binder = Binder(self.base) { (base, value) in
            base.scheduledNotificationTime = value
        }
        return ControlProperty(values: source, valueSink: binder)
    }
}


// MARK: Entities

struct GoogleUser {
    let accessToken: String
    let accessTokenExpirationDate: Date
    let refreshToken: String
    let email: String
    let name: String
}
