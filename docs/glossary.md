# SnapDrill 项目全局术语表 (Glossary)

本文档定义了 SnapDrill 项目中使用的核心术语和命名规范，旨在保证代码库中变量、模型和组件的一致性，防止同义词滥用或重复命名。

---

## 📚 1. 核心领域模型 (Domain Models)

这些是应用中最基础的业务实体，对应底层数据库表（SwiftData）和内存映射。

| 术语 (Term) | 中文含义 | 描述与使用场景 (Description) | 关联代码实体 |
| --- | --- | --- | --- |
| **ReviewItem** | 复习条目 / 题目 | 整个应用最核心的数据单元，代表一道错题或一个知识点。 | `ReviewItemModel`（`@Model`，直接作领域对象） |
| **Content** | 内容 / 题干 | 题目的具体文字描述，通常来源于用户的输入或对图片的 OCR 识别结果。 | `ReviewItem.content` |
| **Answer / AnswerText** | 答案 | 题目的参考答案文本。 | `ReviewItem.answerText` |
| **Subject** | 学科 | 题目所属的具体学科（如：数学、语文、物理）。 | `SubjectModel` |
| **Source** | 来源 | 题目的最初出处（如：试卷、作业、错题本）。 | `SourceModel` |
| **Tag** | 标签 | 用户自定义的分类标签，通常支持多个标签关联到一个题目上。 | `TagModel` |
| **Grade** | 年级 / 阶段 | 题目所属的学习阶段或年级（如：高一、初三）。 | `ReviewItem.grade` |
| **Difficulty** | 难度 | 题目的难度等级（通常为 1-5 星）。 | `ReviewItem.difficulty` |
| **ImagePath** | 图片路径 | 题目原始截图在本地沙盒 `ImageStorage` 中的相对路径。**注意：模型只存相对路径，不直接存图片 Data**。 | `ReviewItem.imagePath` |

> 🚫 **防雷指南**:
>
> - **永远不要** 把 `content` 命名为 `question` 或 `text`。
> - **永远不要** 把 `subject` 命名为 `category`。

---

## 🧠 2. 核心算法与调度 (SM-2 Engine)

SnapDrill 依赖间隔重复（Spaced Repetition）算法来调度题目的复习频率。

| 术语 (Term) | 中文含义 | 描述与使用场景 (Description) | 关联代码实体 |
| --- | --- | --- | --- |
| **Ease Factor (EF)** | 难度因子 | 表示条目的固有难度，决定了复习间隔的增长速率。初始值为 `2.5`，不能低于 `1.3`。 | `ReviewItem.easeFactor` |
| **Interval** | 间隔 | 距离下一次复习的天数。 | `ReviewItem.interval` |
| **Repetitions** | 连续正确次数 | 连续回答正确的次数，一旦回答错误（忘记），通常重置为 0。 | `ReviewItem.repetitions` |
| **ReviewScheduler** | 调度引擎 | 负责运行 SM-2 算法的核心计算服务，计算得出下一次复习的 `nextReviewAt` 时间。 | `ReviewScheduler` |

---

## 📷 3. 图像捕获与识别 (Capture & OCR)

此模块涉及高频更新和性能敏感的相机数据流。

| 术语 (Term) | 中文含义 | 描述与使用场景 (Description) | 关联代码实体 |
| --- | --- | --- | --- |
| **Capture** | 捕获 / 拍摄 | 整体的相机拍照或图像识别功能流程。 | `CaptureView`, `CaptureViewModel` |
| **SmartCamera** | 智能相机 | 内部封装了 Vision OCR 实时边框检测的取景器。 | `SmartCameraViewController` |
| **Target Rect / Smoothed Rect** | 目标框 / 平滑框 | 实时文本检测返回的兴趣框（Target Rect），经过数学运算后平滑过渡的框（Smoothed Rect），以防止 UI 抖动。 | `CameraStateActor`, `CameraSessionManager` |
| **OCR (Optical Character Recognition)** | 光学字符识别 | 从图片中提取文字的技术服务实现。 | `OCRService` |
| **Draft** | 草稿 | 拍摄后尚未完全编辑并持久化保存的零时状态，若中途退出可恢复。 | `CaptureDraftService` |
| **Downsampling** | 降采样 | 从高分辨率相机输出中生成缩略图，防止过大图片导致的 OOM（内存溢出）。 | `CameraSessionManager` |

---

## 🃏 4. 探索与复习交互 (Review UI)

与用户直接交互的复习卡片和评级流。

| 术语 (Term) | 中文含义 | 描述与使用场景 (Description) | 关联代码实体 |
| --- | --- | --- | --- |
| **ReviewCard** | 复习卡片 | UI 层面展示题目内容的组件结构。 | `ReviewCardContent` |
| **SwipeCard** | 滑动卡片 | 允许用户通过手势（左滑/右滑）进行交互的容器层。 | `SwipeCard` |
| **Rating** | 评级 | 用户翻看答案后对自己掌握程度的评估（如：忘记、困难、良好、简单），作为 SM-2 算法的输入。 | `ReviewRatingView` |
| **Session** | 会话 | 一次完整的卡片刷题流。 | `ReviewViewModel`（状态机管理复习会话） |

---

## 🏛 5. 架构层次 (Architecture Layers)

SnapDrill 采用 MVVM 架构，`@Model` 直接作领域对象（无独立 Domain/Entity 层，2026-03-03 删除）。

| 术语 (Term) | 中文含义 | 描述与使用场景 (Description) |
| --- | --- | --- |
| **@Model** | 数据层 + 领域层实体 | 如 `ReviewItemModel`，SwiftData `@Model` 类直接作领域对象，无独立 Domain struct 映射。 |
| **Repository** | 存储库 | 具体类（无协议），如 `ReviewRepository`，向 ViewModel 暴露 CRUD 方法。测试通过 in-memory `ModelContainer` 实现。 |
| **ViewModel** | 视图模型 | `@Observable @MainActor final class`，直接调用 Repository（无 UseCase 层）。 |
| **Router** | 路由 | 管理基于 SwiftUI `NavigationStack` 的视图跳转和注入。 |
| **Service / Engine** | 服务 / 引擎 | 封装业务逻辑、算法或第三方 API（如 `OCRService`, `ReviewScheduler`）。 |

---

> 修改或扩展此表时，请确保所添加术语与现有架构规范无冲突。撰写 `Model` 或功能类变量时，务必将此表作为唯一的 **The Single Source of Truth**。
