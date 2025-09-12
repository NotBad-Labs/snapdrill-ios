# extract_performance_metrics.py
# NotBad
#
# Created by YIMING LIAO on 2025/9/5.
#
#!/usr/bin/env python3
# Scripts/extract_performance_metrics.py
"""提取性能测试指标"""

import json
import sys
import subprocess
import re

def extract_performance_metrics(xcresult_path):
    """从xcresult中提取性能指标"""
    try:
        # 使用xcresulttool提取测试结果
        cmd = [
            'xcrun', 'xcresulttool', 'get',
            'object', '--legacy',
            '--format', 'json',
            '--path', xcresult_path
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"❌ 提取测试结果失败: {result.stderr}")
            sys.exit(1)
            
        data = json.loads(result.stdout)
        
        # 提取性能测试数据
        performance_metrics = {}
        
        # 查找性能测试结果
        def find_performance_tests(obj):
            if isinstance(obj, dict):
                if 'testStatus' in obj and 'performanceMetrics' in obj:
                    test_name = obj.get('identifier', 'unknown')
                    metrics = obj['performanceMetrics']
                    performance_metrics[test_name] = {
                        'baseline': metrics.get('baseline', 0),
                        'measurements': metrics.get('measurements', []),
                        'average': sum(metrics.get('measurements', [])) / len(metrics.get('measurements', [1])),
                        'maxRegression': metrics.get('maxRegression', 0.1)
                    }
                
                for value in obj.values():
                    find_performance_tests(value)
            elif isinstance(obj, list):
                for item in obj:
                    find_performance_tests(item)
        
        find_performance_tests(data)
        
        # 保存性能指标
        with open('performance_metrics.json', 'w') as f:
            json.dump(performance_metrics, f, indent=2)
            
        print(f"📊 提取到 {len(performance_metrics)} 个性能测试指标")
        for test_name, metrics in performance_metrics.items():
            print(f"  {test_name}: 平均 {metrics['average']:.3f}s")
            
    except Exception as e:
        print(f"❌ 提取性能指标失败: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("用法: python3 extract_performance_metrics.py <xcresult_path>")
        sys.exit(1)
        
    extract_performance_metrics(sys.argv[1])
