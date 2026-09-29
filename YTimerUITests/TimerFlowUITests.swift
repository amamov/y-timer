import XCTest

/// 사람이 누르는 순서 그대로 타이머 시작을 확인한다.
final class TimerFlowUITests: XCTestCase {
    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    override func setUp() {
        continueAfterFailure = false
    }

    func testCustomOneMinuteStarts() {
        let app = launch(["-timerMode", "custom", "-customSeconds", "60"])
        app.buttons["시작"].tap()
        assertRunning(app)
    }

    func testPresetStarts() {
        let app = launch(["-timerMode", "presets"])
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH '5'")).firstMatch.tap()
        assertRunning(app)
    }

    /// 앱 내장 알림음을 고른 뒤에도 시작되는지.
    func testCustomSoundStarts() {
        let app = launch(["-timerMode", "custom", "-customSeconds", "60"])
        app.buttons["알람 설정"].tap()
        app.buttons["유리"].tap()
        app.buttons["완료"].tap()
        app.buttons["시작"].tap()
        assertRunning(app)
        app.buttons["알람 설정"].tap()
        app.buttons["시스템 기본"].tap()
        app.buttons["완료"].tap()
    }

    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        allowAlarmsIfAsked()
        return app
    }

    /// 첫 실행의 알람 권한 창은 시스템 창이라 springboard 에서 누른다.
    private func allowAlarmsIfAsked() {
        let allow = springboard.alerts.buttons.element(boundBy: 1)
        if allow.waitForExistence(timeout: 3) { allow.tap() }
    }

    private func assertRunning(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let alert = app.alerts.firstMatch
        if alert.waitForExistence(timeout: 2) {
            XCTFail("오류 창: \(alert.staticTexts.allElementsBoundByIndex.map(\.label))", file: file, line: line)
        }
        XCTAssertTrue(app.buttons["끝내기"].waitForExistence(timeout: 5), "타이머가 돌지 않습니다", file: file, line: line)
        app.buttons["끝내기"].tap()
    }
}
