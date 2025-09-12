# check_performance_regression.py
# NotBad
#
# Created by YIMING LIAO on 2025/9/5.
#
#!/usr/bin/env python3
# Scripts/check_performance_regression.py
"""检查性能回退"""

import json
import sys
import os

def load_baseline_metrics():
    """加载基线性能指标"""
    baseline_file = 'performance_baseline.json'
    if not os.path.exists(baseline_file):
        print("⚠️ 未找到基线性能指标，跳过回退检查")
        return {}
        
    with open(baseline_file, 'r') as f:
        return json.load(f)

def load_current_metrics():
    """加载当前性能指标"""
    metrics_file = 'performance_metrics.json'
    if not os.path.exists(metrics_file):
        print("❌ 未找到当前性能指标")
        sys.exit(1)
        
    with open(metrics_file, 'r') as f:
        return json.load(f)

def check_regression(baseline, current, threshold=0.1):
    """检查性能回退"""
    regressions = []
    
    for test_name, current_metrics in current.items():
        if test_name not in baseline:
            print(f"ℹ️ 新增性能测试: {test_name}")
            continue
            
        baseline_avg = baseline[test_name]['average']
        current_avg = current_metrics['average']
        
        # 计算性能变化百分比
        change_percent = (current_avg - baseline_avg) / baseline_avg
        
        if change_percent > threshold:
            regressions.append({
                'test': test_name,
                'baseline': baseline_avg,
                'current': current_avg,
                'regression': change_percent
            })
            
    return regressions

def main():
    baseline_metrics = load_baseline_metrics()
    current_metrics = load_current_metrics()
    
    if not baseline_metrics:
        # 如果没有基线，将当前指标设为基线
        with open('performance_baseline.json', 'w') as f:
            json.dump(current_metrics, f, indent=2)
        print("✅ 已设置性能基线")
        return
    
    regressions = check_regression(baseline_metrics, current_metrics)
    
    if not regressions:
        print("✅ 未发现性能回退")
        return
    
    print(f"❌ 发现 {len(regressions)} 个性能回退:")
    for regression in regressions:
        print(f"  {regression['test']}: "
              f"{regression['baseline']:.3f}s → {regression['current']:.3f}s "
              f"({regression['regression']:.1%} 劣化)")
    
    sys.exit(1)

if __name__ == "__main__":
    main()
