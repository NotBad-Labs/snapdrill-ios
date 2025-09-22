#!/usr/bin/env python3
"""
修复PRD文档开头的严重格式问题
"""

def fix_document_header():
    file_path = "/Users/yimingliao/Developer/NotBad/docs/prd/NotBad 错题本 App - 产品需求文档 (PRD) v6.0.md"

    # 读取文件
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 重建正确的文档开头
    new_header = """# NotBad 错题本 App - 产品需求文档 (PRD) v6.0

**文档定位：单一事实来源 (Single Source of Truth)**

本文档是NotBad App从概念到发布的全周期产品需求定义的**唯一权威来源**。它旨在为产品、设计、开发、测试、运营及管理团队提供统一的、无歧义的行动纲领。所有与产品需求相关的讨论、决策和实现，均须以此文档为基准。

## 文档优先级与变更准则 (Governance)

- 单一事实来源 (SSoT): 本PRD为产品范围、功能、NFR与指标的唯一权威来源。
- 从属关系:
  - TDD 细化实现与技术约束，必须与PRD一致；冲突时以PRD为准。
  - RTM 建立PRD→TDD→测试的双向追踪，不改变需求本身。"""

    # 找到第一个 "## " 标题（不包括空标题）
    lines = content.split('\n')
    first_real_section_index = -1

    for i, line in enumerate(lines):
        if line.strip().startswith('## ') and len(line.strip()) > 3:
            first_real_section_index = i
            break

    if first_real_section_index > 0:
        # 保留从第一个真实章节开始的内容
        remaining_content = '\n'.join(lines[first_real_section_index:])

        # 重建完整文档
        fixed_content = new_header + "\n\n" + remaining_content

        # 写回文件
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(fixed_content)

        print("✅ 文档开头格式修复完成")
    else:
        print("❌ 找不到有效的章节开始位置")

if __name__ == "__main__":
    fix_document_header()
