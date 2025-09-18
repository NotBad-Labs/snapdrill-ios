#!/usr/bin/env python3
"""
修复PRD文档的Markdown格式问题
"""
import re

def fix_markdown_issues(content):
    """修复常见的Markdown格式问题"""

    # 1. MD004: 将 * 改为 - 用于无序列表
    content = re.sub(r'^(\s*)(\*)', r'\1-', content, flags=re.MULTILINE)

    # 2. MD030: 修复列表标记后的空格（应该只有1个）
    content = re.sub(r'^(\s*[-*])\s{2,}', r'\1 ', content, flags=re.MULTILINE)

    # 3. MD036: 将强调标记用作标题的改为正确格式
    # 将 **标题**: 改为 ### 标题
    content = re.sub(r'^\*\*(.*?)\*\*:?\s*$', r'### \1', content, flags=re.MULTILINE)

    # 4. MD022: 标题前后需要空行
    # 在标题前添加空行（如果没有）
    content = re.sub(r'(?<!\n\n)(^#{1,6}\s.*)', r'\n\1', content, flags=re.MULTILINE)
    # 在标题后添加空行（如果没有）
    content = re.sub(r'(^#{1,6}\s.*?)(?!\n\n)', r'\1\n', content, flags=re.MULTILINE)

    # 5. MD032: 列表前后需要空行
    # 在列表前添加空行
    content = re.sub(r'(?<!\n\n)(^(\s*[-*]\s))', r'\n\1', content, flags=re.MULTILINE)
    # 在列表后添加空行
    lines = content.split('\n')
    result_lines = []
    in_list = False

    for i, line in enumerate(lines):
        result_lines.append(line)

        # 检查当前行是否是列表项
        current_is_list = re.match(r'^\s*[-*]\s', line)

        # 检查下一行是否是列表项
        next_is_list = False
        if i + 1 < len(lines):
            next_is_list = re.match(r'^\s*[-*]\s', lines[i + 1])

        # 如果当前行是列表项，下一行不是列表项且不是空行，则添加空行
        if current_is_list and i + 1 < len(lines) and not next_is_list and lines[i + 1].strip():
            result_lines.append('')

    content = '\n'.join(result_lines)

    # 6. 清理多余的空行（连续3个以上空行改为2个）
    content = re.sub(r'\n{3,}', '\n\n', content)

    return content

def main():
    file_path = "/Users/yimingliao/Developer/NotBad/docs/prd/NotBad 错题本 App - 产品需求文档 (PRD) v5.1 (Swift6.2 + iOS17).md"

    # 读取文件
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 修复格式问题
    fixed_content = fix_markdown_issues(content)

    # 写回文件
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(fixed_content)

    print("✅ PRD文档Markdown格式修复完成")

if __name__ == "__main__":
    main()
