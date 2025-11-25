//
//  KnowledgePointsTests.swift
//  NotBadTests
//
//  知识点值对象单元测试
//

import Testing
import Foundation
@testable import NotBad

@Suite("KnowledgePoints 值对象测试")
struct KnowledgePointsTests {
    
    // MARK: - 初始化测试
    
    @Test("从逗号分隔字符串初始化")
    func initFromCommaSeparatedString() {
        let kp = KnowledgePoints(from: "函数, 导数, 极限")
        
        #expect(kp.count == 3)
        #expect(kp.contains("函数"))
        #expect(kp.contains("导数"))
        #expect(kp.contains("极限"))
    }
    
    @Test("从逗号分隔字符串初始化（英文逗号）")
    func initFromChineseCommaSeparatedString() {
        // 注意：只支持英文逗号分隔
        let kp = KnowledgePoints(from: "三角函数,正弦,余弦")
        
        #expect(kp.count == 3)
        #expect(kp.contains("三角函数"))
    }
    
    @Test("自动去除空白和空值")
    func trimWhitespaceAndEmpty() {
        let kp = KnowledgePoints(from: "  函数  ,  , 导数 ,   ")
        
        #expect(kp.count == 2)
        #expect(kp.contains("函数"))
        #expect(kp.contains("导数"))
    }
    
    @Test("从数组初始化")
    func initFromArray() {
        let kp = KnowledgePoints(["圆锥曲线", "椭圆", "抛物线"])
        
        #expect(kp.count == 3)
    }
    
    @Test("空字符串生成空知识点")
    func emptyStringCreatesEmpty() {
        let kp = KnowledgePoints(from: "")
        
        #expect(kp.isEmpty)
        #expect(kp.count == 0)
    }
    
    // MARK: - 集合操作测试
    
    @Test("支持 Sequence 协议")
    func sequenceConformance() {
        let kp = KnowledgePoints(["A", "B", "C"])
        
        var items: [String] = []
        for item in kp {
            items.append(item)
        }
        
        #expect(items.count == 3)
    }
    
    @Test("支持下标访问")
    func subscriptAccess() {
        let kp = KnowledgePoints(["第一", "第二", "第三"])
        
        #expect(kp[0] == "第一")
        #expect(kp[1] == "第二")
        #expect(kp[2] == "第三")
    }
    
    @Test("添加知识点")
    func addingPoint() {
        let kp = KnowledgePoints(["A", "B"])
        let newKp = kp.adding("C")
        
        #expect(newKp.count == 3)
        #expect(newKp.contains("C"))
        // 原值不变
        #expect(kp.count == 2)
    }
    
    @Test("添加重复知识点不会增加")
    func addingDuplicatePoint() {
        let kp = KnowledgePoints(["A", "B"])
        let newKp = kp.adding("A")
        
        #expect(newKp.count == 2)
    }
    
    @Test("移除知识点")
    func removingPoint() {
        let kp = KnowledgePoints(["A", "B", "C"])
        let newKp = kp.removing("B")
        
        #expect(newKp.count == 2)
        #expect(!newKp.contains("B"))
    }
    
    // MARK: - 搜索匹配测试
    
    @Test("精确匹配")
    func exactMatch() {
        let kp = KnowledgePoints(["函数", "导数", "极限"])
        
        #expect(kp.matches("函数"))
        #expect(kp.matches("导数"))
        #expect(!kp.matches("积分"))
    }
    
    @Test("部分匹配")
    func partialMatch() {
        let kp = KnowledgePoints(["三角函数", "反三角函数", "幂函数"])
        
        #expect(kp.matches("函数"))  // 部分匹配
        #expect(kp.matches("三角"))  // 部分匹配
    }
    
    @Test("大小写不敏感匹配")
    func caseInsensitiveMatch() {
        let kp = KnowledgePoints(["DNA", "RNA", "Protein"])
        
        #expect(kp.matches("dna"))
        #expect(kp.matches("rna"))
        #expect(kp.matches("protein"))
    }
    
    // MARK: - rawValue 测试
    
    @Test("rawValue 正确序列化")
    func rawValueSerialization() {
        let kp = KnowledgePoints(["A", "B", "C"])
        
        // rawValue 使用 ", " (带空格) 分隔
        #expect(kp.rawValue == "A, B, C")
    }
    
    @Test("空知识点 rawValue 为空字符串")
    func emptyRawValue() {
        let kp = KnowledgePoints.empty
        
        #expect(kp.rawValue == "")
    }
    
    // MARK: - 编码测试
    
    @Test("Codable 正确编解码")
    func codableRoundTrip() throws {
        let original = KnowledgePoints(["导数", "积分", "微分"])
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(KnowledgePoints.self, from: data)
        
        #expect(decoded == original)
    }
}
