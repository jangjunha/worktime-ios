//
//  Preference.swift
//  worktime
//
//  Created by junha on 2019/09/05.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import Foundation
import KeychainAccess
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
        static let selectedCalendarName = "SELECTED_CALENDAR_NAME"
        static let eventTitle = "EVENT_TITLE"

        static let scheduledNotificationTime = "SCHEDULED_NOTIFICATION_TIME"
    }

    fileprivate let userDefaults: UserDefaults
    fileprivate let keychain: Keychain

    init(userDefaults: UserDefaults, keychain: Keychain) {
        self.userDefaults = userDefaults
        self.keychain = keychain
    }

    fileprivate let googleUserUpdated = BehaviorSubject(value: ())
    var googleUser: GoogleUser? {
        get {
            guard let accessToken = try? self.keychain.get(Key.gidAuthAccessToken),
                  let accessTokenExpirationDate = self.userDefaults.string(
                    forKey: Key.gidAuthAccessTokenExpirationDate
                  )?.date,
                  let refreshToken = try? self.keychain.get(Key.gidAuthRefreshToken),
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
            do {
                try self.updateKeychain(value: newValue?.accessToken, key: Key.gidAuthAccessToken)
                try self.updateKeychain(value: newValue?.refreshToken, key: Key.gidAuthRefreshToken)
            } catch {
                assertionFailure("Failed to update keychain")
            }
            self.userDefaults.set(
                newValue?.accessTokenExpirationDate.isoFormat,
                forKey: Key.gidAuthAccessTokenExpirationDate
            )
            self.userDefaults.set(newValue?.email, forKey: Key.gidProfileEmail)
            self.userDefaults.set(newValue?.name, forKey: Key.gidProfileName)
            self.googleUserUpdated.onNext(())
        }
    }

    var selectedCalendar: CalendarInfo? {
        get {
            guard let id = self.userDefaults.string(forKey: Key.selectedCalendarID),
                  let name = self.userDefaults.string(forKey: Key.selectedCalendarName) else {
                return nil
            }
            return CalendarInfo(id: id, name: name)
        }
        set(newValue) {
            self.userDefaults.set(newValue?.id, forKey: Key.selectedCalendarID)
            self.userDefaults.set(newValue?.name, forKey: Key.selectedCalendarName)
        }
    }

    var eventTitle: String? {
        get {
            return self.userDefaults.string(forKey: Key.eventTitle)
        }
        set(newValue) {
            self.userDefaults.set(newValue, forKey: Key.eventTitle)
        }
    }

    // 0시 0분 0초 부터 초단위 시간
    var scheduledNotificationTime: Int? {
        get {
            return self.userDefaults.object(forKey: Key.scheduledNotificationTime) as? Int
        }
        set(newValue) {
            self.userDefaults.set(newValue, forKey: Key.scheduledNotificationTime)
        }
    }

    private func updateKeychain(value: String?, key: String) throws {
        if let value = value {
            try self.keychain.set(value, key: key)
        } else {
            try self.keychain.remove(key)
        }
    }
}

extension Preference: ReactiveCompatible {}

extension Reactive where Base: Preference {
    var googleUser: ControlProperty<GoogleUser?> {
        let source = self.base.googleUserUpdated
            .map { self.base.googleUser }
        let binder = Binder(self.base) { (base, value) in
            base.googleUser = value
        }
        return ControlProperty(values: source, valueSink: binder)
    }

    var selectedCalendar: ControlProperty<CalendarInfo?> {
        let source = Observable.combineLatest(
            self.base.userDefaults.rx.observe(String.self, Preference.Key.selectedCalendarID),
            self.base.userDefaults.rx.observe(String.self, Preference.Key.selectedCalendarName)
        ).map { _ in self.base.selectedCalendar }
        let binder = Binder(self.base) { (base, value) in
            base.selectedCalendar = value
        }
        return ControlProperty(values: source, valueSink: binder)
    }

    var eventTitle: ControlProperty<String?> {
        let source = self.base.userDefaults.rx.observe(String.self, Preference.Key.eventTitle)
        let binder = Binder(self.base) { (base, value) in
            base.eventTitle = value
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

struct CalendarInfo {
    let id: String
    let name: String
}
