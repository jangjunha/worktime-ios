//
//  CreateWorktimeViewController.swift
//  worktime-noti-content
//
//  Created by junha on 2019/09/08.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import ReactorKit
import RxCocoa
import RxSwift
import RxViewController
import Pure
import SnapKit
import Then
import UIKit

class CreateWorktimeViewController: BaseViewController, View, FactoryModule {
    struct Dependency {}

    struct Payload {
        let reactor: CreateWorktimeViewReactor
    }


    // MARK: Constants

    enum Metric {
        static let margins = UIEdgeInsets(top: 16, left: 12, bottom: 12, right: 12)
        static let titleBottomMargin: CGFloat = 16
        static let stackViewSpacing: CGFloat = 8
        static let buttonContentEdgeInsets = UIEdgeInsets(top: 14, left: 8, bottom: 14, right: 8)
        static let buttonCornerRadius: CGFloat = 12
        static let buttonBorderWidth: CGFloat = 1
    }

    enum Font {
    }

    enum Color {
        static let buttonBackground = UIColor(red: 0x22 / 255.0, green: 0x8B / 255.0, blue: 0xE6 / 255.0, alpha: 1.0)
        static let buttonBackgroundLight: UIColor = .white
        static let buttonBorderLight = Color.buttonBackground
        static let title: UIColor = .white
        static let titleHighlighted = UIColor.white.darken(by: 0.1)
        static let titleLight: UIColor = Color.buttonBackground
        static let titleLightHighlighted = Color.buttonBackground.darken(by: 0.1)
    }


    // MARK: UI

    let titleLabel = UILabel().then {
        $0.numberOfLines = 0
    }

    let stackView = UIStackView(frame: .zero).then {
        $0.alignment = .fill
        $0.axis = .vertical
        $0.spacing = Metric.stackViewSpacing
    }


    // MARK: Properties

    weak var delegate: CreateWorktimeViewDelegate?

    public var notificationIdentifier: String? {
        didSet {
            self.reactor?.notificationIdentifier = self.notificationIdentifier
        }
    }


    // MARK: Initialize

    required init(dependency: Dependency, payload: Payload) {
        super.init()

        self.reactor = payload.reactor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }


    // MARK: View Life Cycle

    override func loadView() {
        self.view = UIView()
        self.view.layoutMargins = Metric.margins
        self.view.backgroundColor = .white

        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.stackView)
    }

    override func setupConstraints() {
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.view.snp.topMargin)
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualTo(self.view.snp.leftMargin)
            make.right.lessThanOrEqualTo(self.view.snp.rightMargin)
        }

        self.stackView.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(Metric.titleBottomMargin)
            make.bottom.lessThanOrEqualTo(self.view.snp.bottomMargin)
            make.leading.equalTo(self.view.snp.leadingMargin)
            make.trailing.equalTo(self.view.snp.trailingMargin)
        }
    }


    // MARK: Configure

    func bind(reactor: CreateWorktimeViewReactor) {
        reactor.state
            .map { $0.title }
            .bind(to: self.titleLabel.rx.text)
            .disposed(by: self.disposeBag)

        reactor.state
            .map { $0.buttons }
            .distinctUntilChanged { prevList, nextList in
                guard prevList.count == nextList.count else {
                    return false
                }
                return zip(prevList, nextList).allSatisfy { a, b in a == b }
            }
            .subscribe(onNext: { [weak self, weak reactor] items in
                guard let `self` = self, let reactor = reactor else {
                    return
                }
                let buttons = items
                    .map { item -> UIButton in
                        let button = type(of: self).buildTimeButton(
                            beginTime: item.beginDate,
                            endTime: item.endDate,
                            style: item.style
                        )
                        reactor.state.map { !$0.isLoading }
                            .distinctUntilChanged()
                            .bind(to: button.rx.isEnabled)
                            .disposed(by: self.disposeBag)
                        reactor.state.map { !$0.isLoading }
                            .map { CGFloat($0 ? 1.0 : 0.5) }
                            .bind(to: button.rx.alpha)
                            .disposed(by: self.disposeBag)
                        button.rx.tap
                            .map { Reactor.Action.selectTimes(item.beginDate, item.endDate) }
                            .bind(to: reactor.action)
                            .disposed(by: self.disposeBag)
                        return button
                }
                self.stackView.arrangedSubviews.forEach {
                    $0.removeFromSuperview()
                }
                buttons.forEach(self.stackView.addArrangedSubview)
            })
            .disposed(by: self.disposeBag)

        reactor.state
            .map { $0.shouldDismiss }
            .filter { $0 }
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.createWorktimeViewShouldDismiss()
                self?.navigationController?.dismiss(animated: true)
                self?.dismiss(animated: true)
            })
            .disposed(by: self.disposeBag)

        self.rx.viewDidLoad
            .map { Reactor.Action.refreshToken }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
    }


    // MARK: Utils

    static func buildTimeButton(beginTime: Date, endTime: Date?, style: ButtonStyle) -> UIButton {
        let formatTime = { (date: Date) -> String in
            let (hour, minute) = getTimes(date)
            return String(format: "%d:%02d", hour, minute)
        }

        let title: String
        if let endTime = endTime {
            let deltaComps = Calendar.current.dateComponents([.hour, .minute], from: beginTime, to: endTime)
            let delta = { hour, minute in
                return minute == 0 ? "\(hour)시간" : "\(hour)시간 \(minute)분"
            }(deltaComps.hour ?? 0, deltaComps.minute ?? 0)
            title = "\(formatTime(beginTime)) - \(formatTime(endTime)) (\(delta))"
        } else {
            title = formatTime(beginTime)
        }

        let button = UIButton(type: .custom).then {
            $0.setTitle(title, for: .normal)
            $0.backgroundColor = style.backgroundColor
            $0.setTitleColor(style.titleColor, for: .normal)
            $0.setTitleColor(style.highlightedTitleColor, for: .highlighted)
            $0.contentEdgeInsets = Metric.buttonContentEdgeInsets
            $0.layer.cornerRadius = Metric.buttonCornerRadius
            $0.layer.borderWidth = style.borderWidth
            $0.layer.borderColor = style.borderColor?.cgColor
        }
        return button
    }

    static func getTimes(_ date: Date) -> (Int, Int) {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0, comps.minute ?? 0)
    }
}

extension ButtonStyle {
    var backgroundColor: UIColor {
        switch self {
        case .highlighted:
            return CreateWorktimeViewController.Color.buttonBackgroundLight
        case .normal:
            return CreateWorktimeViewController.Color.buttonBackground
        }
    }

    var titleColor: UIColor {
        switch self {
        case .highlighted:
            return CreateWorktimeViewController.Color.titleLight
        case .normal:
            return CreateWorktimeViewController.Color.title
        }
    }

    var highlightedTitleColor: UIColor {
        switch self {
        case .highlighted:
            return CreateWorktimeViewController.Color.titleLightHighlighted
        case .normal:
            return CreateWorktimeViewController.Color.titleHighlighted
        }
    }

    var borderWidth: CGFloat {
        switch self {
        case .highlighted:
            return CreateWorktimeViewController.Metric.buttonBorderWidth
        case .normal:
            return 0
        }
    }

    var borderColor: UIColor? {
        switch self {
        case .highlighted:
            return CreateWorktimeViewController.Color.buttonBorderLight
        case .normal:
            return nil
        }
    }
}

protocol CreateWorktimeViewDelegate: class {
    func createWorktimeViewShouldDismiss()
}
