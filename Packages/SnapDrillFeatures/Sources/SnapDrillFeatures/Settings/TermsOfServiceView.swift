//
//  TermsOfServiceView.swift
//  SnapDrillFeatures
//
//  Created by SnapDrill Labs on 2026/01/02.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  用户协议/服务条款页面
//

import SwiftUI

/// 用户协议视图
public struct TermsOfServiceView: View {
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("用户协议")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("最后更新日期：2026年1月2日")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 10)
                
                // 接受条款
                sectionView(
                    title: "接受条款",
                    content: "欢迎使用 SnapDrill！通过下载、安装或使用本应用，您同意遵守本用户协议的所有条款和条件。如果您不同意这些条款，请不要使用本应用。"
                )
                
                // 服务描述
                sectionView(
                    title: "服务描述",
                    content: """
                    SnapDrill 是一款个人学习助手应用，旨在帮助用户通过间隔重复技术来采集、组织和复习知识。
                    
                    主要功能包括：
                    • 智能扫描与 OCR 文字识别
                    • 错题管理和分类
                    • 间隔重复复习系统
                    • 数据导出（PDF/Markdown/CSV）
                    • iCloud 跨设备同步（可选）
                    """
                )
                
                // 用户账户
                sectionView(
                    title: "用户账户",
                    content: """
                    SnapDrill 不需要创建账户即可使用。所有数据都存储在您的设备上或您的个人 iCloud 账户中。
                    
                    您有责任：
                    • 保护您的设备安全
                    • 妥善保管您的 iCloud 账户信息
                    • 定期备份重要数据
                    """
                )
                
                // 许可授权
                sectionView(
                    title: "许可授权",
                    content: """
                    我们授予您有限的、非独占的、不可转让的、可撤销的许可，允许您在个人设备上使用 SnapDrill 应用。
                    
                    您不得：
                    • 复制、修改或反编译应用
                    • 出售、出租或转让应用
                    • 移除任何版权或所有权声明
                    • 将应用用于非法目的
                    """
                )
                
                // 用户内容
                sectionView(
                    title: "用户内容",
                    content: """
                    您在应用中创建的所有内容（包括文本、图片、笔记等）归您所有。
                    
                    您声明并保证：
                    • 您拥有上传内容的所有权或必要权利
                    • 您的内容不侵犯任何第三方的权利
                    • 您的内容不包含非法、有害或不当的材料
                    
                    我们不会访问、使用或分享您的个人学习内容。
                    """
                )
                
                // 知识产权
                sectionView(
                    title: "知识产权",
                    content: """
                    SnapDrill 应用及其所有内容、功能和特性（包括但不限于软件、文本、图形、标识、图标、图像）均由 SnapDrill Team 拥有，受中国和国际版权、商标和其他知识产权法律保护。
                    
                    "SnapDrill" 名称和标识是 SnapDrill Team 的商标。未经我们事先书面许可，您不得使用这些商标。
                    """
                )
                
                // 免责声明
                sectionView(
                    title: "免责声明",
                    content: """
                    SnapDrill 应用按"现状"和"可用"基础提供，不提供任何明示或暗示的保证。
                    
                    我们不保证：
                    • 应用将无错误或不间断运行
                    • 缺陷将被纠正
                    • 应用将满足您的特定需求
                    • OCR 识别的准确性
                    
                    您使用本应用的风险由您自行承担。
                    """
                )
                
                // 责任限制
                sectionView(
                    title: "责任限制",
                    content: """
                    在法律允许的最大范围内，SnapDrill Team 及其关联方不对以下情况承担责任：
                    
                    • 任何间接、偶然、特殊或后果性损害
                    • 数据丢失或损坏
                    • 业务中断或利润损失
                    • 因使用或无法使用应用而产生的任何损害
                    
                    建议您定期备份重要数据。
                    """
                )
                
                // 数据备份
                sectionView(
                    title: "数据备份",
                    content: """
                    虽然我们努力确保数据的安全性和可靠性，但我们强烈建议您：
                    
                    • 定期导出重要数据
                    • 启用 iCloud 同步作为备份
                    • 保留重要内容的副本
                    
                    我们不对数据丢失承担责任。
                    """
                )
                
                // 服务变更和终止
                sectionView(
                    title: "服务变更和终止",
                    content: """
                    我们保留随时修改、暂停或终止应用或其任何功能的权利，无需事先通知。
                    
                    我们可能会：
                    • 更新应用功能
                    • 修复 bug 和安全漏洞
                    • 改进用户体验
                    
                    您可以随时停止使用应用并删除它。
                    """
                )
                
                // 第三方链接
                sectionView(
                    title: "第三方链接",
                    content: "应用可能包含指向第三方网站或服务的链接。我们不对这些第三方网站的内容、隐私政策或做法负责。访问第三方链接的风险由您自行承担。"
                )
                
                // 适用法律
                sectionView(
                    title: "适用法律",
                    content: "本协议受中华人民共和国法律管辖并按其解释。因本协议引起的任何争议应通过友好协商解决。如协商不成，应提交至应用开发者所在地有管辖权的人民法院解决。"
                )
                
                // 协议修改
                sectionView(
                    title: "协议修改",
                    content: """
                    我们保留随时修改本用户协议的权利。如有重大变更，我们将通过应用内通知或更新日期告知您。
                    
                    修改后继续使用应用即表示您接受修改后的条款。如果您不同意修改后的条款，请停止使用应用。
                    """
                )
                
                // 可分割性
                sectionView(
                    title: "可分割性",
                    content: "如果本协议的任何条款被认定为无效或不可执行，该条款将被删除，其余条款将继续有效。"
                )
                
                // 完整协议
                sectionView(
                    title: "完整协议",
                    content: "本用户协议构成您与 SnapDrill Team 之间关于使用本应用的完整协议，并取代之前的所有口头或书面协议。"
                )
                
                // 联系我们
                sectionView(
                    title: "联系我们",
                    content: """
                    如果您对本用户协议有任何疑问，请通过以下方式联系我们：
                    
                    邮箱：support@snapdrillapp.com
                    应用内反馈：设置 → 关于 → 反馈与建议
                    
                    我们将在 48 小时内回复您的询问。
                    """
                )
            }
            .padding()
        }
        .navigationTitle("用户协议")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func sectionView(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack {
        TermsOfServiceView()
    }
}
