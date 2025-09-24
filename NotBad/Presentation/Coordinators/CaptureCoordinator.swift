//
//  CaptureCoordinator.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import SwiftUI

/// 拍照协调器
/// 管理拍照模块的导航逻辑
@MainActor
class CaptureCoordinator: BaseCoordinator {
    enum CaptureRoute: Hashable {
        case ocr(imageBase64: String)
        case edit(text: String)
        case save(content: String)
    }
    /// 是否显示相机
    @Published var showCamera = false

    /// 是否显示照片库
    @Published var showPhotoLibrary = false

    override func coordinate(to route: Route) {
        switch route {
        case .capture:
            // 回到拍照根视图
            navigationPath = NavigationPath()
            showCamera = false
            showPhotoLibrary = false

        case .camera:
            showCamera = true

        case .photoLibrary:
            showPhotoLibrary = true

        case .ocrResult(let image):
            navigationPath.append(CaptureRoute.ocr(imageBase64: image))

        case .ocrEdit(let result):
            navigationPath.append(CaptureRoute.edit(text: result))

        case .saveReviewItem(let content):
            navigationPath.append(CaptureRoute.save(content: content))

        default:
            // 无法处理的路由委托给父协调器
            delegate(route: route)
        }
    }

    override func goBack() {
        if showCamera {
            showCamera = false
        } else if showPhotoLibrary {
            showPhotoLibrary = false
        } else {
            super.goBack()
        }
    }

    /// 完成捕获工作流，可选择下一步操作
    func completeWorkflow(nextAction: CaptureCompletionAction = .returnToLibrary) {
        // 根据用户选择的下一步操作进行导航
        switch nextAction {
        case .returnToLibrary:
            // 通过父协调器导航到Library Tab
            delegate(route: .navigateToLibraryAfterCapture)
        case .startPractice:
            delegate(route: .navigateToPracticeFromLibrary)
        case .addAnother:
            coordinate(to: .capture)
        }
    }
}

/// 拍照完成后的操作选项
enum CaptureCompletionAction {
    case returnToLibrary    // 返回题库查看
    case startPractice      // 立即开始练习
    case addAnother         // 添加另一题
}
