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
        static let preferenceVersion = "PREFERENCE_VERSION"

        static let gidAuthAccessToken = "GID_AUTH_ACCESS_TOKEN"
        static let gidAuthAccessTokenExpirationDate = "GID_AUTH_ACCESS_TOKEN_EXPIRATION_DATE"
        static let gidAuthRefreshToken = "GID_AUTH_REFRESH_TOKEN"
        static let gidProfileEmail = "GID_PROFILE_EMAIL"
        static let gidProfileName = "GID_PROFILE_NAME"

        static let selectedCalendarID = "SELECTED_CALENDAR_ID"
        static let selectedCalendarName = "SELECTED_CALENDAR_NAME"
        static let eventTitle = "EVENT_TITLE"

        static let scheduledNotificationTime = "SCHEDULED_NOTIFICATION_TIME"
        static let notifiedBefore = "NOTIFIED_BEFORE"
    }

    fileprivate let userDefaults: UserDefaults
    fileprivate let keychain: Keychain

    init(userDefaults: UserDefaults, keychain: Keychain) {
        self.userDefaults = userDefaults
        self.keychain = keychain

        self.migrate()
    }

    private var version: Int {
        get {
            return self.userDefaults.integer(forKey: Key.preferenceVersion)  // Defaults 0
        }
        set(newValue) {
            self.userDefaults.set(newValue, forKey: Key.preferenceVersion)
        }
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

    // N일 전에 알림 보내기 (= N일 후 일정으로 등록)
    var notifiedBefore: Int? {
        get {
            return self.userDefaults.object(forKey: Key.notifiedBefore) as? Int
        }
        set(newValue) {
            self.userDefaults.set(newValue, forKey: Key.notifiedBefore)
        }
    }

    private func updateKeychain(value: String?, key: String) throws {
        if let value = value {
            try self.keychain.set(value, key: key)
        } else {
            try self.keychain.remove(key)
        }
    }

    private func migrate() {
        // WARN: Please update latest version when new revision added
        let latestVersion = 2

        let isV1 = self.userDefaults.string(forKey: "GID_AUTH_ACCESS_TOKEN") != nil
        if self.version == 0, !isV1 {
            self.version = latestVersion
        }

        // WARN: Please note the order of migrations
        if self.version < 2 {
            try? self.updateKeychain(
                value: self.userDefaults.string(forKey: "GID_AUTH_ACCESS_TOKEN"),
                key: "GID_AUTH_ACCESS_TOKEN"
            )
            try? self.updateKeychain(
                value: self.userDefaults.string(forKey: "GID_AUTH_REFRESH_TOKEN"),
                key: "GID_AUTH_REFRESH_TOKEN"
            )
            self.userDefaults.removeObject(forKey: "GID_AUTH_ACCESS_TOKEN")
            self.userDefaults.removeObject(forKey: "GID_AUTH_REFRESH_TOKEN")
            self.version = 2
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

    var notifiedBefore: ControlProperty<Int?> {
        let source = self.base.userDefaults.rx.observe(Int.self, Preference.Key.notifiedBefore)
        let binder = Binder(self.base) { (base, value) in
            base.notifiedBefore = value
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
