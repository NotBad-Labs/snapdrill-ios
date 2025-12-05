//
//  ExamPaperViews.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI

// MARK: - Exam Page View

/// 试卷页面视图 (A4 尺寸适配)
///
/// 代表 PDF 的一页。
struct ExamPageView: View {
    let title: String
    let pageIndex: Int
    let totalPages: Int
    let items: [ReviewItem]
    let showHeader: Bool
    let config: PDFExportConfig
    /// 本页第一题的全局序号（用于试卷模式编号）
    var startQuestionNumber: Int = 1
    
    // A4 尺寸 (72 DPI): 595 x 842
    // 边距: 40
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 页眉 (仅第一页显示大标题，其他页显示小标题)
            if showHeader {
                ExamHeaderView(title: title, isExamMode: config.examMode)
            } else {
                ExamMiniHeaderView(title: title)
            }
            
            Divider()
                .padding(.vertical, 10)
            
            // 2. 题目列表
            VStack(alignment: .leading, spacing: 24) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    ExamItemView(
                        item: item,
                        config: config,
                        questionNumber: config.examMode ? startQuestionNumber + index : nil
                    )
                }
            }
            .padding(.vertical, 10)
            
            Spacer()
            
            // 3. 页脚
            HStack {
                Text("NotBad 错题本自动生成")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("第 \(pageIndex + 1) 页 / 共 \(totalPages) 页")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)
        }
        .padding(40)
        .frame(width: 595, height: 842) // A4 Point Size
        .background(.white)
        .foregroundStyle(.black) // 强制黑色文字，适合打印
    }
}

// MARK: - Exam Header View

struct ExamHeaderView: View {
    let title: String
    let isExamMode: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // 试卷模式显示更正式的标题
            if isExamMode {
                Text("模拟测验")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Text(title)
                .font(.system(size: 24, weight: .bold))
            
            // 试卷模式显示更完整的信息栏
            if isExamMode {
                HStack(spacing: 30) {
                    Text("姓名: ____________")
                    Text("班级: ____________")
                    Text("得分: ____________")
                }
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                
                HStack(spacing: 30) {
                    Text("日期: ____________")
                    Text("用时: ____________")
                }
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 40) {
                    Text("姓名: ____________")
                    Text("班级: ____________")
                    Text("日期: ____________")
                }
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, 10)
    }
}

struct ExamMiniHeaderView: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

// MARK: - Exam Item View

struct ExamItemView: View {
    let item: ReviewItem
    let config: PDFExportConfig
    /// 题号（试卷模式下显示）
    var questionNumber: Int? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 题目信息行
            HStack {
                // 试卷模式：显示题号
                if config.examMode, let number = questionNumber {
                    Text("\(number).")
                        .font(.system(size: 16, weight: .bold))
                }
                
                Text("【\(item.subject.displayName)】")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                if !item.title.isEmpty {
                    Text(item.title)
                        .font(.system(size: 14, weight: .medium))
                }
                
                Spacer()
                
                Text(item.reviewItemType.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.black, lineWidth: 1)
                    )
            }
            
            // 题目图片
            if config.includeImages, let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200) // 限制图片高度
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // 知识点 (仅复习模式，试卷模式隐藏)
            if !config.examMode, config.includeNotes, !item.knowledgePoints.isEmpty {
                HStack {
                    Text("知识点:")
                        .font(.caption)
                        .bold()
                    ForEach(item.knowledgePoints.items, id: \.self) { point in
                        Text(point)
                            .font(.caption)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(2)
                    }
                }
            }
            
            // 笔记 (仅复习模式，试卷模式隐藏 - 防作弊)
            if !config.examMode, config.includeNotes, !item.note.isEmpty {
                Text("笔记: \(item.note)")
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
            }
            
            // 留白区域 (用于答题)
            if config.showAnswerArea {
                answerAreaView
            }
        }
    }
    
    // MARK: - Answer Area
    
    @ViewBuilder
    private var answerAreaView: some View {
        let height = config.answerAreaHeight.height(for: item.reviewItemType)
        
        VStack(alignment: .leading, spacing: 4) {
            // 根据题型显示不同提示
            Text(answerPrompt)
                .font(.system(size: 14, weight: .bold))
            
            // 选择题：显示选项框
            if item.reviewItemType == .choice || item.reviewItemType == .multiChoice {
                choiceOptionsView
            } else if item.reviewItemType == .judgment {
                // 判断题：显示对错选项
                judgmentOptionsView
            } else {
                // 其他题型：显示答题线
                answerLinesView(height: height)
            }
        }
    }
    
    /// 选择题选项视图
    private var choiceOptionsView: some View {
        HStack(spacing: 30) {
            ForEach(["A", "B", "C", "D"], id: \.self) { option in
                HStack(spacing: 4) {
                    Circle()
                        .stroke(Color.black, lineWidth: 1)
                        .frame(width: 14, height: 14)
                    Text(option)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    /// 判断题选项视图
    private var judgmentOptionsView: some View {
        HStack(spacing: 40) {
            HStack(spacing: 4) {
                Circle()
                    .stroke(Color.black, lineWidth: 1)
                    .frame(width: 14, height: 14)
                Text("对 (√)")
                    .font(.system(size: 14))
            }
            HStack(spacing: 4) {
                Circle()
                    .stroke(Color.black, lineWidth: 1)
                    .frame(width: 14, height: 14)
                Text("错 (×)")
                    .font(.system(size: 14))
            }
        }
        .padding(.vertical, 8)
    }
    
    /// 答题线视图
    private func answerLinesView(height: CGFloat) -> some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: height)
            .overlay(
                VStack(spacing: 20) {
                    ForEach(0..<Int(height / 25), id: \.self) { _ in
                        Divider()
                    }
                }
            )
    }
    
    /// 根据题型返回答题提示
    private var answerPrompt: String {
        switch item.reviewItemType {
        case .choice, .multiChoice:
            return "答案："
        case .judgment:
            return "判断："
        case .fillBlank:
            return "填空："
        case .calculation, .proof:
            return "解："
        case .writing:
            return "作文："
        case .reading, .cloze:
            return "作答："
        default:
            return "解答："
        }
    }
}
