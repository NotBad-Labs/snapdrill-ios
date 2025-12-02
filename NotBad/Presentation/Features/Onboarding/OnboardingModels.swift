//
//  OnboardingModels.swift
//  NotBad
//
//  引导流程相关模型
//

import Foundation

// MARK: - OnboardingStep

/// 引导步骤
///
/// 表示首次启动引导的各个步骤。
enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome = 0
    case selectRegion = 1
    case selectGrade = 2
    case selectSubjects = 3

    var id: Int { rawValue }
}
