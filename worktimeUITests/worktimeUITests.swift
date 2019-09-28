//
//  worktimeUITests.swift
//  worktimeUITests
//
//  Created by junha on 2019/09/08.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import XCTest
//@testable import worktime

class worktimeUITests: XCTestCase {

    override func setUp() {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments = [
//            "-AppleLanguages",
//            "(ko)",
//            "-AppleLocale",
//            "ko_KR",
            "-UITests",
        ]

        setupSnapshot(app)

        app.launch()
    }

    func testSnapshot() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests"]

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        addUIInterruptionMonitor(withDescription: "Send You Notifications") { alert in
            alert.buttons["Allow"].tap()
            return true
        }

        let loginButton = app.tables.staticTexts["로그인"]
        self.waitForElementToAppear(element: loginButton)
        loginButton.tap()

        let logoutButton = app.tables.staticTexts["로그아웃"]
        self.waitForElementToAppear(element: logoutButton)

        let selectCalendarButton = app.tables.staticTexts["캘린더를 선택하세요"]
        self.waitForElementToAppear(element: selectCalendarButton)
        selectCalendarButton.tap()

        let worktimeCalendarRow = app.tables.staticTexts["근무시간"]
        self.waitForElementToAppear(element: worktimeCalendarRow)
        worktimeCalendarRow.tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()  // back

        let eventTitleField = app.textFields["일정 제목 필드"]
        self.waitForElementToAppear(element: eventTitleField)
        eventTitleField.tap()
        eventTitleField.typeText("junha\n")

        let notificationScheduleButton = app.tables.staticTexts["알림 시각"]
        self.waitForElementToAppear(element: notificationScheduleButton)
        notificationScheduleButton.tap()

        let notificationEnabledSwitch = app.tables.switches.element(boundBy: 0)
        self.waitForElementToAppear(element: notificationEnabledSwitch)
        notificationEnabledSwitch.tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()  // back

        self.waitForElementToAppear(element: logoutButton)
        if #available(iOS 13, *) {
            springboard.statusBars.firstMatch.tap()
        } else {
            app.statusBars.firstMatch.tap()
        }
        precondition(eventTitleField.value as? String == "junha")
        sleep(2)
        snapshot("00-Settings")

        let notifyNowButton = app.tables.staticTexts["지금 알림 받아보기"]
        self.waitForElementToAppear(element: notifyNowButton)
        notifyNowButton.tap()

        let notification = springboard.otherElements["NotificationShortLookView"]
        self.waitForElementToAppear(element: notification)
        notification.swipeDown()

        let worktimeBeginLabel = springboard.staticTexts["오늘 언제 근무를 시작하시나요?"]
        self.waitForElementToAppear(element: worktimeBeginLabel, timeout: 10)

        let strictBeginButton = springboard.buttons["10:00"]
        self.waitForElementToAppear(element: strictBeginButton)
        snapshot("01-Register-Begin")

        strictBeginButton.tap()

        let worktimeEndLabel = springboard.staticTexts["오늘 언제 근무를 종료하시나요?"]
        self.waitForElementToAppear(element: worktimeEndLabel)

        let strictEndButton = springboard.buttons["10:00 - 19:00 (9시간)"]
        self.waitForElementToAppear(element: strictEndButton)
        snapshot("02-Register-End")
    }

    func waitForElementToAppear(element: XCUIElement, timeout: TimeInterval = 5, file: String = #file,
                                line: Int = #line) {
        let existsPredicate = NSPredicate(format: "exists == true")

        expectation(for: existsPredicate,
                    evaluatedWith: element, handler: nil)

        waitForExpectations(timeout: timeout) { (error) -> Void in
            if (error != nil) {
                let message = "Failed to find \(element) after \(timeout) seconds."
                self.recordFailure(withDescription: message, inFile: file, atLine: line, expected: true)
            }
        }
    }
}
