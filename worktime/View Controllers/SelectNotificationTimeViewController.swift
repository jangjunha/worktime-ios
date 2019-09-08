//
//  SelectNotificationTimeViewController.swift
//  worktime
//
//  Created by junha on 2019/09/07.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import Pure
import RxSwift
import SnapKit
import UIKit
import UserNotifications


class SelectNotificationTimeViewController: BaseViewController, FactoryModule {
    struct Dependency {
        let preference: Preference
        let userNotificationCenter: UNUserNotificationCenter
        let notificationService: NotificationService
    }

    struct Payload {}


    // MARK: Constants

    enum Constant {
        static let title = "알림 설정"
        static let description = "매일 평일 선택한 시간에 근무시간 공유 알림이 도착합니다."
        static let receiveNotificationText = "알림 받기"
        static let defaultTime = (9 * 60) + 0
        static let dateCellReuseIdentifier = "dateCell"
    }


    // MARK: Properties

    let preference: Preference
    let userNotificationCenter: UNUserNotificationCenter
    let notificationService: NotificationService


    // MARK: UI

    let tableView = UITableView(frame: .zero, style: .grouped).then {
        $0.bounces = false
    }

    let notificationSwitch = UISwitch(frame: .zero)

    let datePicker = UIDatePicker(frame: .zero).then {
        $0.datePickerMode = .time
    }


    // MARK: Initialize

    required init(dependency: Dependency, payload: Payload) {
        self.preference = dependency.preference
        self.userNotificationCenter = dependency.userNotificationCenter
        self.notificationService = dependency.notificationService

        super.init()

        self.title = Constant.title
        self.tableView.dataSource = self

        self.preference
            .rx.scheduledNotificationTime
            .map { $0 != nil }
            .bind(to: self.notificationSwitch.rx.isOn)
            .disposed(by: self.disposeBag)

        self.preference
            .rx.scheduledNotificationTime
            .map { $0 != nil }
            .bind(to: self.datePicker.rx.isEnabled)
            .disposed(by: self.disposeBag)

        self.preference
            .rx.scheduledNotificationTime
            .map { $0 ?? Constant.defaultTime }
            .map { type(of: self).convertToDate(from: $0) }
            .bind(to: self.datePicker.rx.value)
            .disposed(by: self.disposeBag)

        self.notificationSwitch
            .rx.value
            .skipUntil(self.rx.viewWillAppear)
            .map { $0 ? Constant.defaultTime : nil }
            .bind(to: self.preference.rx.scheduledNotificationTime)
            .disposed(by: self.disposeBag)

        self.datePicker
            .rx.value
            .skipUntil(self.rx.viewWillAppear)
            .map { type(of: self).convertToTime(from: $0) }
            .distinctUntilChanged()
            .do(onNext: { [weak self] time in
                guard let `self` = self else {
                    return
                }

                let weekdays = [2, 3, 4, 5, 6]  // MON - FRI
                let weekdayIdentifierPairs = weekdays
                    .map { (
                        weekday: $0,
                        identifier: String(
                            format: NotificationService.Constant.scheduledNotificationIdentifierFormat,
                            $0
                        )
                    ) }
                self.userNotificationCenter.removePendingNotificationRequests(
                    withIdentifiers: weekdayIdentifierPairs.map { $0.identifier }
                )

                let hour = Int(time / 60)
                let minute = time % 60
                weekdayIdentifierPairs.forEach {
                    let components = DateComponents(
                        calendar: Calendar.current,
                        hour: hour,
                        minute: minute,
                        weekday: $0.weekday
                    )
                    self.notificationService.registerNotification(
                        identifier: $0.identifier,
                        dateMatching: components,
                        repeats: true
                    ) { error in
                        if let error = error {
                            let alertController = UIAlertController(
                                title: "오류",
                                message: "알림을 등록하지 못했습니다. 설정 앱에서 Worktime 앱에 알림 권한이 있는지 확인해주세요.",
                                preferredStyle: .alert
                            )
                            alertController.addAction(.init(
                                title: "닫기",
                                style: .default
                            ))
                            self.present(alertController, animated: true)
                        }
                    }
                }
            })
            .bind(to: self.preference.rx.scheduledNotificationTime)
            .disposed(by: self.disposeBag)
    }

    required convenience init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: View Life Cycle

    override func loadView() {
        self.view = UIView()
        self.view.addSubview(self.tableView)
    }

    override func setupConstraints() {
        self.tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }


    // MARK: Utils

    static func convertToDate(from time: Int) -> Date {
        return Calendar.current.date(
            bySettingHour: Int(time / 60),
            minute: time % 60,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    static func convertToTime(from date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }
}

extension SelectNotificationTimeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(frame: .zero)
        cell.selectionStyle = .none

        switch indexPath {
        case IndexPath(row: 0, section: 0):
            cell.textLabel?.text = Constant.receiveNotificationText
            cell.contentView.addSubview(self.notificationSwitch)
            self.notificationSwitch.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview().inset(16)
            }
        case IndexPath(row: 1, section: 0):
            cell.contentView.addSubview(self.datePicker)
            self.datePicker.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        default:
            assertionFailure("Unhandled cell")
        }

        return cell
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            return Constant.description
        default:
            assertionFailure("Unhandled section")
            return nil
        }
    }
}
