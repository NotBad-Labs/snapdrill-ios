#!/bin/zsh

# 环境变量设置脚本
# 帮助用户设置GitHub Actions自托管运行器的配置

echo "=========================================="
echo "GitHub Actions 自托管运行器配置"
echo "=========================================="
echo ""

# 获取GitHub仓库信息
echo "请输入GitHub仓库信息："
echo ""
read -p "GitHub仓库地址（格式：owner/repo，如：yimingliao/NotBad）: " GITHUB_REPO

if [[ -z "$GITHUB_REPO" ]]; then
    echo "错误：仓库地址不能为空"
    exit 1
fi

echo ""
echo "请输入GitHub Personal Access Token："
echo "（可以在 https://github.com/settings/tokens 生成）"
read -s -p "Token: " GITHUB_TOKEN
echo ""

if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "错误：Token不能为空"
    exit 1
fi

# 群晖配置
echo ""
echo "是否配置群晖存储？(y/N): "
read USE_SYNO

if [[ "$USE_SYNO" =~ ^[Yy]$ ]]; then
    echo ""
    echo "请输入群晖配置信息："
    read -p "群晖IP地址: " SMB_HOST
    read -p "SMB用户名: " SMB_USER
    read -p "SMB共享名称: " SHARE_NAME
    
    if [[ -z "$SMB_HOST" || -z "$SMB_USER" || -z "$SHARE_NAME" ]]; then
        echo "警告：群晖配置不完整，将跳过群晖存储配置"
        USE_SYNO="n"
    fi
fi

# 运行器配置
echo ""
echo "请输入运行器配置（可选，直接回车使用默认值）："
read -p "运行器名称（默认：mac-mini-m4）: " RUNNER_NAME
read -p "运行器标签（默认：self-hosted,macos,m4,xcode-16-4）: " RUNNER_LABELS

# 设置默认值
RUNNER_NAME=${RUNNER_NAME:-mac-mini-m4}
RUNNER_LABELS=${RUNNER_LABELS:-self-hosted,macos,m4,xcode-16-4}

# 显示配置确认
echo ""
echo "=========================================="
echo "配置确认"
echo "=========================================="
echo "GitHub仓库：$GITHUB_REPO"
echo "运行器名称：$RUNNER_NAME"
echo "运行器标签：$RUNNER_LABELS"
if [[ "$USE_SYNO" =~ ^[Yy]$ ]]; then
    echo "群晖配置：$SMB_HOST/$SHARE_NAME ($SMB_USER)"
else
    echo "群晖配置：未配置"
fi
echo ""

read -p "确认配置并开始安装？(y/N): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "安装已取消"
    exit 0
fi

# 设置环境变量
export GITHUB_REPO
export GITHUB_TOKEN
export RUNNER_NAME
export RUNNER_LABELS

if [[ "$USE_SYNO" =~ ^[Yy]$ ]]; then
    export SMB_HOST
    export SMB_USER
    export SHARE_NAME
fi

echo ""
echo "环境变量已设置，开始安装..."
echo ""

# 运行安装脚本
sudo ./Scripts/install_runner.sh
