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


    // MARK: Types

    enum Weekday: Int, CaseIterable {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7

        var notificationIdentifier: String {
            return String(
                format: NotificationService.Constant.scheduledNotificationIdentifierFormat,
                self.rawValue
            )
        }

        static let weekdays: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday]

        static func + (left: Weekday, right: Int) -> Weekday {
            var raw = (left.rawValue - 1 + right) % Weekday.allCases.count + 1
            raw = raw > 0 ? raw : raw + Weekday.allCases.count
            return Weekday(rawValue: raw)!
        }

        static func - (left: Weekday, right: Int) -> Weekday {
            return left + (-right)
        }
    }


    // MARK: Constants

    enum Constant {
        static let title = "알림 설정"
        static let buildDescription = { (time: Int?, dayBefore: Int) -> String in
            guard let time = time else {
                return "근무시간 공유 알림을 받지 않습니다."
            }
            let dateDescription: String?
            switch dayBefore {
            case 0:
                dateDescription = "매 근무일"
            case 1:
                dateDescription = "매 근무일 전날"
            default:
                dateDescription = nil
            }
            return [
                dateDescription,
                "\(Int(time / 60))시 \(time % 60)분에",
                "근무시간 공유 알림이 도착합니다."
            ]
                .compactMap { $0}
                .joined(separator: " ")
        }
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

    let switchCell = UITableViewCell().then {
        $0.textLabel?.text = Constant.receiveNotificationText
        $0.selectionStyle = .none
    }

    let pickerCell = UITableViewCell().then {
        $0.selectionStyle = .none
    }

    let notificationSwitch = UISwitch(frame: .zero)

    let dayPicker = UIPickerView(frame: .zero)

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

        let notifiedBeforeValues = [1, 0]

        Observable.just(notifiedBeforeValues)
            .bind(to: self.dayPicker.rx.items) { _, item, _ in
                UILabel().then {
                    $0.text = item == 0 ? "당일" : "\(item)일 전"
                    $0.textAlignment = .right
                    $0.font = .preferredFont(forTextStyle: .title2)
                }
            }
            .disposed(by: self.disposeBag)

        self.preference
            .rx.scheduledNotificationTime
            .map { $0 != nil }
            .bind(to: self.notificationSwitch.rx.isOn)
            .disposed(by: self.disposeBag)

        let notificationEnabled = self.preference
            .rx.scheduledNotificationTime
            .map { $0 != nil }

        notificationEnabled
            .bind(to: self.datePicker.rx.isEnabled)
            .disposed(by: self.disposeBag)

        notificationEnabled
            .subscribe(onNext: { [weak self] isEnabled in
                guard let `self` = self else {
                    return
                }
                self.dayPicker.isUserInteractionEnabled = isEnabled
                self.dayPicker.alpha = isEnabled ? 1 : 0.5
            })
            .disposed(by: self.disposeBag)

        self.preference
            .rx.scheduledNotificationTime
            .map { $0 ?? Constant.defaultTime }
            .map { type(of: self).convertToDate(from: $0) }
            .bind(to: self.datePicker.rx.value)
            .disposed(by: self.disposeBag)

        self.preference
            .rx.notifiedBefore
            .subscribe(onNext: { [weak self] item in
                self?.dayPicker.selectRow(
                    notifiedBeforeValues.firstIndex(of: item ?? 0) ?? 0,
                    inComponent: 0,
                    animated: false
                )
            })
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
            .bind(to: self.preference.rx.scheduledNotificationTime)
            .disposed(by: self.disposeBag)

        self.dayPicker
            .rx.modelSelected(Int.self)
            .map { items in
                assert(items.count == 1, "Expected number of items is 1")
                return items[0]
            }
            .bind(to: self.preference.rx.notifiedBefore)
            .disposed(by: self.disposeBag)

        Observable.combineLatest(
            self.preference.rx.scheduledNotificationTime,
            self.preference.rx.notifiedBefore
                .map { $0 ?? 0 }
        )
            .skipUntil(self.rx.viewDidAppear)
            .do(onNext: { [weak self] _ in self?.tableView.reloadData() })
            .subscribe(onNext: { [weak self] time, notifiedBefore in
                guard let `self` = self else {
                    return
                }

                self.userNotificationCenter.removePendingNotificationRequests(
                    withIdentifiers: Weekday.allCases.map { $0.notificationIdentifier }
                )

                guard let time = time else {
                    return
                }

                let hour = Int(time / 60)
                let minute = time % 60
                Weekday.weekdays
                    .map { $0 - notifiedBefore }
                    .forEach { weekday in
                        let components = DateComponents(
                            calendar: Calendar.current,
                            hour: hour,
                            minute: minute,
                            weekday: weekday.rawValue
                        )
                        self.notificationService.registerNotification(
                            identifier: weekday.notificationIdentifier,
                            dateMatching: components,
                            repeats: true,
                            presentingViewController: self
                        ) { error in
                            guard error == nil else {
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
                                return
                            }
                        }
                    }
            })
            .disposed(by: self.disposeBag)
    }

    required convenience init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: View Life Cycle

    override func loadView() {
        self.view = UIView()
        self.view.addSubview(self.tableView)

        self.switchCell.contentView.addSubview(self.notificationSwitch)
        self.pickerCell.contentView.addSubview(self.dayPicker)
        self.pickerCell.contentView.addSubview(self.datePicker)
    }

    override func setupConstraints() {
        self.tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.notificationSwitch.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
        }
        self.dayPicker.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
        }
        self.datePicker.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
            make.leading.equalTo(self.dayPicker.snp.trailing)
            make.width.equalTo(self.dayPicker.snp.width).multipliedBy(3)
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
        switch indexPath {
        case IndexPath(row: 0, section: 0):
            return self.switchCell
        case IndexPath(row: 1, section: 0):
            return self.pickerCell
        default:
            assertionFailure("Unhandled cell")
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            return Constant.buildDescription(
                self.preference.scheduledNotificationTime,
                self.preference.notifiedBefore ?? 0
            )
        default:
            assertionFailure("Unhandled section")
            return nil
        }
    }
}
