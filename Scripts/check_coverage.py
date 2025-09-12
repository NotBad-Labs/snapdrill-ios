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

def parse_coverage_report(coverage_file):
    """解析Xcode生成的覆盖率报告"""
    try:
        with open(coverage_file, 'r') as f:
            coverage_data = json.load(f)
        
        # 提取覆盖率数据
        total_lines = 0
        covered_lines = 0
        
        for target in coverage_data.get('targets', []):
            for file_data in target.get('files', []):
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
    
    args = parser.parse_args()
    
    coverage_percentage, covered_lines, total_lines = parse_coverage_report(args.coverage_file)
    
    print(f"📊 代码覆盖率: {coverage_percentage:.2f}%")
    print(f"📝 覆盖行数: {covered_lines}/{total_lines}")
    
    if coverage_percentage >= args.threshold:
        print(f"✅ 覆盖率达标 (>= {args.threshold}%)")
        sys.exit(0)
    else:
        print(f"❌ 覆盖率不达标 (< {args.threshold}%)")
        sys.exit(1)

if __name__ == "__main__":
    main()
