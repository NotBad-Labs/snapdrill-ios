# check_coverage.py
# NotBad
#
# Created by YIMING LIAO on 2025/9/5.
#
#!/usr/bin/env python3
# Scripts/check_coverage.py
"""检查代码覆盖率是否达到阈值"""

import json
import sys
import argparse
import os
import re

def parse_coverage_report(coverage_file, include_target_regex=None, exclude_path_regex=None):
    """解析Xcode生成的覆盖率报告"""
    try:
        with open(coverage_file, 'r') as f:
            coverage_data = json.load(f)
        
        # 提取覆盖率数据
        total_lines = 0
        covered_lines = 0
        
        target_pattern = re.compile(include_target_regex) if include_target_regex else None
        path_pattern = re.compile(exclude_path_regex) if exclude_path_regex else None

        for target in coverage_data.get('targets', []):
            # 仅包含匹配的 target（若设置）
            if target_pattern:
                name = target.get('name', '')
                if not target_pattern.search(name):
                    continue
            for file_data in target.get('files', []):
                path = file_data.get('path', '')
                # 排除匹配的文件路径（若设置）
                if path_pattern and path and path_pattern.search(path):
                    continue
                total_lines += file_data.get('executableLines', 0)
                covered_lines += file_data.get('coveredLines', 0)
        
        coverage_percentage = (covered_lines / total_lines * 100) if total_lines > 0 else 0
        return coverage_percentage, covered_lines, total_lines
        
    except Exception as e:
        print(f"❌ 解析覆盖率报告失败: {e}")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description='检查代码覆盖率')
    parser.add_argument('coverage_file', help='覆盖率报告文件路径')
    parser.add_argument('threshold', type=float, help='覆盖率阈值')
    parser.add_argument('--warn-threshold', type=float, default=None, help='警告阈值（可选）')
    parser.add_argument('--show-details', action='store_true', help='显示详细覆盖率信息')
    parser.add_argument('--include-target-regex', default=os.environ.get('COVERAGE_INCLUDE_TARGET_REGEX'), help='仅统计匹配该正则的 target（可选）')
    parser.add_argument('--exclude-path-regex', default=os.environ.get('COVERAGE_EXCLUDE_REGEX'), help='排除匹配该正则的文件路径（可选）')
    
    args = parser.parse_args()
    
    coverage_percentage, covered_lines, total_lines = parse_coverage_report(
        args.coverage_file,
        include_target_regex=args.include_target_regex,
        exclude_path_regex=args.exclude_path_regex,
    )
    
    print(f"📊 代码覆盖率: {coverage_percentage:.2f}%")
    print(f"📝 覆盖行数: {covered_lines}/{total_lines}")
    print(f"🎯 目标阈值: {args.threshold}%")
    
    # 显示详细信息
    if args.show_details:
        print(f"📈 覆盖率趋势: {'上升' if coverage_percentage >= args.threshold else '需要提升'}")
        print(f"💡 建议: {'保持当前水平' if coverage_percentage >= args.threshold else '增加测试用例'}")
    
    # 检查警告阈值
    if args.warn_threshold and coverage_percentage < args.warn_threshold:
        print(f"⚠️ 覆盖率低于警告阈值 ({args.warn_threshold}%)")
    
    # 主阈值检查
    if coverage_percentage >= args.threshold:
        print(f"✅ 覆盖率达标 (>= {args.threshold}%)")
        sys.exit(0)
    else:
        print(f"❌ 覆盖率不达标 (< {args.threshold}%)")
        print(f"📊 需要提升: {args.threshold - coverage_percentage:.2f}%")
        sys.exit(1)

if __name__ == "__main__":
    main()
