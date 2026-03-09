---
description: 自动审计代码库是否违反全局禁令（如 print, any 类型）及安全风险
---

# 代码合规与安全审计工作流

本工作流用于在开发过程中快速检测代码是否违反了开发规约，并进行安全风险扫描。

---

## 一、代码风格审计

### 禁止事项

| 项目 | 说明 |
|---|---|
| `print()` | 生产代码禁止使用 |
| `any` 类型 | Swift 6 代码禁止使用（已批准例外见 `.claude/principles.md` 约束 4） |
| 硬编码敏感字串 | 扫描 `API_KEY`, `PASSWORD` 等 |

### 强制要求

| 项目 | 说明 |
|---|---|
| `SnapDrillLogger` | 必须用于记录日志 |
| `do-catch` | 异步操作必须包含 |

### 执行命令

// turbo

```bash
./Scripts/lint.sh
```

---

## 二、安全风险审计 (Security Audit)

> 基于 OWASP Top 10 和专家报告的安全建议

### 2.1 注入攻击风险

```
请扫描以下注入风险：
1. SQL 注入：是否使用参数化查询？
2. 命令注入：是否对用户输入进行转义？
3. 路径遍历：文件路径是否经过验证？
```

// turbo

```bash
grep -rn "String(format:" --include="*.swift" SnapDrill/ Packages/ || echo "✅ 无 String format 风险"
```

### 2.2 敏感信息暴露

```
请扫描敏感信息暴露风险：
1. API Key / Token 是否硬编码？
2. 密码是否明文存储？
3. 日志中是否包含敏感信息？
```

// turbo

```bash
grep -rniE "(api_key|apikey|secret|password|token)" --include="*.swift" SnapDrill/ Packages/ | grep -v "\.git" || echo "✅ 无明显敏感信息"
```

### 2.3 依赖漏洞

```
请检查第三方依赖：
1. 是否有已知漏洞的库版本？
2. 是否有过时或不再维护的依赖？
3. 是否有不必要的权限请求？
```

// turbo

```bash
swift package show-dependencies --package-path Packages/SnapDrillCore 2>/dev/null || echo "请在 Package 目录运行"
```

---

## 三、上下文注入防御

> 基于专家报告的"上下文注入"攻击防御

```
请检查以下防御措施：
1. 从外部读取的文件是否经过验证？
2. 用户输入是否直接拼接到提示词中？
3. AI 代理是否在沙盒环境运行？
```

---

## 四、审计报告模板

完成审计后，生成报告：

```markdown
## 审计报告

| 维度 | 状态 | 发现 |
|---|:---:|---|
| 代码风格 | ✅/⚠️/❌ | ... |
| 注入风险 | ✅/⚠️/❌ | ... |
| 敏感信息 | ✅/⚠️/❌ | ... |
| 隐私合规 | ✅/⚠️/❌ | ... |
| 依赖漏洞 | ✅/⚠️/❌ | ... |

**总体评估**: [通过/需要修复/高风险]
```

---

## 建议

- 在每次提交代码 (Commit) 或发起 PR 前，请运行此审计
- 重大功能上线前，执行完整的安全审计流程
