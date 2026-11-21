import CoreGraphics
import Foundation
import SwiftData
import UIKit

/// Synthesizes realistic printed homework/exam mistake cards (with red grading & blue handwritten notes)
/// and processes them through the live on-device ink-removal engine for instant Dogfood/demo testing.
@MainActor
enum DemoNotebookSeeder {
    private struct ProblemTemplate {
        let subjectIndex: Int
        let sourceTitle: String
        let printedHeader: String
        let printedLines: [String]
        let handwrittenLines: [String]
        let hasGeometryDiagram: Bool
        let answerText: String
        let notes: String
        let causes: [MistakeCause]
        let tags: [String]
        let mastery: MasteryLevel
        let hoursAgo: Double
    }

    static func populateDemoMistakes(
        in context: ModelContext,
        imageStore: MistakeImageStore = MistakeImageStore(),
        locale: Locale = .current
    ) async throws {
        let subjects = SubjectCatalog.ensureSeeded(in: context, locale: locale)
            .filter { !$0.isUncategorizedBucket }
        guard !subjects.isEmpty else { return }

        let remover = HeuristicInkRemover()
        let templates = localizedTemplates(for: locale)

        for template in templates {
            let subject = subjects[template.subjectIndex % subjects.count]
            let originalImage = renderProblemImage(template: template)
            guard let originalData = originalImage.jpegData(compressionQuality: 0.90) else { continue }
            let (cleanedData, succeeded) = await remover.removeInk(from: originalData, mode: .autoAll)
            let ocrText = template.printedHeader + "\n" + template.printedLines.joined(separator: "\n")

            let itemID = UUID()
            let origRel = try imageStore.saveJPEG(originalData, relativePath: "orig/\(itemID.uuidString).jpg")
            let cleanRel = try imageStore.saveJPEG(cleanedData, relativePath: "clean/\(itemID.uuidString).jpg")

            let resolvedTags = resolveTags(named: template.tags, in: context)
            let mistake = MistakeItem(
                id: itemID,
                createdAt: Date().addingTimeInterval(-template.hoursAgo * 3600),
                sourceTitle: template.sourceTitle,
                notes: template.notes,
                answerText: template.answerText,
                causes: template.causes,
                mastery: template.mastery,
                ocrText: ocrText,
                originalImagePath: origRel,
                cleanedImagePath: cleanRel,
                handwritingRemovalSucceeded: succeeded,
                reviewCount: template.mastery == .mastered ? 2 : 1,
                lastReviewedAt: Date().addingTimeInterval(-template.hoursAgo * 1800),
                subject: subject
            )
            mistake.tags = resolvedTags
            context.insert(mistake)
        }

        try context.save()
    }

    // MARK: - Templates

    private static func localizedTemplates(for locale: Locale) -> [ProblemTemplate] {
        let lang = locale.language.languageCode?.identifier ?? "en"
        if lang == "ja" {
            return [
                ProblemTemplate(
                    subjectIndex: 0,
                    sourceTitle: "2学期中間テスト 大問3",
                    printedHeader: "3. 二次関数 y = x² - 4ax + 3a² + 2 (0 ≤ x ≤ 2) の最小値を求めよ。",
                    printedLines: [
                        "ただし a は実数の定数とする。",
                        "(1) a の値によって場合分けし、最小値 m(a) を表せ。",
                        "(2) m(a) = -2 となるときの a の値をすべて求めよ。"
                    ],
                    handwrittenLines: [
                        "軸 x = 2a が 0 と 2 の間にあるとき...",
                        "2a < 0 のケースを見落とした！",
                        "✗ 場合分け漏れ -4点"
                    ],
                    hasGeometryDiagram: true,
                    answerText: "軸 x = 2a に着目し、(i) 2a < 0、(ii) 0 ≤ 2a ≤ 2、(iii) 2a > 2 の 3 つに分類。m(a) = -2 より a = ±2 / √... を吟味して a = -1 + √... ではなく計算整理後 a = 2, -2/3 等を確認する。",
                    notes: "区間に対する軸の位置で必ず数直線を描いて 3 通りに分けること。",
                    causes: [.conceptUnclear, .misreadQuestion],
                    tags: ["二次関数", "中間考査"],
                    mastery: .unknown,
                    hoursAgo: 4
                ),
                ProblemTemplate(
                    subjectIndex: 1,
                    sourceTitle: "英語長文演習 P.42",
                    printedHeader: "Q5. 空所に入る最も適切な語句を 1 つ選びなさい。",
                    printedLines: [
                        "Hardly had she arrived at the station (   ) the train departed.",
                        "A. than    B. when    C. before    D. until"
                    ],
                    handwrittenLines: [
                        "no sooner ... than と混同して A を選んだ",
                        "✓ 正解 B (Hardly ... when)"
                    ],
                    hasGeometryDiagram: false,
                    answerText: "正解：B (when)。Hardly / Scarcely ... when ~「〜するとすぐに」は no sooner ... than と混同しやすい。",
                    notes: "否定語の倒置表現セットを音読して区別する。",
                    causes: [.careless],
                    tags: ["文法", "倒置"],
                    mastery: .fuzzy,
                    hoursAgo: 20
                )
            ]
        }

        if lang == "zh" {
            return [
                ProblemTemplate(
                    subjectIndex: 0,
                    sourceTitle: "期中模拟卷 第14题",
                    printedHeader: "14. 已知函数 f(x) = x² - 2ax + 3 在区间 [0, 2] 上的最小值为 g(a)。",
                    printedLines: [
                        "(1) 求 g(a) 关于参数 a 的分段解析式；",
                        "(2) 若存在 x ∈ [0, 2] 使 f(x) ≤ 1，求实数 a 的取值范围。"
                    ],
                    handwrittenLines: [
                        "对称轴 x = a，直接代入了 f(a) = 3 - a²",
                        "✗ 忘记讨论 a < 0 和 a > 2 的端点情况！",
                        "算错符号：a ≥ 1"
                    ],
                    hasGeometryDiagram: true,
                    answerText: "(1) 当 a < 0 时，g(a) = f(0) = 3；当 0 ≤ a ≤ 2 时，g(a) = f(a) = 3 - a²；当 a > 2 时，g(a) = f(2) = 7 - 4a。\n(2) 转化为 g(a) ≤ 1，解得 a ≥ √2。",
                    notes: "动轴定区间问题必须先画数轴标出 0 和 2，分三段讨论最稳妥。",
                    causes: [.conceptUnclear, .calculationError],
                    tags: ["二次函数", "期中考试"],
                    mastery: .unknown,
                    hoursAgo: 3
                ),
                ProblemTemplate(
                    subjectIndex: 3,
                    sourceTitle: "力学专题练习 P.28",
                    printedHeader: "8. 质量为 m 的滑块静止在倾角 θ = 30° 的粗糙斜面上，受水平推力 F 作用。",
                    printedLines: [
                        "若滑块与斜面间动摩擦因数为 μ，最大静摩擦力等于滑动摩擦力，",
                        "求使滑块保持静止时水平推力 F 的最大与最小值。"
                    ],
                    handwrittenLines: [
                        "支持力 N = mg cosθ  (漏了 F sinθ !)",
                        "✗ 受力分解少了一项 -5分"
                    ],
                    hasGeometryDiagram: true,
                    answerText: "正交分解：垂直斜面方向 N = mg cosθ + F sinθ；沿斜面方向 F cosθ ± f = mg sinθ，代入 f_max = μN 分别求得 F_max 与 F_min。",
                    notes: "水平力 F 在垂直斜面方向有分力 F sinθ，以后画完受力图先数分力个数。",
                    causes: [.misreadQuestion, .methodUnknown],
                    tags: ["受力分析", "月考复习"],
                    mastery: .fuzzy,
                    hoursAgo: 18
                ),
                ProblemTemplate(
                    subjectIndex: 1,
                    sourceTitle: "完形填空与语法 P.19",
                    printedHeader: "12. Fill in the blank with the proper form of the given word.",
                    printedLines: [
                        "_______ (absorb) in painting, the little girl didn’t notice the rain outside.",
                        "A. Absorbing   B. Absorbed   C. To absorb   D. Having absorbed"
                    ],
                    handwrittenLines: [
                        "主语 the little girl 是人，选了 A. Absorbing",
                        "✗ 固定搭配 be absorbed in 省略 be"
                    ],
                    hasGeometryDiagram: false,
                    answerText: "选 B (Absorbed)。短语 be absorbed in 意为“全神贯注于……”，作状语时省略 be 动词用过去分词 Absorbed。",
                    notes: "类似结构：be lost in / be buried in / be devoted to，均用过去分词作状语。",
                    causes: [.conceptUnclear],
                    tags: ["非谓语动词"],
                    mastery: .unknown,
                    hoursAgo: 32
                ),
                ProblemTemplate(
                    subjectIndex: 4,
                    sourceTitle: "化学反应速率小测",
                    printedHeader: "5. 恒温恒容密闭容器中发生反应：2SO₂(g) + O₂(g) ⇌ 2SO₃(g)  ΔH < 0。",
                    printedLines: [
                        "下列说法能证明该反应已达到化学平衡状态的是：",
                        "A. v正(SO₂) = 2v逆(O₂)    B. 容器内气体总压强不再变化",
                        "C. c(SO₂) : c(O₂) = 2 : 1  D. 混合气体密度保持不变"
                    ],
                    handwrittenLines: [
                        "我选了 D，以为气体质量会变...",
                        "✓ 正解 A, B（恒容下总质量不变，密度始终不变）"
                    ],
                    hasGeometryDiagram: false,
                    answerText: "选 AB。全气体反应总质量 m 不变，恒容时 V 不变，故 ρ = m/V 恒为定值，不能作平衡判据。",
                    notes: "判断密度 ρ 不变能否作平衡标志：先看是否全气体+恒容！",
                    causes: [.careless, .conceptUnclear],
                    tags: ["化学平衡", "易错辨析"],
                    mastery: .mastered,
                    hoursAgo: 56
                )
            ]
        }

        return [
            ProblemTemplate(
                subjectIndex: 0,
                sourceTitle: "Midterm Practice #14",
                printedHeader: "14. Find the minimum value g(a) of f(x) = x² - 2ax + 3 on the interval [0, 2].",
                printedLines: [
                    "(1) Express g(a) as a piecewise function of the real parameter a.",
                    "(2) Determine all values of a such that f(x) ≤ 1 for at least one x ∈ [0, 2]."
                ],
                handwrittenLines: [
                    "Vertex at x = a -> plugged in f(a) = 3 - a² directly",
                    "✗ Missed cases a < 0 and a > 2!"
                ],
                hasGeometryDiagram: true,
                answerText: "(1) g(a) = 3 for a < 0; g(a) = 3 - a² for 0 ≤ a ≤ 2; g(a) = 7 - 4a for a > 2.\n(2) Solve g(a) ≤ 1 to obtain a ≥ √2.",
                notes: "Always sketch the interval [0, 2] relative to the axis of symmetry before simplifying.",
                causes: [.conceptUnclear, .calculationError],
                tags: ["Quadratics", "Midterm"],
                mastery: .unknown,
                hoursAgo: 3
            ),
            ProblemTemplate(
                subjectIndex: 2,
                sourceTitle: "Mechanics Worksheet P.28",
                printedHeader: "8. A block of mass m rests on a rough 30° incline under a horizontal push F.",
                printedLines: [
                    "Given coefficient of static friction μ, find the minimum and maximum",
                    "horizontal force F required to keep the block in equilibrium."
                ],
                handwrittenLines: [
                    "Normal force N = mg cosθ  (forgot + F sinθ !)",
                    "✗ Missing horizontal component -5 pts"
                ],
                hasGeometryDiagram: true,
                answerText: "Perpendicular balance gives N = mg cosθ + F sinθ; along the plane F cosθ ± μN = mg sinθ.",
                notes: "Count every force projection along both perpendicular axes after drawing the free-body diagram.",
                causes: [.misreadQuestion, .methodUnknown],
                tags: ["Mechanics", "FreeBody"],
                mastery: .fuzzy,
                hoursAgo: 18
            ),
            ProblemTemplate(
                subjectIndex: 1,
                sourceTitle: "Grammar Review #12",
                printedHeader: "12. Choose the best option to complete the sentence.",
                printedLines: [
                    "_______ in her painting, the girl didn't notice the rain outside.",
                    "A. Absorbing   B. Absorbed   C. To absorb   D. Having absorbed"
                ],
                handwrittenLines: [
                    "Picked A because 'the girl' is a person",
                    "✗ Passive participle phrase: (Being) absorbed in"
                ],
                hasGeometryDiagram: false,
                answerText: "B (Absorbed). From 'be absorbed in', omitting 'be' leaves the past participle.",
                notes: "Watch out for similar patterns: lost in, buried in, devoted to.",
                causes: [.careless],
                tags: ["Participles"],
                mastery: .mastered,
                hoursAgo: 44
            )
        ]
    }

    // MARK: - Synthetic Exam Photo Renderer

    private static func renderProblemImage(template: ProblemTemplate) -> UIImage {
        let width: CGFloat = 1080
        let height: CGFloat = template.hasGeometryDiagram ? 760 : 580
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        return renderer.image { ctx in
            let cg = ctx.cgContext

            // Warm off-white exam paper sheet with subtle horizontal grain
            UIColor(red: 0.968, green: 0.960, blue: 0.942, alpha: 1.0).setFill()
            cg.fill(CGRect(x: 0, y: 0, width: width, height: height))

            // Faint ruled notebook/test grid lines
            UIColor(red: 0.89, green: 0.88, blue: 0.85, alpha: 0.45).setStroke()
            cg.setLineWidth(1)
            for y in stride(from: CGFloat(64), through: height - 40, by: 48) {
                cg.move(to: CGPoint(x: 36, y: y))
                cg.addLine(to: CGPoint(x: width - 36, y: y))
                cg.strokePath()
            }

            // Crisp printed black question text
            let headerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 30, weight: .semibold),
                .foregroundColor: UIColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1.0)
            ]
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 27, weight: .regular),
                .foregroundColor: UIColor(red: 0.14, green: 0.14, blue: 0.15, alpha: 1.0)
            ]

            let headerRect = CGRect(x: 52, y: 42, width: width - 104, height: 92)
            (template.printedHeader as NSString).draw(in: headerRect, withAttributes: headerAttrs)

            var cursorY: CGFloat = 138
            for line in template.printedLines {
                let rect = CGRect(x: 64, y: cursorY, width: width - (template.hasGeometryDiagram ? 360 : 120), height: 74)
                (line as NSString).draw(in: rect, withAttributes: bodyAttrs)
                cursorY += 56
            }

            // Printed diagram (parabola or incline) on right side
            if template.hasGeometryDiagram {
                let box = CGRect(x: width - 310, y: 145, width: 250, height: 220)
                UIColor(red: 0.12, green: 0.12, blue: 0.13, alpha: 1.0).setStroke()
                cg.setLineWidth(3)
                // Axes
                cg.move(to: CGPoint(x: box.minX + 20, y: box.maxY - 30))
                cg.addLine(to: CGPoint(x: box.maxX - 10, y: box.maxY - 30))
                cg.move(to: CGPoint(x: box.minX + 45, y: box.maxY - 10))
                cg.addLine(to: CGPoint(x: box.minX + 45, y: box.minY + 15))
                cg.strokePath()

                // Parabola / triangle curve in black ink
                cg.setLineWidth(3.5)
                cg.move(to: CGPoint(x: box.minX + 60, y: box.minY + 35))
                cg.addQuadCurve(
                    to: CGPoint(x: box.maxX - 30, y: box.minY + 45),
                    control: CGPoint(x: box.midX + 10, y: box.maxY - 10)
                )
                cg.strokePath()
            }

            // Blue ballpoint handwritten solution lines
            let blueInkAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 28),
                .foregroundColor: UIColor(red: 0.14, green: 0.34, blue: 0.82, alpha: 0.92)
            ]
            // Red grading correction lines
            let redInkAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor(red: 0.84, green: 0.16, blue: 0.18, alpha: 0.95)
            ]

            var handY = max(cursorY + 38, template.hasGeometryDiagram ? 410 : 320)
            for (idx, line) in template.handwrittenLines.enumerated() {
                let isRed = line.contains("✗") || line.contains("✓") || idx == template.handwrittenLines.count - 1
                let attrs = isRed ? redInkAttrs : blueInkAttrs
                (line as NSString).draw(at: CGPoint(x: 78, y: handY), withAttributes: attrs)
                handY += 54
            }

            // Red grading underline / circle annotation
            UIColor(red: 0.86, green: 0.15, blue: 0.17, alpha: 0.92).setStroke()
            cg.setLineWidth(5)
            cg.strokeEllipse(in: CGRect(x: width - 220, y: height - 150, width: 120, height: 76))
            cg.move(to: CGPoint(x: 76, y: handY - 12))
            cg.addLine(to: CGPoint(x: 420, y: handY - 18))
            cg.strokePath()
        }
    }

    private static func resolveTags(named names: [String], in context: ModelContext) -> [MistakeTag] {
        let existing = (try? context.fetch(FetchDescriptor<MistakeTag>())) ?? []
        var result: [MistakeTag] = []
        for name in names {
            if let found = existing.first(where: { $0.name == name }) {
                result.append(found)
            } else {
                let created = MistakeTag(name: name)
                context.insert(created)
                result.append(created)
            }
        }
        return result
    }
}
