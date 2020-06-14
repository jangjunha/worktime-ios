//
//  SelectCalendarViewController.swift
//  worktime
//
//  Created by junha on 2019/09/05.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import Pure
import RxSwift
import RxSwiftExt
import RxDataSources
import RxViewController
import SnapKit
import UIKit


class SelectCalendarViewController: BaseViewController, FactoryModule {
    struct Dependency {
        let preference: Preference
        let googleProvider: GoogleProvider
    }

    struct Payload {}


    // MARK: Constants

    enum Constant {
        static let title = "캘린더 선택"
        static let calendarCellIdentifier = "calendarCell"
    }


    // MARK: Properties

    let preference: Preference

    let googleProvider: GoogleProvider


    // MARK: UI

    let tableView = UITableView(frame: .zero, style: .grouped).then {
        $0.register(UITableViewCell.self, forCellReuseIdentifier: Constant.calendarCellIdentifier)
    }

    let loadingView = UIActivityIndicatorView(style: .whiteLarge).then {
        $0.color = UIColor.compat.systemGray
        $0.startAnimating()
    }


    // MARK: Initialize

    required init(dependency: Dependency, payload: Payload) {
        self.preference = dependency.preference
        self.googleProvider = dependency.googleProvider

        super.init()

        self.title = Constant.title

        let listCalendars = self.googleProvider.rx
            .request(.userCalendarList)
            .map(CalendarList.self)
            .map { $0.items }
            .asDriver(onErrorJustReturn: [])

        Observable.combineLatest(
            self.rx.viewDidLoad.flatMap { _ in listCalendars },
            self.preference.rx.selectedCalendar
        ) { calendars, _ in calendars }
            .bind(to: self.tableView.rx.items(
                cellIdentifier: Constant.calendarCellIdentifier
            )) { [weak self] _, model, cell in
                guard let `self` = self else {
                    return
                }
                cell.textLabel?.text = model.summary
                cell.accessoryType = model.id == self.preference.selectedCalendar?.id ? .checkmark : .none
            }
            .disposed(by: self.disposeBag)

        listCalendars
            .mapTo(true)
            .startWith(false)
            .drive(self.loadingView.rx.isHidden)
            .disposed(by: self.disposeBag)

        self.tableView.rx.modelSelected(CalendarListEntry.self)
            .map { CalendarInfo(id: $0.id, name: $0.summary) }
            .bind(to: self.preference.rx.selectedCalendar)
            .disposed(by: self.disposeBag)
    }

    required convenience init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: View Life Cycle

    override func loadView() {
        self.view = UIView()
        self.view.backgroundColor = UIColor.compat.systemBackground
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.loadingView)
    }

    override func setupConstraints() {
        self.tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.loadingView.snp.makeConstraints { make in
            make.center.equalTo(self.view.safeAreaLayoutGuide)
        }
    }
}
