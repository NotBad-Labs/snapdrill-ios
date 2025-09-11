#
//  setup_ci.sh
//  NotBad
//
//  Created by YIMING LIAO on 2025/9/5.
//
#!/bin/bash
# Scripts/setup_ci.sh
"""设置CI环境的脚本"""

set -e

echo "🚀 设置 NotBad CI/CD 环境..."

# 1. 创建必要的目录
mkdir -p .github/workflows
mkdir -p Scripts
mkdir -p TestPlans

# 2. 设置脚本权限
chmod +x Scripts/*.py
chmod +x Scripts/*.sh

# 3. 创建 ExportOptions.plist
cat > ExportOptions.plist << EOF
}
