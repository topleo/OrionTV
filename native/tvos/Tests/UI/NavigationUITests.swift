import XCTest
final class NavigationUITests: XCTestCase {
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
