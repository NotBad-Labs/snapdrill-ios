//
//  NotBadWidget.swift
//  NotBadWidget
//
//  使用 ReviewKit 共享数据
//  Widget 和主 App 使用相同的 ReviewKit.ReviewItemModel
//

import WidgetKit
import SwiftUI
import SwiftData
import ReviewKit  // ✅ 导入 ReviewKit，共享 Model 定义

// MARK: - ReviewEntry

/// 复习数据条目
struct ReviewEntry: TimelineEntry {
    let date: Date
    let pendingCount: Int
    let overdueCount: Int
    let masteryRate: Double
    let recentSubjects: [String]
    let configuration: ConfigurationAppIntent
}

// MARK: - Provider

/// 小组件数据提供者
///
/// 直接从 SwiftData 读取数据（通过 App Groups 共享）
struct Provider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> ReviewEntry {
        ReviewEntry(
            date: Date(),
            pendingCount: 5,
            overdueCount: 2,
            masteryRate: 0.65,
            recentSubjects: ["数学", "英语", "物理"],
            configuration: ConfigurationAppIntent()
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> ReviewEntry {
        await getEntry(for: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<ReviewEntry> {
        let entry = await getEntry(for: configuration)

        // 每30分钟更新一次
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    @MainActor
    private func getEntry(for configuration: ConfigurationAppIntent) async -> ReviewEntry {
        // ✅ 使用 ReviewKit 的 PersistenceController 读取共享数据
        do {
            let context = PersistenceController.shared.container.mainContext
            
            let descriptor = FetchDescriptor<ReviewItemModel>()
            let allItems = try context.fetch(descriptor)
            
            let now = Date()
            let startOfDay = Calendar.current.startOfDay(for: now)
            
            // 待复习：nextReviewDate <= now
            let pendingCount = allItems.filter { $0.nextReviewDate <= now }.count
            
            // 已逾期：nextReviewDate < 今天开始
            let overdueCount = allItems.filter { $0.nextReviewDate < startOfDay }.count
            
            // 掌握率
            let masteredCount = allItems.filter { $0.masteryLevel >= 3 }.count
            let masteryRate = allItems.isEmpty ? 0 : Double(masteredCount) / Double(allItems.count)
            
            // 最近学科
            let recentSubjects = Array(Set(allItems.prefix(10).map { $0.subjectRaw })).prefix(3).map { String($0) }
            
            return ReviewEntry(
                date: now,
                pendingCount: pendingCount,
                overdueCount: overdueCount,
                masteryRate: masteryRate,
                recentSubjects: Array(recentSubjects),
                configuration: configuration
            )
        } catch {
            print("❌ Widget 读取数据失败: \(error)")
            return ReviewEntry(
                date: Date(),
                pendingCount: 0,
                overdueCount: 0,
                masteryRate: 0,
                recentSubjects: [],
                configuration: configuration
            )
        }
    }
}

// MARK: - ConfigurationAppIntent

import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "错题本小组件" }
    static var description: IntentDescription { "显示复习进度和统计信息" }

    @Parameter(title: "显示样式", default: .compact)
    var displayStyle: WidgetDisplayStyle
}

enum WidgetDisplayStyle: String, AppEnum {
    case compact = "紧凑"
    case detailed = "详细"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "显示样式"
    }

    static var caseDisplayRepresentations: [WidgetDisplayStyle: DisplayRepresentation] {
        [
            .compact: "紧凑",
            .detailed: "详细"
        ]
    }
}

// MARK: - Widget Views

struct NotBadWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .accessoryCircular:
            CircularWidgetView(entry: entry)
        case .accessoryRectangular:
            RectangularWidgetView(entry: entry)
        case .accessoryInline:
            InlineWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: ReviewEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundStyle(.orange)
                Text("错题本")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(entry.pendingCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("待复习")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if entry.overdueCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.caption2)
                        Text("\(entry.overdueCount) 道已逾期")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: ReviewEntry

    var body: some View {
        HStack(spacing: 16) {
            // 左侧统计
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "book.fill")
                        .foregroundStyle(.orange)
                    Text("错题本")
                        .font(.headline)
                        .fontWeight(.bold)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("\(entry.pendingCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("待复习")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if entry.overdueCount > 0 {
                    Label("\(entry.overdueCount) 道已逾期", systemImage: "exclamationmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }

            Divider()

            // 右侧掌握率
            VStack(spacing: 8) {
                Text("掌握率")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: entry.masteryRate)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(entry.masteryRate * 100))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .frame(width: 70, height: 70)

                if !entry.recentSubjects.isEmpty {
                    Text(entry.recentSubjects.prefix(2).joined(separator: "·"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let entry: ReviewEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Image(systemName: "book.fill")
                    .foregroundStyle(.orange)
                Text("错题本")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text("今日复习")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // 统计卡片
            HStack(spacing: 12) {
                StatCardWidget(
                    title: "待复习",
                    value: "\(entry.pendingCount)",
                    icon: "clock.arrow.circlepath",
                    color: .orange
                )

                StatCardWidget(
                    title: "已逾期",
                    value: "\(entry.overdueCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )

                StatCardWidget(
                    title: "掌握率",
                    value: "\(Int(entry.masteryRate * 100))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
            }

            Spacer()

            // 最近科目
            if !entry.recentSubjects.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("最近学科")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ForEach(entry.recentSubjects.prefix(4), id: \.self) { subject in
                            Text(subject)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.1))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // 快速操作
            HStack {
                Link(destination: URL(string: "notbad://review")!) {
                    Label("开始复习", systemImage: "play.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Stat Card Widget

struct StatCardWidget: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Accessory Widgets

struct CircularWidgetView: View {
    let entry: ReviewEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 0) {
                Text("\(entry.pendingCount)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text("待复习")
                    .font(.system(size: 8))
            }
        }
    }
}

struct RectangularWidgetView: View {
    let entry: ReviewEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("错题本")
                    .font(.headline)
                Text("\(entry.pendingCount) 道待复习")
                    .font(.caption)
            }

            Spacer()

            if entry.overdueCount > 0 {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
            }
        }
    }
}

struct InlineWidgetView: View {
    let entry: ReviewEntry

    var body: some View {
        Text("📚 \(entry.pendingCount) 道待复习")
    }
}

// MARK: - Widget Configuration

struct NotBadWidget: Widget {
    let kind: String = "NotBadWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: Provider()
        ) { entry in
            NotBadWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("错题本")
        .description("快速查看复习进度和统计信息")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    NotBadWidget()
} timeline: {
    ReviewEntry(
        date: .now,
        pendingCount: 12,
        overdueCount: 3,
        masteryRate: 0.72,
        recentSubjects: ["数学", "英语", "物理"],
        configuration: ConfigurationAppIntent()
    )
}

#Preview(as: .systemMedium) {
    NotBadWidget()
} timeline: {
    ReviewEntry(
        date: .now,
        pendingCount: 12,
        overdueCount: 3,
        masteryRate: 0.72,
        recentSubjects: ["数学", "英语", "物理"],
        configuration: ConfigurationAppIntent()
    )
}

#Preview(as: .systemLarge) {
    NotBadWidget()
} timeline: {
    ReviewEntry(
        date: .now,
        pendingCount: 12,
        overdueCount: 3,
        masteryRate: 0.72,
        recentSubjects: ["数学", "英语", "物理"],
        configuration: ConfigurationAppIntent()
    )
}
