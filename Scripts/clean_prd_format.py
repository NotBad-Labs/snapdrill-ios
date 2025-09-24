#!/usr/bin/env python3
import re

def clean_prd_document():
    """彻底清理PRD文档的Markdown格式问题"""

    file_path = "/Users/yimingliao/Developer/NotBad/docs/prd/NotBad 错题本 App - 产品需求文档 (PRD) v6.0.md"

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. 移除空标题（只有#符号没有内容的行）
    content = re.sub(r'^#+\s*$', '', content, flags=re.MULTILINE)

    # 2. 将强调标记的"标题"转换为真正的标题
    # **标题内容** -> ### 标题内容
    content = re.sub(r'^\*\*(.*?)\*\*\s*$', r'### \1', content, flags=re.MULTILINE)

    # 3. 修复列表标记：* 改为 -
    content = re.sub(r'^(\s*)\*(\s)', r'\1-\2', content, flags=re.MULTILINE)

    # 4. 修复列表标记后的多余空格
    content = re.sub(r'^(\s*-)\s{2,}', r'\1 ', content, flags=re.MULTILINE)

    # 5. 清理连续的空行（超过2个连续空行改为2个）
    content = re.sub(r'\n{3,}', '\n\n', content)

    # 6. 确保文档以单个换行符结尾
    content = content.rstrip() + '\n'

    # 写回文件
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print("✅ PRD文档格式清理完成")

if __name__ == "__main__":
    clean_prd_document()
