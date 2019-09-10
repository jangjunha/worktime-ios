//
//  SettingsViewController.swift
//  worktime
//
//  Created by junha on 2019/09/07.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import GoogleSignIn
import Pure
import RxSwift
import RxDataSources
import SnapKit
import Then
import UIKit
import UserNotifications


class SettingsViewController: BaseViewController, FactoryModule {
    struct Dependency {
        let preference: Preference
        let userNotificationCenter: UNUserNotificationCenter
        let notificationService: NotificationService
        let googleLoginService: GoogleLoginServiceType

        let selectCalendarViewControllerFactory: SelectCalendarViewController.Factory
        let selectNotificationTimeViewControllerFactory: SelectNotificationTimeViewController.Factory
    }

    struct Payload {}


    // MARK: Constants

    enum Constant {
        static let title = "근무시간"
    }


    // MARK: Properties

    let preference: Preference
    let userNotificationCenter: UNUserNotificationCenter
    let notificationService: NotificationService
    let googleLoginService: GoogleLoginServiceType
    let selectCalendarViewControllerFactory: SelectCalendarViewController.Factory
    let selectNotificationTimeViewControllerFactory: SelectNotificationTimeViewController.Factory


    // MARK: UI

    let tableView = UITableView(frame: .zero, style: .grouped)

    let profileCell = UITableViewCell().then {
        $0.selectionStyle = .none
    }
    let signinCell = UITableViewCell().then {
        $0.textLabel?.text = "로그인"
        $0.textLabel?.textColor = .blue
    }
    let signoutCell = UITableViewCell().then {
        $0.textLabel?.text = "로그아웃"
        $0.textLabel?.textColor = .red
    }
    let selectCalendarCell = UITableViewCell().then {
        $0.textLabel?.text = "캘린더를 선택하세요"
        $0.accessoryType = .disclosureIndicator
    }
    let selectedCalendarCell = UITableViewCell().then {
        $0.accessoryType = .disclosureIndicator
    }
    let notificationScheduleCell = UITableViewCell(style: .value1, reuseIdentifier: nil).then {
        $0.textLabel?.text = "알림 시각"
        $0.accessoryType = .disclosureIndicator
    }
    let notifyNowCell = UITableViewCell().then {
        $0.textLabel?.text = "지금 알림 받아보기"
    }


    // MARK: Initialize

    required init(dependency: Dependency, payload: Payload) {
        self.preference = dependency.preference
        self.userNotificationCenter = dependency.userNotificationCenter
        self.notificationService = dependency.notificationService
        self.googleLoginService = dependency.googleLoginService
        self.selectCalendarViewControllerFactory = dependency.selectCalendarViewControllerFactory
        self.selectNotificationTimeViewControllerFactory = dependency.selectNotificationTimeViewControllerFactory

        super.init()

        self.title = Constant.title

        let dataSource = RxTableViewSectionedReloadDataSource<SettingsTableSectionModel>(
            configureCell: { _, _, _, row in
                switch row {
                case let .profile(user):
                    let cell = self.profileCell
                    cell.textLabel?.text = "\(user.name)(\(user.email))"
                    return cell
                case .signinButton:
                    return self.signinCell
                case .signoutButton:
                    return self.signoutCell
                case let .selectCalendar(isEnabled):
                    let cell = self.selectCalendarCell
                    cell.textLabel?.textColor = isEnabled ? .blue : .lightGray
                    cell.selectionStyle = isEnabled ? .default : .none
                    return cell
                case let .selectedCalendar(calendarID):
                    let cell = self.selectedCalendarCell
                    cell.textLabel?.text = calendarID
                    return cell
                case let .notification(time, isEnabled):
                    let cell = self.notificationScheduleCell
                    cell.textLabel?.textColor = isEnabled ? .black : .lightGray
                    cell.detailTextLabel?.text = { time in
                        guard let time = time else {
                            return "꺼짐"
                        }
                        return String(format: "평일 %02d:%02d", Int(time / 60), time % 60)
                    }(time)
                    cell.selectionStyle = isEnabled ? .default : .none
                    return cell
                case let .notifyNow(isEnabled):
                    let cell = self.notifyNowCell
                    cell.textLabel?.textColor = isEnabled ? .black : .lightGray
                    cell.selectionStyle = isEnabled ? .default : .none
                    return cell
                }
            },
            titleForHeaderInSection: { dataSource, index in
                return dataSource.sectionModels[index].title
            }
        )

        let accountSection = self.preference
            .rx.googleUser
            .map { user -> [SettingsTableRow] in
                guard let user = user else {
                    return [.signinButton]
                }
                return [
                    .profile(user: user),
                    .signoutButton
                ]
            }
            .map { SettingsTableSectionModel(title: "연결된 계정", items: $0) }

        let selectedCalendarSection = Observable.combineLatest(
            self.preference.rx.selectedCalendarID,
            self.preference.rx.googleUser
        )
            .map { id, user -> [SettingsTableRow] in
                guard let id = id else {
                    return [.selectCalendar(isEnabled: user != nil)]
                }
                return [.selectedCalendar(calendarID: id)]
            }
            .map { SettingsTableSectionModel(title: "캘린더", items: $0) }

        let notificationSection = Observable.combineLatest(
            self.preference.rx.scheduledNotificationTime,
            self.preference.rx.selectedCalendarID,
            self.preference.rx.googleUser
        )
            .map { time, calendarID, user in (
                time: time,
                isEnabled: calendarID != nil && user != nil
            ) }
            .map { a -> [SettingsTableRow] in
                let (time, isEnabled) = a
                return [
                    .notification(time: time, isEnabled: isEnabled),
                    .notifyNow(isEnabled: isEnabled)
                ]
            }
            .map { SettingsTableSectionModel(title: "알림", items: $0) }

        Observable.combineLatest(
            accountSection,
            selectedCalendarSection,
            notificationSection
        )
            .map { [$0, $1, $2] }
            .bind(to: self.tableView.rx.items(dataSource: dataSource))
            .disposed(by: self.disposeBag)

        self.tableView
            .rx.modelSelected(SettingsTableRow.self)
            .subscribe(onNext: { [weak self] row in
                guard let `self` = self else {
                    return
                }
                switch row {
                case .signinButton:
                    self.googleLoginService.signIn()
                case .signoutButton:
                    self.preference.googleUser = nil
                    self.preference.selectedCalendarID = nil
                    self.preference.scheduledNotificationTime = nil
                    self.googleLoginService.signOut()
                case .selectCalendar(isEnabled: true),
                     .selectedCalendar:
                    let viewController = self.selectCalendarViewControllerFactory.create(payload: .init())
                    self.navigationController?.pushViewController(viewController, animated: true)
                case .notification(_, isEnabled: true):
                    let viewController = self.selectNotificationTimeViewControllerFactory.create(payload: .init())
                    self.navigationController?.pushViewController(viewController, animated: true)
                case .notifyNow(isEnabled: true):
                    let components = Calendar.current.dateComponents([.nanosecond], from: Date())
                    self.notificationService.registerNotification(
                        identifier: UUID().uuidString,
                        dateMatching: components,
                        repeats: false
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
                case .selectCalendar(isEnabled: false),
                     .notification(_, isEnabled: false),
                     .notifyNow(isEnabled: false),
                     .profile:
                    break
                }
            })
            .disposed(by: self.disposeBag)

        self.rx.viewDidLoad
            .subscribe(onNext: { [weak self] in
                guard let `self` = self else {
                    return
                }

                self.googleLoginService.presentingViewController = self

                self.userNotificationCenter.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
                    guard granted, error == nil else {
                        let alertController = UIAlertController(
                            title: "알림 설정",
                            message: "나중에 권한을 부여하려면 설정 앱에서 알림을 허용해주세요.",
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

                let category = UNNotificationCategory(
                    identifier: NotificationService.Constant.categoryIdentifier,
                    actions: [],
                    intentIdentifiers: [],
                    options: []
                )
                self.userNotificationCenter.setNotificationCategories([category])
            })
            .disposed(by: self.disposeBag)

        self.tableView
            .rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: self.disposeBag)
    }

    required convenience init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: View Life Cycle

    override func loadView() {
        self.view = UIView()
        self.view.backgroundColor = .white
        self.view.addSubview(self.tableView)
    }

    override func setupConstraints() {
        self.tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.eventTitleField.snp.makeConstraints { make in
            make.edges.equalTo(self.eventTitleCell.snp.margins)
        }
    }
}

enum SettingsTableRow {
    // Account
    case profile(user: GoogleUser)
    case signinButton
    case signoutButton

    // Calendar
    case selectCalendar(isEnabled: Bool)
    case selectedCalendar(calendarID: String)

    // Notification
    case notification(time: Int?, isEnabled: Bool)
    case notifyNow(isEnabled: Bool)
}

struct SettingsTableSectionModel {
    var title: String?
    var items: [Item]
}

extension SettingsTableSectionModel: SectionModelType {
    typealias Item = SettingsTableRow

    init(original: SettingsTableSectionModel, items: [Item]) {
        self = original
        self.items = items
    }
}
