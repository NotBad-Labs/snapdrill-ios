#!/usr/bin/env python3
import re

def final_format_fix():
    """最终格式修复：添加必要的空行"""

    file_path = "/Users/yimingliao/Developer/NotBad/docs/prd/NotBad 错题本 App - 产品需求文档 (PRD) v5.1 (Swift6.2 + iOS17).md"

    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    result = []
    i = 0

    while i < len(lines):
        line = lines[i].rstrip()

        # 检查当前行是否是标题
        is_heading = re.match(r'^#{1,6}\s', line)

        # 检查前一行和后一行
        prev_line = lines[i-1].rstrip() if i > 0 else ""
        next_line = lines[i+1].rstrip() if i < len(lines) - 1 else ""

        # 如果是标题，确保前后有空行
        if is_heading:
            # 标题前需要空行（除非是文档开头）
            if i > 0 and prev_line and not prev_line.isspace():
                if result and result[-1].strip():  # 前面不是空行
                    result.append('\n')

            result.append(line + '\n')

            # 标题后需要空行（除了连续标题的特殊情况）
            if next_line and not next_line.startswith('#') and not next_line.isspace():
                result.append('\n')

        # 检查当前行是否是列表项
        elif re.match(r'^\s*-\s', line):
            # 列表前需要空行
            if i > 0 and prev_line and not prev_line.isspace() and not re.match(r'^\s*-\s', prev_line):
                if result and result[-1].strip():  # 前面不是空行
                    result.append('\n')

            result.append(line + '\n')

            # 列表后需要空行（如果下一行不是列表项）
            if next_line and not re.match(r'^\s*-\s', next_line) and not next_line.isspace():
                # 向前看，检查是否所有列表项都结束了
                j = i + 1
                while j < len(lines) and (not lines[j].strip() or re.match(r'^\s*-\s', lines[j])):
                    j += 1

                if j < len(lines) and not re.match(r'^\s*-\s', lines[j]):
                    # 找到列表结束，在最后添加空行
                    if i + 1 < len(lines) and not lines[i + 1].isspace():
                        result.append('\n')

        else:
            result.append(line + '\n')

        i += 1

    # 写回文件
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(result)

    print("✅ 最终格式修复完成")

if __name__ == "__main__":
    final_format_fix()
