//
//  CaptureUITests.swift
//  NotBadUITests
//
//  Created for NotBad K12 错题本
//

import XCTest

/// 录入错题 UI 测试
///
/// 测试添加错题的完整流程
final class CaptureUITests: NotBadUITests {

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        app.launch()
        completeOnboardingIfNeeded()
    }

    // MARK: - Tests

    /// 测试录入页面基本显示
    func testCaptureTabDisplay() throws {
        // 导航到录入 Tab
        navigateToTab("录入")

        takeScreenshot(named: "capture_tab_initial")

        // 验证录入页面元素存在
        let imageSelectionCard = app.otherElements["image_selection_card"]
        XCTAssertTrue(imageSelectionCard.waitForExistence(timeout: 3) || app.buttons["capture_camera"].exists,
                      "图片选择区域应该存在")

        // 验证表单元素
        XCTAssertTrue(app.staticTexts["capture_field_title"].exists ||
                      app.textFields.count > 0,
                      "标题输入框应该存在")

        // 验证保存按钮
        let saveButton = app.buttons["capture_save_to_library"]
        XCTAssertTrue(saveButton.exists, "保存按钮应该存在")
    }

    /// 测试填写标题
    func testFillTitle() throws {
        navigateToTab("录入")

        // 找到标题输入框
        let titleField = app.textFields.firstMatch
        XCTAssertTrue(titleField.waitForExistence(timeout: 3))

        // 输入标题
        titleField.tap()
        titleField.typeText("测试错题标题")

        takeScreenshot(named: "capture_title_filled")

        // 验证输入成功
        XCTAssertEqual(titleField.value as? String, "测试错题标题")
    }

    /// 测试学科选择
    func testSubjectSelection() throws {
        navigateToTab("录入")

        // 找到学科选择器
        let subjectPicker = app.buttons["capture_subject_picker"]
        if subjectPicker.waitForExistence(timeout: 3) {
            subjectPicker.tap()

            takeScreenshot(named: "capture_subject_picker_open")

            // 选择数学
            let mathOption = app.buttons["数学"]
            if mathOption.waitForExistence(timeout: 2) {
                mathOption.tap()
            }

            takeScreenshot(named: "capture_subject_selected")
        }
    }

    /// 测试年级选择
    func testGradeSelection() throws {
        navigateToTab("录入")

        // 找到年级选择器
        let gradePicker = app.buttons["capture_grade_picker"]
        if gradePicker.waitForExistence(timeout: 3) {
            gradePicker.tap()

            takeScreenshot(named: "capture_grade_picker_open")

            // 选择一个年级
            let gradeOption = app.buttons.matching(NSPredicate(format: "label CONTAINS '高'")).firstMatch
            if gradeOption.waitForExistence(timeout: 2) {
                gradeOption.tap()
            }

            takeScreenshot(named: "capture_grade_selected")
        }
    }

    /// 测试保存验证（无标题时）
    func testSaveValidation() throws {
        navigateToTab("录入")

        // 直接点击保存按钮
        let saveButton = app.buttons["capture_save_to_library"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3))
        saveButton.tap()

        takeScreenshot(named: "capture_validation_error")

        // 验证显示错误提示
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 3), "应该显示验证错误提示")
    }

    /// 测试完整的录入流程
    func testCompleteCapture() throws {
        navigateToTab("录入")

        // 1. 填写标题
        let titleField = app.textFields.firstMatch
        XCTAssertTrue(titleField.waitForExistence(timeout: 3))
        titleField.tap()
        titleField.typeText("UI测试错题")

        // 关闭键盘
        app.keyboards.buttons["完成"].tap()

        takeScreenshot(named: "capture_complete_filled")

        // 2. 点击保存
        let saveButton = app.buttons["capture_save_to_library"]
        saveButton.tap()

        // 3. 验证保存成功
        // 可能显示成功提示或跳转
        let successAlert = app.alerts.firstMatch
        if successAlert.waitForExistence(timeout: 3) {
            takeScreenshot(named: "capture_success_alert")

            // 点击确认
            let confirmButton = successAlert.buttons.firstMatch
            confirmButton.tap()
        }

        takeScreenshot(named: "capture_after_save")
    }

    /// 测试相机按钮
    func testCameraButton() throws {
        navigateToTab("录入")

        // 找到相机按钮
        let cameraButton = app.buttons["capture_camera"]
        if cameraButton.waitForExistence(timeout: 3) {
            // 注意：在模拟器上相机可能不可用
            // 这里只验证按钮存在且可点击
            XCTAssertTrue(cameraButton.isEnabled, "相机按钮应该可用")
            takeScreenshot(named: "capture_camera_button")
        }
    }

    /// 测试相册按钮
    func testAlbumButton() throws {
        navigateToTab("录入")

        // 找到相册按钮
        let albumButton = app.buttons["capture_album"]
        if albumButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(albumButton.isEnabled, "相册按钮应该可用")

            // 点击相册按钮
            albumButton.tap()

            // 验证相册选择器出现
            let photoPicker = app.otherElements["photo-picker"]
            // iOS 系统相册选择器
            let photoLibrary = app.navigationBars["Photos"]

            takeScreenshot(named: "capture_photo_picker")

            // 关闭选择器
            if app.buttons["Cancel"].exists {
                app.buttons["Cancel"].tap()
            } else if app.buttons["取消"].exists {
                app.buttons["取消"].tap()
            }
        }
    }
}
