# ``SnapDrillFeatureCapture``

题目采集功能模块，提供拍照识题、文档扫描和 OCR 结果确认流程。

## 概述

`SnapDrillFeatureCapture` 负责将现实中的题目转化为数字卡片：
用户通过相机拍摄或文档扫描获取图片，Vision OCR 自动提取题目文字，
用户确认后保存至题库。意外退出时自动保存草稿（由 `CaptureDraftService` 管理）。

依赖：`SnapDrillCore` · `SnapDrillData` · `SnapDrillUI`

## 核心类型

### 视图

- ``CaptureView`` — 采集入口，含相机取景和扫描触发
- ``CaptureResultView`` — OCR 结果确认与编辑，保存题目至题库

### 视图模型

- ``CaptureViewModel`` — 管理相机状态和 OCR 触发
- ``CaptureResultViewModel`` — 管理识别结果编辑、图片裁剪和保存逻辑

### 导航

- ``CaptureRouter`` — 管理采集流程内部导航（取景 → 结果确认）

### 相机组件

- ``SmartCameraView`` — 实时取景器，支持手动对焦和裁剪框
- ``DocumentScannerView`` — 系统文档扫描器（`VNDocumentCameraViewController`）封装
