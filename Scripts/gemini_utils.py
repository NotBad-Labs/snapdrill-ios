#!/usr/bin/env python3
# 核心职责：Gemini API 调用工具，提供带自动降级的模型路由

import json
import urllib.request
import urllib.error

# 模型降级链（2026-03，基于 https://ai.google.dev/gemini-api/docs/models）
# 按代码审查能力 + 稳定性排序：
# - gemini-3.1-pro-preview：最强推理，Preview 阶段持续 503
# - gemini-2.5-pro：GA 稳定，能力接近 3.1-pro，首选备用
# - gemini-2.5-flash：GA 稳定快，兜底保证审查能完成
# 已排除：gemini-3-pro-preview（3月9日下线）、gemini-2.0-flash（弃用中）
GEMINI_MODELS = [
    "gemini-3.1-pro-preview",
    "gemini-2.5-pro",
    "gemini-2.5-flash",
]

GEMINI_API_BASE = "https://generativelanguage.googleapis.com/v1beta"


def call_gemini_with_fallback(
    prompt_text: str,
    api_key: str,
    timeout: int = 300,
    temperature: float = 0.1,
) -> tuple[str, str]:
    """
    依次尝试 GEMINI_MODELS，遇到 5xx / 429 / 超时 / 连接错误自动降级。
    返回 (响应文本, 实际使用的模型名)。
    4xx（401/403 认证错误）不重试，直接抛出。
    """
    payload = {
        "contents": [{"parts": [{"text": prompt_text}]}],
        "generationConfig": {"temperature": temperature},
    }
    last_error = None
    for model in GEMINI_MODELS:
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
