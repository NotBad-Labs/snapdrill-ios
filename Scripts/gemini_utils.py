#!/usr/bin/env python3
# 核心职责：Gemini API 调用工具，提供带自动降级的模型路由
# 注：Scripts/ 目录下的 CI Python 脚本使用 print() 输出到 GitHub Actions 日志，
#     SnapDrillLogger 是 Swift 框架不适用于此，CLAUDE.md 的 print() 禁令仅适用于 Swift 代码。

import json
import urllib.request
import urllib.error

GEMINI_API_BASE = "https://generativelanguage.googleapis.com/v1beta"

# 模型降级链（2026-05-25 刷新，对齐 docs/tech/reference/agent-cli-models.md）
#
# Gemini 3.5 Flash GA（2026-05-19 Google IO 发布）已通过直接 API 端点
# generativelanguage.googleapis.com 可达，model ID = "gemini-3.5-flash"。
# gemini-cli 0.42.0 OAuth Code Assist endpoint 滞后于 GA，CLI 直接传该 ID 报 404；
# 本脚本走直接 API，model ID 接受 GA 字面值。
#
# 深度审查链（全模块架构 review，~300K 字符）：
#   3.5-flash（GA 首选，user-decision-log #012 主笔候选裁决依据）→
#   3.1-flash-lite-preview（成本兜底）→ 2.5-pro（旧 GA 兜底）→ 2.5-flash（最低兜底）
#
# 快速审查链（PR diff review，~40K 字符）：
#   3.5-flash（GA 首选）→ 3.1-flash-lite-preview（成本兜底）→ 2.5-flash（最低兜底）
#
# 已排除：gemini-3-pro-preview（3月9日下线）、gemini-2.0-flash（弃用中）

MODELS_DEEP = [
    "gemini-3.5-flash",               # 2026-05-19 GA，首选；user-decision-log #012 裁决
    "gemini-3.1-flash-lite-preview",  # 成本兜底
    "gemini-2.5-pro",                 # 旧 GA 兜底
    "gemini-2.5-flash",               # 最低兜底
]

MODELS_FAST = [
    "gemini-3.5-flash",               # GA 首选
    "gemini-3.1-flash-lite-preview",  # 成本兜底
    "gemini-2.5-flash",               # 最低兜底
]


def call_gemini_with_fallback(
    prompt_text: str,
    api_key: str,
    timeout: int = 300,
    temperature: float = 0.1,
    models: list[str] | None = None,
) -> tuple[str, str]:
    """
    依次尝试 models 列表中的模型，遇到 5xx / 429 / 超时 / 连接错误自动降级。
    返回 (响应文本, 实际使用的模型名)。
    4xx（401/403 认证错误）不重试，直接抛出。

    models 默认使用 MODELS_DEEP（深度审查链）。
    PR diff 等轻量任务传入 MODELS_FAST 使用快速审查链。
    """
    if models is None:
        models = MODELS_DEEP
    payload = {
        "contents": [{"parts": [{"text": prompt_text}]}],
        "generationConfig": {"temperature": temperature},
    }
    last_error = None
    for model in models:
        url = f"{GEMINI_API_BASE}/models/{model}:generateContent?key={api_key}"
        print(f"尝试模型：{model}...")
        try:
            req = urllib.request.Request(
                url,
                data=json.dumps(payload).encode("utf-8"),
                headers={"Content-Type": "application/json"},
            )
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                result = json.loads(resp.read())
                text = result["candidates"][0]["content"]["parts"][0]["text"]
                print(f"✅ 成功（模型：{model}）")
                return text, model
        except urllib.error.HTTPError as e:
            # 5xx 服务器错误和 429 限流均触发降级，4xx 认证/权限错误直接抛出
            if e.code == 429 or e.code >= 500:
                print(f"⚠️ {model} 返回 HTTP {e.code}，降级到下一个模型...")
                last_error = e
                continue
            else:
                raise
        except Exception as e:
            print(f"⚠️ {model} 调用失败（{e}），降级到下一个模型...")
            last_error = e
            continue
    raise RuntimeError(f"所有模型均不可用，最后错误：{last_error}")
