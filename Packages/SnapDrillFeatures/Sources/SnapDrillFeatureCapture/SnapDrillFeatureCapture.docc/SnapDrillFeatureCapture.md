# ``SnapDrillFeatureCapture``

题目采集功能模块，提供拍照识题、文档扫描和 OCR 结果确认流程。

## 概述

`SnapDrillFeatureCapture` 负责将现实中的题目转化为数字卡片。
支持多种采集方式：相机拍照、文档扫描、相册导入、PDF 导入和纯文本手动录入。
Vision OCR 自动提取题目文字，用户确认后保存至题库。
意外退出时自动保存草稿（由 `CaptureDraftService` 管理），支持连续裁剪一图多题。

依赖：`SnapDrillCore` · `SnapDrillData` · `SnapDrillUI`

## 核心类型

### 视图

- ``CaptureView`` — 采集入口，整合相机、相册、PDF、剪贴板文本、手动录入等多种采集方式
- ``CaptureResultView`` — OCR 结果确认与编辑，保存题目至题库

### 视图模型

- ``CaptureViewModel`` — 管理相机权限检查（`checkCameraPermission`）、OCR 触发、草稿检测（`checkDraftOnAppear`）和剪贴板导入
- ``CaptureResultViewModel`` — 管理识别结果编辑、图片裁剪和保存逻辑

### 导航

- ``CaptureRouter`` — 管理采集流程内部导航（取景 → 结果确认）

### 内部组件

相机取景由 `SmartCameraView` 驱动，支持手动对焦和裁剪框；
文档扫描通过 `DocumentScannerView` 封装 `VNDocumentCameraViewController`；
PDF 导入通过 `PDFPagePickerView` 选择页面后转为图片。
这些组件为模块内部实现，不对外暴露。
