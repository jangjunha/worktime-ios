//
//  ScrollableCreateWorktimeViewController.swift
//  worktime
//
//  Created by junha on 2019/12/01.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import Pure
import UIKit

class ScrollableCreateWorktimeViewController: BaseViewController, FactoryModule {
    struct Dependency {
        let preference: Preference
        let timeService: TimeServiceType
        let createWorktimeViewControllerFactory: CreateWorktimeViewController.Factory
        let createWorktimeViewReactorFactory: CreateWorktimeViewReactor.Factory
    }

    struct Payload {}


    // MARK: UI

    let scrollView = UIScrollView()

    let contentView = UIView().then {
        $0.backgroundColor = .orange
    }

    lazy var createWorktimeViewController: CreateWorktimeViewController = {
        let viewController = self.createWorktimeViewControllerFactory.create(payload: .init(
            reactor: self.createWorktimeViewReactorFactory.create(payload: .init(
                dayBefore: self.dayBefore
            ))
        ))
        viewController.delegate = self
        return viewController
    }()

    let closeButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)


    // MARK: Properties

    lazy var dayBefore: Int = {
        let now = self.timeService.now()
        let calendar = Calendar.current
        let hour = calendar.dateComponents([.hour], from: now).hour ?? 0
        return hour <= self.preference.dateSeparatorHour ? 0 : 1
    }()

    let preference: Preference
    let timeService: TimeServiceType

    let createWorktimeViewControllerFactory: CreateWorktimeViewController.Factory
    let createWorktimeViewReactorFactory: CreateWorktimeViewReactor.Factory


    // MARK: Initialize

    required init(dependency: Dependency, payload: Payload) {
        self.preference = dependency.preference
        self.timeService = dependency.timeService
        self.createWorktimeViewControllerFactory = dependency.createWorktimeViewControllerFactory
        self.createWorktimeViewReactorFactory = dependency.createWorktimeViewReactorFactory

        super.init()

        self.closeButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.navigationController?.dismiss(animated: true)
        }).disposed(by: self.disposeBag)
    }

    required convenience init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: View Life Cycle

    override func loadView() {
        self.view = UIView()
        self.view.backgroundColor = UIColor.compat.systemBackground
        self.view.addSubview(self.scrollView)
        self.scrollView.addSubview(self.contentView)
        self.contentView.addSubview(self.createWorktimeViewController.view)
    }

    override func setupConstraints() {
        self.scrollView.snp.makeConstraints { make in
            make.edges.equalTo(self.view.safeAreaLayoutGuide)
        }
        self.contentView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().priority(.high)
            make.width.equalToSuperview()
            make.height.greaterThanOrEqualTo(self.scrollView)
        }
        self.createWorktimeViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func viewDidLoad() {
        self.view.updateConstraintsIfNeeded()

        self.addChild(self.createWorktimeViewController)
        self.createWorktimeViewController.didMove(toParent: self)

        self.navigationItem.leftBarButtonItem = self.closeButton
    }
}

extension ScrollableCreateWorktimeViewController: CreateWorktimeViewDelegate {
    func createWorktimeViewShouldDismiss() {
        self.navigationController?.dismiss(animated: true)
        self.dismiss(animated: true)
    }
}
