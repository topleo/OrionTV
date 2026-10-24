import XCTest
final class NavigationUITests: XCTestCase {
    func testEpisodeButtonsHaveUniformBounds() throws {
        let app=XCUIApplication(bundleIdentifier:"com.oriontv.layout-preview")
        app.launch()
        let remote=XCUIRemote.shared
        sleep(3)
        remote.press(.right)
        remote.press(.select)
        XCTAssertTrue(app.buttons["episode-1"].waitForExistence(timeout:10))
        func checkVisibleButtons() {
            let buttons=app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@", "episode-")).allElementsBoundByIndex.filter { !$0.hasFocus && $0.frame.height > 0 }
            XCTAssertGreaterThan(buttons.count, 1)
            if let first=buttons.first {
                for button in buttons {
                    XCTAssertEqual(button.frame.width, first.frame.width, accuracy:1)
                    XCTAssertEqual(button.frame.height, first.frame.height, accuracy:1)
                }
            }
        }
        checkVisibleButtons()
        for _ in 0..<17 { remote.press(.down) }
        XCTAssertTrue(app.buttons["episode-100"].exists)
        checkVisibleButtons()
        let shot=XCTAttachment(screenshot:app.screenshot());shot.lifetime = .keepAlways;add(shot)
    }
    func testEmptyLiveCanReturnToSidebarAndSettings() throws {
        for (url, title) in [("", "添加直播频道"), ("http://127.0.0.1:18087/empty.m3u", "暂无直播频道"), ("not-a-url", "无法加载频道")] {
            let app=XCUIApplication(bundleIdentifier:"com.oriontv.layout-preview")
            app.launchArguments = ["-native.liveURL", url]
            app.launch()
            let remote=XCUIRemote.shared
            sleep(3)
            for _ in 0..<12 { remote.press(.up) }
            for _ in 0..<7 { remote.press(.down) }
            remote.press(.select)
            remote.press(.right)
            let settings=app.buttons["live-open-settings"]
            XCTAssertTrue(settings.waitForExistence(timeout:5))
            XCTAssertTrue(app.staticTexts[title].exists)
            remote.press(.menu)
            sleep(1)
            let actions=app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "live-")).allElementsBoundByIndex
            XCTAssertFalse(actions.contains { $0.hasFocus }, "Back should move focus into the native sidebar")
            remote.press(.right)
            for _ in 0..<4 { if settings.hasFocus { break }; remote.press(.down) }
            XCTAssertTrue(settings.hasFocus)
            remote.press(.select)
            XCTAssertTrue(app.textFields["M3U 订阅地址"].waitForExistence(timeout:5))
            app.terminate()
        }
    }
    func testPartialRowAndSidebar() throws {
        let app=XCUIApplication(bundleIdentifier:"com.oriontv.layout-preview")
        app.launch()
        let remote=XCUIRemote.shared
        sleep(3)
        for _ in 0..<12 { remote.press(.up) }
        for _ in 0..<2 { remote.press(.down) }
        remote.press(.select)
        sleep(2)
        for _ in 0..<7 { remote.press(.right) }
        let sixth=app.buttons["poster-影片 06"]
        XCTAssertTrue(sixth.waitForExistence(timeout:5))
        XCTAssertTrue(sixth.hasFocus, "Expected last card of first row")
        remote.press(.down)
        let ninth=app.buttons["poster-影片 09"]
        XCTAssertTrue(ninth.hasFocus, "Down from column six should choose column three in partial row")
        let shot=XCTAttachment(screenshot:app.screenshot());shot.lifetime = .keepAlways;add(shot)
        remote.press(.menu)
        remote.press(.menu)
        sleep(1)
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "poster-")).allElementsBoundByIndex.contains { $0.hasFocus })
        let sidebar=XCTAttachment(screenshot:app.screenshot());sidebar.lifetime = .keepAlways;add(sidebar)
    }
    func testAutomaticPaging() throws {
        let app=XCUIApplication(bundleIdentifier:"com.oriontv.layout-preview")
        app.launch()
        let remote=XCUIRemote.shared
        sleep(3)
        for _ in 0..<12 { remote.press(.up) }
        remote.press(.down)
        remote.press(.select)
        remote.press(.right)
        for _ in 0..<12 { remote.press(.down) }
        let last=app.buttons["poster-较长影片标题用于检查两行排版 43"]
        XCTAssertTrue(last.waitForExistence(timeout:5))
        XCTAssertTrue(last.hasFocus)
        XCTAssertFalse(app.staticTexts["热门剧集"].isHittable, "Content heading should scroll away")
    }
}
