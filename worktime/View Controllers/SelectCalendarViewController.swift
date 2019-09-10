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
        $0.color = .gray
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
            self.preference.rx.selectedCalendarID
        ) { calendars, _ in calendars }
            .bind(to: self.tableView.rx.items(
                cellIdentifier: Constant.calendarCellIdentifier
            )) { _, model, cell in
                cell.textLabel?.text = model.summary
                cell.accessoryType = model.id == self.preference.selectedCalendarID ? .checkmark : .none
            }
            .disposed(by: self.disposeBag)

        listCalendars
            .mapTo(true)
            .startWith(false)
            .drive(self.loadingView.rx.isHidden)
            .disposed(by: self.disposeBag)

        self.tableView.rx.modelSelected(CalendarListEntry.self)
            .map { $0.id }
            .bind(to: self.preference.rx.selectedCalendarID)
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