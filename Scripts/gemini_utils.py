#!/usr/bin/env python3
# 核心职责：Gemini API 调用工具，提供带自动降级的模型路由
# 注：Scripts/ 目录下的 CI Python 脚本使用 print() 输出到 GitHub Actions 日志，
#     SnapDrillLogger 是 Swift 框架不适用于此，CLAUDE.md 的 print() 禁令仅适用于 Swift 代码。

import json
import urllib.request
import urllib.error

GEMINI_API_BASE = "https://generativelanguage.googleapis.com/v1beta"

# 模型降级链（2026-03，基于 https://ai.google.dev/gemini-api/docs/models）
#
# 深度审查链（全模块架构 review，~300K 字符，需要最强推理）：
#   gemini-3.1-pro-preview → gemini-2.5-pro → gemini-2.5-flash
#
# 快速审查链（PR diff review，~40K 字符，GA 稳定优先）：
#   gemini-2.5-flash → gemini-2.5-pro
#
# Flash Preview（gemini-3-flash-preview / gemini-3.1-flash-lite-preview）
# 未纳入：同为 Preview 阶段，与 3.1-pro-preview 共享不稳定基础设施，
#          无法作为可靠降级目标；gemini-2.5-flash（GA）已满足快速审查需求。
# gemini-3-pro-preview：3月9日下线，已排除。
# gemini-2.0-flash：弃用中，已排除。

MODELS_DEEP = [
    "gemini-3.1-pro-preview",   # 最强推理，Preview 持续 503 时自动降级
    "gemini-2.5-pro",           # GA 稳定，能力接近 3.1-pro，首选备用
    "gemini-2.5-flash",         # GA 稳定快，兜底保证审查能完成
]

MODELS_FAST = [
    "gemini-2.5-flash",         # GA 稳定快，PR diff 首选
    "gemini-2.5-pro",           # GA 稳定，flash 失败时升级保障质量
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
