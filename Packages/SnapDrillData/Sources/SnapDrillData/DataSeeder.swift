//
//  DataSeeder.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  测试数据生成器，用于开发环境下填充初始数据。
//

import SwiftData
import Foundation
import SnapDrillCore

/// 测试数据生成工具
///
/// 仅用于调试和压力测试，不参与生产流程。
public final class DataSeeder {
    
    // MARK: - Properties
    
    private let container: ModelContainer
    
    // MARK: - Initialization
    
    public init(container: ModelContainer) {
        self.container = container
    }
    
    // MARK: - Public API
    
    // 真实的 Mock 数据源 (50短 + 50长)
    // swiftlint:disable line_length
    private let mockData: [(q: String, a: String, sub: String)] = [
        // MARK: - 短文本 (Short Text)
        ("三角函数 sin(30°) 等于多少？", "1/2", "数学"),
        ("Triangle area formula?", "1/2 * base * height", "数学"),
        ("勾股定理公式是什么？", "a² + b² = c²", "数学"),
        ("what is 1+1", "2", "数学"),
        ("什么是素数？", "只能被1和它本身整除的大于1的自然数", "数学"),
        ("牛顿第二定律公式？", "F = ma", "物理"),
        ("光速约为多少？", "3 × 10⁸ m/s", "物理"),
        ("水的化学式？", "H₂O", "化学"),
        ("pH = 7 代表什么？", "中性溶液", "化学"),
        ("Identify the verb: 'She runs fast'.", "Runs", "英语"),
        ("Past tense of 'Run'?", "Ran", "英语"),
        ("Who was the first president of USA?", "George Washington", "历史"),
        ("DNA的全称？", "脱氧核糖核酸", "生物"),
        ("熊猫的主食？", "竹子", "生物"),
        ("日本的首都是？", "东京", "地理"),
        ("Capital of France?", "Paris", "地理"),
        ("《静夜思》作者？", "李白", "语文"),
        ("“采菊东篱下”下一句？", "悠然见南山", "语文"),
        ("How are you?", "I am fine, thank you.", "英语"),
        ("1kg = ? g", "1000g", "数学"),
        ("水的沸点？", "100°C", "物理"),
        ("冰的熔点？", "0°C", "物理"),
        ("人体正常体温？", "37°C", "生物"),
        ("地球自转周期？", "24小时", "地理"),
        ("太阳系最大的行星？", "木星", "地理"),
        ("《西游记》作者？", "吴承恩", "语文"),
        ("红灯停，绿灯？", "行", "常识"),
        ("Apple starts with?", "A", "英语"),
        ("1+2+3=?", "6", "数学"),
        ("2*3=?", "6", "数学"),
        ("sin(90°) = ?", "1", "数学"),
        ("cos(0°) = ?", "1", "数学"),
        ("E=mc² whose formula?", "Einstein", "物理"),
        ("H2 + O2 -> ?", "H2O", "化学"),
        ("CO2 is?", "Carbon Dioxide", "化学"),
        ("Au is symbol for?", "Gold", "化学"),
        ("Ag is symbol for?", "Silver", "化学"),
        ("Fe is symbol for?", "Iron", "化学"),
        ("Who wrote Romeo and Juliet?", "Shakespeare", "英语"),
        ("Opposite of Black?", "White", "英语"),
        ("Capital of China?", "Beijing", "地理"),
        ("Biggest ocean?", "Pacific", "地理"),
        ("Longest river?", "Nile / Amazon", "地理"),
        ("Fastest land animal?", "Cheetah", "生物"),
        ("King of jungle?", "Lion", "生物"),
        ("Largest mammal?", "Blue Whale", "生物"),
        ("Man's best friend?", "Dog", "生物"),
        ("Output of print('Hello')?", "Hello", "编程"),
        ("What language is iOS built in?", "Swift / Obj-C", "编程"),
        ("What comes after Tuesday?", "Wednesday", "常识"),
        
        // MARK: - 长文本 (Long Text)
        (
            """
            阅读理解：
            In the early 20th century, the theory of relativity transformed theoretical physics and astronomy. It superseded a 200-year-old theory of mechanics created primarily by Isaac Newton.
            
            Question: Who created the theory that relativity superseded?
            """,
            "Isaac Newton created the theory of mechanics that was superseded by the theory of relativity.",
            "英语"
        ),
        (
            """
            已知函数 f(x) = x³ - 3x + 1.
            (1) 求 f(x) 的单调区间；
            (2) 求 f(x) 在区间 [-2, 2] 上的最大值和最小值。
            """,
            """
            (1) f'(x) = 3x² - 3 = 3(x+1)(x-1).
            当 x < -1 或 x > 1 时，f'(x) > 0，函数单调递增；
            当 -1 < x < 1 时，f'(x) < 0，函数单调递减。
            所以单调增区间为 (-∞, -1) 和 (1, +∞)，单调减区间为 (-1, 1).
            
            (2) f(-2) = -8 + 6 + 1 = -1
            f(-1) = -1 + 3 + 1 = 3 (极大值)
            f(1) = 1 - 3 + 1 = -1 (极小值)
            f(2) = 8 - 6 + 1 = 3
            所以在 [-2, 2] 上，最大值为 3，最小值为 -1。
            """,
            "数学"
        ),
        (
            """
            请简述光合作用（Photosynthesis）的两个主要阶段及其发生的场所和主要产物。
            """,
            """
            光合作用主要分为两个阶段：
            
            1. 光反应阶段 (Light-dependent reactions)：
               - 场所：叶绿体类囊体薄膜 (Thylakoid membrane)。
               - 条件：光照、色素、酶。
               - 主要产物：ATP、NADPH、O₂。
               
            2. 暗反应阶段 (Light-independent reactions / Calvin Cycle)：
               - 场所：叶绿体基质 (Stroma)。
               - 条件：ATP、NADPH、CO₂、酶（不需要光，但通常在光下进行）。
               - 主要产物：有机物（如葡萄糖）和 C₅。
            """,
            "生物"
        ),
        (
            """
            Essay Question:
            Discuss the causes and effects of the Industrial Revolution in Europe during the 18th and 19th centuries. Focus on social and economic changes.
            """,
            """
            Causes:
            1. Agricultural Revolution: Increased food production supports larger population.
            2. Capital Availability: Wealth from trade available for investment.
            3. Technological Innovations: Steam engine (Watt), Spinning Jenny.
            4. Natural Resources: Coal and iron ore abundance.
            
            Effects:
            1. Urbanization: Mass movement from rural farms to factory cities.
            2. Social Classes: Rise of the industrial working class (proletariat) and bourgeoisie.
            3. Standard of Living: Initially poor working conditions, later improved availability of goods.
            4. Global Power: Shifted economic dominance to industrialized nations.
            """,
            "历史"
        ),
        (
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
            "This is a standard placeholder text used to demonstrate the visual form of a document or a typeface without relying on meaningful content. It is derived from Cicero's 'De Finibus Bonorum et Malorum'.",
            "测试"
        ),
        (
            """
            请默写《蜀道难》的第一段。
            """,
            """
            噫吁嚱，危乎高哉！
            蜀道之难，难于上青天！
            蚕丛及鱼凫，开国何茫然！
            尔来四万八千岁，不与秦塞通人烟。
            西当太白有鸟道，可以横绝峨眉巅。
            地崩山摧壮士死，然后天梯石栈相钩连。
            上有六龙回日之高标，下有冲波逆折之回川。
            黄鹤之飞尚不得过，猿猱欲度愁攀援。
            青泥何盘盘，百步九折萦岩峦。
            扪参历井仰胁息，以手抚膺坐长叹。
            """,
            "语文"
        ),
        (
            """
            Explain the difference between UIView and CALayer in iOS development.
            """,
            """
            UIView:
            - A subclass of UIResponder, handles user interactions (touches).
            - Has a CALayer backing store.
            - High-level API for layout (Auto Layout) and drawing.
            - CPU bound for some operations.
            
            CALayer:
            - Part of Core Animation.
            - Handles visual content rendering and animations.
            - Does NOT handle events/touches.
            - GPU accelerated.
            - Lightweight compared to UIView.
            """,
            "编程"
        ),
        (
            """
            Translate the following paragraph to Chinese:
            "Artificial Intelligence is a branch of computer science that aims to create systems capable of performing tasks that would normally require human intelligence, such as visual perception, speech recognition, decision-making, and translation between languages."
            """,
            """
            人工智能是计算机科学的一个分支，旨在创建能够执行通常需要人类智能才能完成的任务的系统，例如视觉感知、语音识别、决策制定和语言翻译。
            """,
            "英语"
        ),
        (
            """
            什么是一带一路（The Belt and Road Initiative）？包括哪两个主要组成部分？
            """,
            """
            “一带一路”是“丝绸之路经济带”和“21世纪海上丝绸之路”的简称。
            
            1. 丝绸之路经济带：
            主要是通过陆路连接中国与中亚、西亚、中东和欧洲。
            
            2. 21世纪海上丝绸之路：
            主要是通过海路连接中国与东南亚、南亚、东非和地中海沿岸国家。
            
            该倡议旨在促进沿线国家的政策沟通、设施联通、贸易畅通、资金融通和民心相通。
            """,
            "政治"
        ),
        (
            """
            Solve the system of equations:
            2x + 3y = 12
            x - y = 1
            """,
            """
            From equation (2): x = y + 1.
            Substitute into equation (1):
            2(y + 1) + 3y = 12
            2y + 2 + 3y = 12
            5y = 10
            y = 2.
            
            Now find x:
            x = 2 + 1 = 3.
            
            Solution: x = 3, y = 2.
            Check: 2(3) + 3(2) = 6 + 6 = 12. Correct.
            """,
            "数学"
        ),
        // ... (Repeating pattern for varied lengths)
        ("Describe the water cycle.", "Evaporation -> Condensation -> Precipitation -> Collection. Then repeats.", "地理"),
        ("Explain the properties of Acids.", "1. Sour taste.\n2. Turn blue litmus paper red.\n3. pH < 7.\n4. React with bases to form salt and water.\n5. Corrosive.", "化学"),
        ("Define 'Inflation' in economics.", "Inflation is a general increase in prices and fall in the purchasing value of money.", "经济"),
        ("What is the Pythagorean Theorem used for?", "It is used to find the length of a side of a right triangle when the other two sides are known. Formula: a² + b² = c².", "数学"),
        ("Who painted the Mona Lisa?", "Leonardo da Vinci, a Polymath of the High Renaissance who was active as a painter, draughtsman, engineer, scientist, theorist, sculptor and architect.", "艺术"),
        ("Explain 'Cloud Computing'.", "The delivery of different services through the Internet, including data storage, servers, databases, networking, and software.", "编程"),
        ("What is a Black Hole?", "A region of spacetime where gravity is so strong that nothing—no particles or even electromagnetic radiation such as light—can escape from it.", "物理"),
        ("List 5 renewable energy sources.", "1. Solar Energy\n2. Wind Energy\n3. Hydro Energy\n4. Tidal Energy\n5. Geothermal Energy", "地理"),
        ("What is the function of the Kidneys?", "Removal of toxins, metabolic waste, and excess ions from the blood; regulation of blood volume, chemical composition, and pH.", "生物"),
        ("Translate 'Failure is the mother of success' to Chinese.", "失败是成功之母。", "英语"),
        
        ("Why is the sky blue?", "Because molecules in the air scatter blue light from the sun more than they scatter red light. This scattering is called Rayleigh scattering.", "物理"),
        ("What is a stock market?", "A marketplace where securities, such as shares of public companies, are issued and traded.", "经济"),
        ("Explain the concept of 'Karma'.", "The sum of a person's actions in this and previous states of existence, viewed as deciding their fate in future existences.", "哲学"),
        ("Difference between RAM and ROM?", "RAM is volatile memory used for temporary storage while processing. ROM is non-volatile memory used for permanent storage of firmware.", "编程"),
        ("What is the Great Wall of China?", "A series of fortifications that were built across the historical northern borders of ancient Chinese states and Imperial China as protection against various nomadic groups.", "历史"),
        ("Define 'Democracy'.", "A system of government by the whole population or all the eligible members of a state, typically through elected representatives.", "政治"),
        ("What is Global Warming?", "The long-term heating of Earth's climate system observed since the pre-industrial period (between 1850 and 1900) due to human activities.", "地理"),
        ("Explain 'Supply and Demand'.", "The amount of a commodity, product, or service available and the desire of buyers for it, considered as factors regulating its price.", "经济"),
        ("What is a virus (biological)?", "A submicroscopic infectious agent that replicates only inside the living cells of an organism.", "生物"),
        ("Who is Aristotle?", "A Greek philosopher and polymath during the Classical period in Ancient Greece. Taught by Plato, was the founder of the Lyceum.", "历史"),
        
        ("Calculate 15% of 80.", "15/100 * 80 = 0.15 * 80 = 12.", "数学"),
        ("What is a Prime Meridian?", "The planet's line of zero degrees longitude. Slicing the earth along the circle of the prime meridian would divide it into Eastern and Western hemispheres.", "地理"),
        ("Explain the rules of Football (Soccer).", "1. Two teams of 11 players.\n2. Score by getting ball into opponents goal.\n3. No hands allowed (except goalie).\n4. 90 minutes game time.", "体育"),
        ("What is Jazz?", "A music genre that originated in the African-American communities of New Orleans, Louisiana, United States, in the late 19th and early 20th centuries.", "艺术"),
        ("Define 'Algorithm'.", "A process or set of rules to be followed in calculations or other problem-solving operations, especially by a computer.", "编程"),
        ("What is the purpose of the United Nations?", "To maintain international peace and security, develop friendly relations among nations, achieve international co-operation, and be a centre for harmonizing the actions of nations.", "政治"),
        ("Explain the 'Butterfly Effect'.", "The sensitive dependence on initial conditions in which a small change in one state of a deterministic nonlinear system can result in large differences in a later state.", "科普"),
        ("What is Blockchain?", "A growing list of records, called blocks, that are linked using cryptography. Each block contains a cryptographic hash of the previous block, a timestamp, and transaction data.", "编程"),
        ("Who is Marie Curie?", "A Polish and naturalized-French physicist and chemist who conducted pioneering research on radioactivity. The first woman to win a Nobel Prize.", "历史"),
        ("What is the 'Internet of Things'?", "The network of physical objects—'things'—that are embedded with sensors, software, and other technologies for the purpose of connecting and exchanging data with other devices and systems over the internet.", "编程")
    ]
    
    /// 批量生成测试数据 (100条高质量数据)
    /// - Parameter count: 忽略传入的count，固定生成 mockData 的数据
    /// - Returns: 耗时（秒）
    public func seedReviewItems(count: Int) async throws -> TimeInterval {
        let startTime = Date()
        SnapDrillLogger.generic.info("开始生成 \(self.mockData.count) 条高质量混合长短文本数据 (Background)")
        
        // Capture data needed for task to be Sendable
        let seedData = self.mockData
        let container = self.container
        
        // Detached Task to run on background thread, keeping Main Thread free
        return try await Task.detached(priority: .userInitiated) {
            let context = ModelContext(container)
            // Disable autosave for batch
            context.autosaveEnabled = false
            
            // 扩展数据以达到请求的数量（如果需要更多）
            var targetData = seedData
            while targetData.count < count {
                targetData.append(contentsOf: seedData)
            }
            // 预定义源池
            let sourcePool = ["模拟考试", "课本习题", "课外辅导", "网络资源", "历年真题"]
            
            // 1. 同步所有学科 (Subjects)
            let uniqueSubjects = Set(targetData.map { $0.sub })
            for subName in uniqueSubjects {
                let fetch = FetchDescriptor<SubjectModel>(predicate: #Predicate<SubjectModel> { $0.name == subName })
                if (try? context.fetch(fetch).first) == nil {
                    // 简单的图标映射逻辑
                    let icon = subName == "数学" ? "function" : 
                               subName == "物理" ? "atom" : 
                               subName == "化学" ? "flask" : 
                               subName == "生物" ? "leaf" : 
                               subName == "英语" ? "textformat.abc" : "book"
                    
                    let newSub = SubjectModel(name: subName, icon: icon, colorHex: "#4A90E2", sortOrder: 0)
                    context.insert(newSub)
                }
            }
            
            // 2. 同步所有来源 (Sources)
            for sourceName in sourcePool {
                let fetch = FetchDescriptor<SourceModel>(predicate: #Predicate<SourceModel> { $0.name == sourceName })
                if (try? context.fetch(fetch).first) == nil {
                    let icon = sourceName.contains("考试") ? "doc.text.fill" :
                               sourceName.contains("习题") ? "book.closed.fill" :
                               sourceName.contains("网络") ? "globe" : "folder"
                    
                    let newSource = SourceModel(name: sourceName, icon: icon, colorHex: "#808080")
                    context.insert(newSource)
                }
            }
            
            // 预定义标签池
            let tagPool = ["必考", "易错", "真题", "重点", "压轴", "2024", "基础", "难点"]
            
            for (index, data) in targetData.enumerated() {
                // 随机生成 0-3 个标签
                let tagCount = Int.random(in: 0...3)
                var assignedTags: [TagModel] = []
                if tagCount > 0 {
                    let randomTags = tagPool.shuffled().prefix(tagCount)
                    for tagName in randomTags {
                        // 查找或创建标签 (Simple logic for seeding)
                        let fetch = FetchDescriptor<TagModel>(predicate: #Predicate<TagModel> { $0.name == tagName })
                        if let existing = try? context.fetch(fetch).first {
                            assignedTags.append(existing)
                        } else {
                            let newTag = TagModel(name: tagName)
                            context.insert(newTag)
                            assignedTags.append(newTag)
                        }
                    }
                }
                
                let item = ReviewItemModel(
                    content: data.q,
                    imagePath: nil,
                    subject: data.sub,
                    source: ["模拟考试", "课本习题", "课外辅导", "网络资源", "历年真题"].randomElement()!,
                    tags: assignedTags
                )
                item.answerText = data.a
                item.difficulty = Int.random(in: 1...5) // 随机难度 1-5
                
                // 随机化复习状态
                item.createdAt = Date.now.addingTimeInterval(-Double.random(in: 0...(86400 * 5)))
                
                if index < Int(Double(count) * 0.8) {
                    item.nextReviewAt = Date.now.addingTimeInterval(-Double.random(in: 100...86400))
                } else {
                    item.nextReviewAt = Date.now.addingTimeInterval(Double.random(in: 3600...86400))
                }
                
                context.insert(item)
            }
            
            try context.save()
            return Date().timeIntervalSince(startTime)
        }.value
    }
    
    /// 清空所有 ReviewItem
    public func clearAll() async throws {
        let container = self.container
        try await Task.detached(priority: .userInitiated) {
            let context = ModelContext(container)
            try context.delete(model: ReviewItemModel.self)
            try context.save()
        }.value
    }
}
