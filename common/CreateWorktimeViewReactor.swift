//
//  CreateWorktimeViewReactor.swift
//  worktime-noti-content
//
//  Created by junha on 2019/09/07.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import Pure
import ReactorKit
import RxSwift
import UserNotifications


class CreateWorktimeViewReactor: Reactor, FactoryModule {
    typealias Button = (beginDate: Date, endDate: Date?, style: ButtonStyle)

    struct Dependency {
        let preference: Preference
        let userNotificationCenter: UNUserNotificationCenter
        let googleProvider: GoogleProvider
        let googleClientID: String
    }

    struct Payload {}

    enum Action {
        case refreshToken
        case selectTimes(Date?, Date?)
    }

    enum Mutation {
        case setLoading(Bool)
        case setShouldDismiss
        case setErrorMessage(String?)
        case setTimes(Date?, Date?)
        case setButtons([Button])
    }

    struct State {
        var isLoading: Bool
        var shouldDismiss: Bool
        var errorMessage: String?

        var times: (Date?, Date?)

        var buttons: [Button]

        var title: String {
            if let errorMessage = errorMessage {
                return errorMessage
            }

            switch times {
            case (.none, _):
                return "언제 근무를 시작하시나요?"
            case (.some, .none):
                return "언제 근무를 종료하시나요?"
            case (.some, .some):
                return "등록 중..."
            }
        }
    }

    let initialState: State

    let dependency: Dependency
    var notificationIdentifier: String?

    required init(dependency: Dependency, payload: Payload) {
        self.dependency = dependency

        self.initialState = State(
            isLoading: false,
            shouldDismiss: false,
            errorMessage: nil,
            times: (nil, nil),
            buttons: []
        )
        self.action.onNext(.selectTimes(nil, nil))
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .refreshToken:
            guard let googleUser = self.dependency.preference.googleUser else {
                return .empty()
            }
            let refreshToken = self.dependency.googleProvider
                .rx.request(.refreshToken(
                    clientID: self.dependency.googleClientID,
                    refreshToken: googleUser.refreshToken
                ))
                .map(Token.self)
                .map { token in GoogleUser(
                    accessToken: token.accessToken,
                    accessTokenExpirationDate: Date().addingTimeInterval(TimeInterval(token.expiresIn)),
                    refreshToken: googleUser.refreshToken,
                    email: googleUser.email,
                    name: googleUser.name
                ) }
                .do(onSuccess: { [weak self] user in
                    guard let `self` = self else {
                        return
                    }
                    self.dependency.preference.googleUser = user
                })
                .asDriver(onErrorDriveWith: .empty())
            return .concat(
                .just(.setLoading(true)),
                refreshToken.asObservable().flatMap { _ in Observable<Mutation>.empty() },
                .just(.setLoading(false))
            )
        case let .selectTimes(beginTime, endTime):
            let setButtons: Observable<Mutation> = {
                switch (beginTime, endTime) {
                case (.none, _):
                    let base = type(of: self).normalize(date: Date())
                    return .just(.setButtons(
                        type(of: self).makeBeginButtons(base: base)
                    ))
                case let (.some(beginTime), .none):
                    return .just(.setButtons(
                        type(of: self).makeEndButtons(beginDate: beginTime)
                    ))
                case let (.some(beginTime), .some(endTime)):
                    let preference = self.dependency.preference
                    guard let calendarID = preference.selectedCalendarID else {
                        return .just(.setErrorMessage("캘린더 정보를 불러오는 데 실패했습니다. 앱을 열어서 다시 설정해주세요."))
                    }
                    guard let eventTitle = preference.eventTitle, !eventTitle.isEmpty else {
                        return .just(.setErrorMessage("오류: 앱을 열어서 일정 제목을 설정해주세요."))
                    }

                    let event = Event(
                        id: nil,
                        summary: eventTitle,
                        start: .dateTime(beginTime),
                        end: .dateTime(endTime)
                    )
                    let createEvent = self.dependency.googleProvider
                        .rx.request(.createEvent(calendarID: calendarID, event: event))
                        .filterSuccessfulStatusCodes()
                        .do(onSuccess: { [weak self] response in
                            let data = try? response.mapJSON()
                            NSLog("!== Success to create event \(data ?? "none")")
                            if let identifier = self?.notificationIdentifier {
                                self?.dependency.userNotificationCenter.removeDeliveredNotifications(
                                    withIdentifiers: [identifier]
                                )
                            }
                        }, onError: { error in
                            NSLog("!== Failed to create event - error: \(error)")
                        })
                        .asObservable()
                        .share()
                    let mutations = createEvent
                        .map { _ -> Mutation in .setShouldDismiss }
                        .catchErrorJustReturn(.setErrorMessage("등록 중 문제가 발생했습니다."))
                    return .concat(
                        .just(.setLoading(true)),
                        mutations,
                        .just(.setLoading(false))
                    )
                }
            }()
            return .merge(
                .just(.setTimes(beginTime, endTime)),
                setButtons
            )
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case let .setLoading(isLoading):
            state.isLoading = isLoading
        case .setShouldDismiss:
            state.shouldDismiss = true
        case let .setErrorMessage(message):
            state.errorMessage = message
        case let .setTimes(beginTime, endTime):
            state.times = (beginTime, endTime)
        case let .setButtons(buttons):
            state.buttons = buttons
        }
        return state
    }

    static func normalize(date: Date) -> Date {
        // 시각을 5분 단위로 올림해서 반환합니다.
        let calendar = Calendar.current
        let baseDate = date.addingTimeInterval((5 * 60) - 1)
        let components = calendar.dateComponents([.hour, .minute, .second], from: baseDate)
        return calendar.date(
            bySettingHour: components.hour ?? 0,
            minute: Int(Double(components.minute ?? 0) / 5.0) * 5,
            second: 0,
            of: baseDate
        ) ?? baseDate
    }

    static func makeBeginButtons(base: Date) -> [Button] {
        let calendar = Calendar.current
        let strict: [Button] = [(
            beginDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: base) ?? base,
            endDate: nil,
            style: .highlighted
        )]
        let intervals: [TimeInterval] = [
            0,
            10 * 60,
            15 * 60,
            20 * 60,
            30 * 60
        ]
        let futures: [Button] = intervals
            .map(base.addingTimeInterval)
            .map { (beginDate: $0, endDate: nil, style: .normal) }
        return strict + futures
    }

    static func makeEndButtons(beginDate: Date) -> [Button] {
        let calendar = Calendar.current
        let strict: [Button] = {
            let date = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: beginDate) ?? beginDate
            guard beginDate < date else {
                return []
            }
            return [(beginDate: beginDate, endDate: date, style: .highlighted)]
        }()
        let intervals: [TimeInterval] = [
            9 * 60 * 60,
            8 * 60 * 60,
            7 * 60 * 60,
            4 * 60 * 60
        ]
        let normals: [Button] = intervals
            .map(beginDate.addingTimeInterval)
            .map { (beginDate: beginDate, endDate: $0, style: .normal) }
        return strict + normals
    }
}

enum Step {
    case selectBegin
    case selectEnd(selectedBeginTime: Date)
}

enum ButtonStyle {
    case highlighted
    case normal
}

extension ButtonStyle: Equatable {
}
