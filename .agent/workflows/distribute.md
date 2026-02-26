---
description: 执行应用打包并上传至 TestFlight 的完整流程
---

# TestFlight 分发工作流

本工作流通过脚本自动完成打包、导出和上传流程。

## 前置要求 (Pre-requisites)

确保当前环境具备以下环境变量：

- **ASC_API_KEY_ID**: App Store Connect API Key ID
- **ASC_API_KEY_ISSUER_ID**: Issuer ID
- **ASC_API_KEY_PATH**: `.p8` 文件的绝对路径

## 执行步骤

// turbo

1. 运行分发脚本：

   ```bash
   ./upload_testflight.sh
   ```

2. 监控终端输出，确认 "Archive", "Export", "Upload" 三个阶段均成功。

3. 如果上传失败，请检查 `ExportOptions.plist` 中的 Team ID 或 Provisioning Profile 配置。

## 后期工作

- 上传成功后，请登录 App Store Connect 设置测试员并提交审核。
