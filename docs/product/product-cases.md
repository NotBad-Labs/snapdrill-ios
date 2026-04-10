# SnapDrill 产品用例与边界规格

> 本文件定义「怎么验收」——可执行行为规格，供 Issue 验收标准引用、QA 回归基线。
> 不重复设计理由（引用 design），不重复功能清单（引用 requirements），不重复用户叙事（引用 journeys）。
> Issue 的 Given-When-Then 引用本文档的 Use Case 编号和 Boundary ID（如 B01）。
> 冲突优先级：design > cases > requirements。

---

## Use Case 1: Create Problem

**Goal**: 通过任一录入入口创建一道题目，完成裁剪、OCR、元数据填写并保存入库。


**Preconditions**:
- 当前 Profile 已选定
- 用户位于采集入口或可一步进入采集入口
- Camera / Photos / PDF / Clipboard：用户已选择或可选择有效输入源（含 Document Scan）

**Success path**:
1. 用户从 Camera、Photos、PDF import、Clipboard 或 Manual edit 进入录题流程（含 Document Scan）
2. 系统展示可编辑的题目载体：图片来源进入裁剪；Manual edit 进入文本/图片编辑
3. 系统对图片内容执行 OCR；识别结果展示给用户，可编辑、可复制到剪贴板，但不阻塞保存
4. 系统保留题目图片作为主内容真相；OCR 文本作为展示、搜索索引、可复制文本
5. 编辑页只展示用户已开启的系统字段；学科默认开启；其余字段按设置决定是否出现
6. 系统对已开启字段沿用上次选值作为默认值；用户仅修改本题有变化的字段
7. 用户可填写或补充元数据：学科、难度、来源、年级、答案、自定义标签
8. 用户点击保存；系统原子性写入题目、图片引用、OCR 文本、元数据
9. 保存成功后给出成功反馈（触觉 + 缩略图动画），并默认回到采集界面，支持连续录入

**Variants & Exceptions**:
- [Variant] Camera：支持实时文字区域检测、稳定性指示器、自动框选
- [Variant] Photos：支持同一张图连续裁剪多题，保存后同图再次出现，不必重复选图
- [Variant] Document Scan
- [Variant] PDF import：支持逐页预览、页面选择、裁剪后录入
- [Variant] Manual edit：允许无图片保存纯文本题目，也允许补充图片
- [Exception] Camera 权限拒绝或受限：不可进入拍照；必须给出权限说明与跳转系统设置入口
- [Exception] Photo Library 权限拒绝或受限：不可选图；必须给出权限说明，不得静默失败
- [Exception] OCR 首次失败：提供手动重试选项；同时显示稳定性提示引导调整拍摄姿势，但保留继续编辑和保存能力
- [Exception] OCR 返回空文本：图片题仍可保存；OCR 文本字段允许为空
- [Exception] 保存失败（磁盘满/写入错误）：不得显示成功状态；当前编辑内容必须保留为 draft 或停留在当前页可重试
- [Exception] 导入文件损坏/不可读格式：提示文件不可用，允许重新选择

**Data guarantees**:
- 未点击保存前，不产生正式题目记录
- 保存成功后，题目记录必须同时包含当前 Profile 归属、主内容载体、元数据和可检索 OCR 文本
- 图片题保存时必须保留裁剪后的图片副本；OCR 不是唯一数据来源
- 任何写入失败不得产生"列表已出现但内容不完整"的半写入记录
- Draft 仅保留最近一份（当前为全局单例，per-Profile 隔离待实现）；成功保存后自动清除对应 draft；7 天过期自动清理

**References**:
- `product-vision.md`：`1. 录入体验是生命线`、`4. 数据属于用户（隐私是核心差异化）`
- `product-design.md`：`信息架构 [P1, P2]`、`OCR 定位 [P1, P6]`、`图片存储策略 [P1, P4]`、`字段可配置系统 [P1, P2]`、`连续录入设计 [P1]`、`草稿恢复设计 [P4]`
- `product-requirements.md`：`录入方式优先级`、`OCR 识别能力演进路线`、`草稿恢复`、`功能全景`
- `product-journeys.md`：`旅程 0：首次打开 App`、`旅程 2：做完试卷，拍照录入错题`、`旅程 3：从微信群导入老师发的题目`、`旅程 1：家长帮小学生录入 + 多孩管理`、`旅程 9：OCR 失败手动修正`

---

## Use Case 2: Manage Library Item

**Goal**: 在题库中定位已有题目，并完成搜索、过滤、排序、编辑、补答案、批量打标签。


**Preconditions**:
- 当前 Profile 题库中已有 1 道以上题目（空库见 Boundary B17）

**Success path**:
1. 用户进入题库，系统默认按录入时间倒序展示当前 Profile 下的题目列表
2. 用户可通过搜索栏按 OCR 文字内容搜索题目
3. 用户可按学科、标签、难度进行多选过滤，过滤条件可组合生效
4. 用户可按录入时间、学科、难度、复习状态切换排序方式
5. 用户进入题目详情，查看原题图片、OCR 文字、元数据、答案
6. 用户进入编辑，修改系统字段、自定义标签、答案文字、答案图片
7. 用户保存后，列表和详情反映更新结果
8. 用户进入选择模式，勾选多道题
9. 用户执行批量打标签；系统将目标标签追加到所选题目，不移除未触及的既有标签

**Variants & Exceptions**:
- [Variant] 搜索与过滤可叠加；结果集基于当前 Profile
- [Variant] 自定义标签允许自由创建（输入 + 空格生成）；历史标签建议可复用
- [Variant] 编辑时可补答案而不修改题目主内容（典型场景：批改后补录正确答案）
- [Variant] 编辑时可仅修改难度（典型场景：考试后发现某题比预期难/简单）
- [Variant] 系统字段选项（学科/来源/年级）支持用户增删改：新增自定义选项、删除未使用选项、重命名时级联更新引用
- [Variant] 已被题目使用的系统字段选项不可删除（数据完整性保护）
- [Exception] 空题库：显示空状态，并提供去采集入口（见 Boundary B16）
- [Exception] 搜索无结果：显示无结果状态，保留当前搜索词和过滤条件
- [Exception] 过滤后无结果：显示无结果状态，不得清空用户已选过滤条件
- [Exception] 编辑保存失败：保持旧数据不变，提示失败可重试
- [Exception] 批量打标签部分失败：必须反馈成功/失败数量，已成功项保留；失败项不得写入半状态

**Data guarantees**:
- 搜索、过滤、排序只影响当前展示，不改动底层题目数据
- 编辑保存必须原子更新；失败时保持旧数据不变
- 批量打标签对每个题目独立落库；不得因单条失败回滚全部已成功项
- 题目始终归属于当前 Profile，不得因搜索、过滤、编辑跨 Profile 泄露数据

**References**:
- `product-design.md`：`字段可配置系统 [P1, P2]`、`批量操作设计 [P2]`
- `product-requirements.md`：`题库排序与过滤`、`功能边界（MoSCoW 分类）`、`功能全景`
- `product-journeys.md`：`旅程 4：整理和管理已有题目`

---

## Use Case 3: Delete + Undo

**Goal**: 安全删除单题或多题，并在 5 秒 Toast undo window 内支持撤销。


**Preconditions**:
- 当前 Profile 题库中存在待删除题目

**Success path**:
1. 用户在列表中删除单题，或在选择模式中删除多题
2. 系统先执行 soft delete，不立即永久删除
3. 系统展示底部 Toast，明确已删除数量，并提供 5 秒撤销入口
4. 若用户在窗口内点击撤销，系统恢复最近一次删除的全部题目
5. 若用户未撤销且 5 秒到期，系统执行永久删除
6. 永久删除完成后，列表、统计、复习入口同步移除对应题目

**Variants & Exceptions**:
- [Variant] 单题删除与批量删除共用同一套 soft delete + Toast 撤销机制
- [Variant] 仅支持最近一次删除撤销；新删除会覆盖旧删除的撤销上下文
- [Exception] 删除请求发起失败：不得从列表移除题目，不得弹成功 Toast
- [Exception] 撤销请求失败：必须提示恢复失败，原题目保留 soft delete 状态，待系统重试或用户刷新后确认最终状态
- [Exception] App 在 undo window 内进入后台或被杀死：不得在用户无感知的情况下立即丢失题目；下次恢复时必须以可确定状态收敛为"已恢复"或"已完成永久删除"，不得出现幽灵记录或重复记录

**Data guarantees**:
- Soft delete 窗口内题目不得被其他功能当作正式可编辑记录继续修改
- 撤销成功后，题目 ID、元数据、图片、复习进度必须完整恢复
- 永久删除完成后，题目主记录、图片引用、搜索索引、复习记录必须一致移除
- 删除与撤销必须限定在当前 Profile，不得影响其他 Profile 数据

**References**:
- `product-design.md`：`删除撤销设计 [P4]`、`批量操作设计 [P2]`、`多 Profile 设计 [P5]`
- `product-requirements.md`：`功能边界（MoSCoW 分类）`、`功能全景`
- `product-journeys.md`：`旅程 4：整理和管理已有题目`、`插曲：误删和撤销`

---

## Use Case 4: Review Due Cards

**Goal**: 从 Dashboard 进入待复习列表，完成翻卡、自我评估，并更新 SM-2 复习状态。


**Preconditions**:
- 当前 Profile 存在到期复习题目（无到期题见 Boundary B18）

**Success path**:
1. Dashboard 展示当前 Profile 的待复习数量和入口
2. 用户点击待复习入口进入 Review
3. 系统按待复习队列展示卡片正面，包含原题图片与 OCR 文字
4. 用户点击卡片翻面，查看答案文字与答案图片
5. 用户通过右滑/"记得"按钮或左滑/"不记得"按钮完成评估
6. 系统依据评估结果更新该题的 SM-2 相关复习状态（easeFactor、interval、nextReviewAt），并推进到下一题
7. 全部到期题处理完成后，系统展示简洁结果摘要（"N 题掌握，M 题待加强"）并返回上一级

**Variants & Exceptions**:
- [Variant] 手势与按钮是等价输入
- [Variant] 图片题复习时必须显示图片，OCR 仅为辅助
- [Exception] 当前无到期题：Dashboard 与 Review 入口显示空状态，不进入空白卡片流（见 Boundary B19）
- [Exception] 某题缺少答案：允许翻面进入空答案状态，但仍可完成"记得/不记得"评估
- [Exception] 单题复习状态更新失败：必须阻止该题被标记为已完成本轮复习，并提示重试，避免假完成

**Data guarantees**:
- 复习只更新当前 Profile 下被评估题目的复习状态，不改动题目主内容
- 每次评估只落库一次，不得因重复手势或重复点击产生双重更新
- 复习结果摘要必须与本轮成功提交的评估结果一致

**References**:
- `product-design.md`：`图片存储策略 [P1, P4]`、`复习设计 [P3, P5]`
- `product-requirements.md`：`功能边界（MoSCoW 分类）`、`功能全景`
- `product-journeys.md`：`旅程 5：复习到期题目`

---

## Use Case 5: Export + Print

**Goal**: 将题库中的题目导出为 PDF、直接打印，或导出 JSON/CSV 数据。


**Preconditions**:
- 当前 Profile 下存在可导出题目

**Success path**:
1. 用户在题库中通过搜索/过滤形成目标结果集，或选中单题/多题用于打印
2. 用户发起 PDF 导出；系统生成导出前预览
3. 用户可在 PDF 导出中选择去答案打印、留白答题区、页眉页码等选项
4. 用户确认后，系统生成 PDF 文件并提供预览、分享、保存
5. 用户发起快速打印；系统允许选择每页题数（1/2/4 题）并调用系统打印
6. 用户通过隐私设置页发起 JSON 导出，或通过隐私设置页/题库导出面板发起 CSV 导出；系统生成当前 Profile 的结构化数据导出文件

**Variants & Exceptions**:
- [Variant] JSON 从隐私设置页触发；CSV 可从隐私设置页或题库导出面板触发（CSV 双入口）
- [Variant] 图片处理增强（去手写/去批改痕迹/试卷还原）为 Pro 功能（免费限次体验）；免费用户超出限次时提示升级，不阻塞基础导出
- [Variant] "去答案打印"（隐藏答案字段）是免费基础功能，与 Pro 的图片处理增强是不同层面
- [Variant] 结构化数据导出以实际导出字段清单为准；如有未覆盖字段，需在帮助文档说明
- [Exception] 导出结果集为空：不得生成空文件；必须提示无可导出题目
- [Exception] 文件写入失败或磁盘空间不足：不得提示导出成功；已生成的临时文件必须清理
- [Exception] 打印不可用（无 AirPrint 打印机）：必须停留在打印前状态并给出失败反馈，不得误记为已打印

**Data guarantees**:
- PDF 内容必须来自当前过滤结果或当前选择结果，不得夹带其他 Profile 题目
- 去答案模式只影响导出内容，不改动原题答案数据
- JSON/CSV 导出必须以实际导出字段清单为准；如有未覆盖字段，需在帮助文档说明，不得静默宣称为全字段导出
- 导出与打印是只读操作，不得修改题目主数据、复习状态或统计

**References**:
- `product-vision.md`：`4. 数据属于用户（隐私是核心差异化）`
- `product-design.md`：`导出与打印设计 [P4 数据属于用户]`
- `product-requirements.md`：`导出与打印能力`、`设置与个性化`、`功能全景`
- `product-journeys.md`：`旅程 4：整理和管理已有题目`
- `product-business.md`：`付费模式（Freemium + 订阅，Bear 模式，2026-03-07 确立）`

---

## Use Case 6: Backup + Restore

**Goal**: 创建 `.snapdrill` 手动备份文件，并从备份文件恢复当前设备数据。


**Preconditions**:
- 备份：当前设备存在至少一个 Profile 含数据
- 恢复：用户持有 `.snapdrill` 文件

**Success path**:
1. 用户在设置中发起手动备份
2. 系统打包当前设备本地数据为 `.snapdrill` 文件，包含全部 Profile、题目、图片引用、元数据、复习进度
3. 系统生成备份文件并交由用户保存/分享
4. 用户选择 `.snapdrill` 文件发起恢复
5. 系统先校验文件可读性、结构完整性、版本兼容性
6. 校验通过后，系统导入备份中的全部 Profile 数据
7. 恢复完成后，题库、Dashboard、Review、设置中的本地数据与备份内容一致

**Variants & Exceptions**:
- [Variant] 备份文件必须覆盖多 Profile 场景，不允许只导出当前活跃 Profile 的局部数据
- [Exception] 备份文件损坏或不可读：必须拒绝恢复，并保留现有本地数据不变
- [Exception] 备份版本高于当前 App 支持版本：必须拒绝恢复并提示版本不兼容，建议升级 App
- [Exception] 备份版本低于当前 App 但在兼容范围内：允许迁移恢复；失败时不得破坏现有本地数据
- [Exception] 恢复写入中途失败：目标：完整成功或完整失败。当前实现：数据库恢复成功后图片恢复为 best-effort，可能出现数据库有记录但图片缺失的状态，恢复完成后应显示结果摘要
- [Exception] 磁盘空间不足：恢复前检查可用空间，空间不足时拒绝开始恢复并提示

**Data guarantees**:
- 备份是用户数据所有权的出口；生成失败不得产生"文件已导出"假象
- 恢复目标是可验证的完整替换或完整导入过程；当前实现如出现图片 best-effort 恢复失败，必须在结果摘要中明确提示，不得静默跳过
- 备份与恢复必须保留 Profile 隔离关系
- 任何恢复失败均不得损坏恢复前的现有本地数据

**References**:
- `product-vision.md`：`4. 数据属于用户（隐私是核心差异化）`
- `product-design.md`：`备份与恢复设计 [P4 数据安全]`、`多 Profile 设计 [P5 家长友好]`
- `product-requirements.md`：`功能边界（MoSCoW 分类）`、`功能全景`
- `product-journeys.md`：`旅程 1：家长帮小学生录入 + 多孩管理`、`旅程 10：免费用户换机恢复`
- `product-business.md`：`付费模式（Freemium + 订阅，Bear 模式，2026-03-07 确立）`、`隐私策略（2026-03-07 确立，Bear 模式）`

---

## Use Case 7: Switch Profile

**Goal**: 在同一设备上切换不同孩子/用户的 Profile，并保持数据完全隔离。


**Preconditions**:
- 设备上已存在 2 个及以上 Profile（首个 Profile 在 Onboarding 时自动创建）

**Success path**:
1. 用户在 Dashboard 头像区域或设置页进入 Profile 管理
2. 系统展示本地 Profile 列表
3. 用户选择目标 Profile
4. 系统切换当前上下文，并刷新 Dashboard、Library、Capture 默认值、Review、统计
5. 用户在新 Profile 下执行录题、搜索、复习、导出时，只看到该 Profile 的数据

**Variants & Exceptions**:
- [Variant] Profile 切换不要求密码，不引入账号体系
- [Variant] 支持创建新 Profile（填写昵称、选择头像）和删除 Profile（需确认，不可恢复）
- [Variant] 备份/恢复包含全部 Profile；切换后的数据集必须与恢复结果一致
- [Exception] 当前存在未保存编辑或 draft：切换前必须先保存为 draft、提示用户恢复/放弃，或阻止直接切换，避免静默丢失
- [Exception] 切换时存在进行中的 OCR/导出/打印任务：等待完成或提示中断，不得静默丢弃进行中的任务结果
- [Exception] 切换失败：必须保持原 Profile 不变，不得进入部分页面已切换、部分页面未切换的混合状态

**Data guarantees**:
- Profile 是数据隔离边界；题库、统计、复习进度、导出结果、draft 都必须按 Profile 隔离
- Profile 切换不得跨 Profile 复用搜索结果、过滤条件对应的数据集
- 一个 Profile 的删除、导出、恢复、复习更新不得污染其他 Profile

**References**:
- `product-vision.md`：`目标用户`、`成功信号（设计校准器）`
- `product-design.md`：`多 Profile 设计 [P5]`
- `product-requirements.md`：`功能全景`
- `product-journeys.md`：`旅程 0：首次打开 App`、`旅程 1：家长帮小学生录入 + 多孩管理`
- `product-business.md`：`付费模式（Freemium + 订阅，Bear 模式，2026-03-07 确立）`

---

## Appendix: Boundary Cases

> 仅收录 S0/S1 全部 + 高频 S2。Severity 定义见 `../workflow.md`§工作优先级。

| ID | Scenario | Expected UX | Data guarantee | Severity |
|---|---|---|---|---|
| B01 | 设备存储满时保存题目 | 提示保存失败，保留编辑内容为 draft 或停留编辑页可重试 | 不产生半写入记录，不丢失当前输入 | S0 |
| B02 | 保存写入失败（SwiftData/磁盘错误） | 不展示成功反馈，保留当前编辑状态 | rollbackContext() 回滚，旧数据不变 | S0 |
| B03 | App 录题中意外退出（来电/崩溃） | 下次进入提示恢复最近一份 draft | draft 保留最近一份，7 天过期清理 | S0 |
| B04 | 备份文件损坏/不可读 | 拒绝恢复，提示文件损坏 | 现有本地数据完全不变 | S0 |
| B05 | 恢复中途写入失败 | 提示恢复失败，尽力回滚 | 目标：不留半恢复状态。当前：图片恢复为 best-effort | S0 |
| B06 | Profile 切换时存在未保存编辑 | 提示保存/放弃，不静默切换 | 未保存内容不无提示丢失 | S0 |
| B07 | 导出 PDF/JSON/CSV 时磁盘写满 | 提示导出失败，清理临时文件 | 不生成损坏文件，原数据不受影响 | S1 |
| B08 | 导入图片/PDF 损坏或不可读 | 提示文件不可用，允许重新选择 | 现有数据不变 | S1 |
| B09 | 备份版本高于当前 App | 拒绝恢复，提示升级 App | 现有数据不变 | S1 |
| B10 | Undo window 内 App 进入后台 | 返回前台后状态可理解地收敛 | 不出现幽灵记录，不发生不可逆数据丢失 | S0 |
| B11 | Undo window 内 App 被杀死 | 下次启动收敛到确定状态 | 不因进程终止导致不可解释的数据丢失 | S0 |
| B12 | 批量打标签/删除部分失败 | 反馈成功/失败数量 | 已成功项保留，失败项不写半状态 | S1 |
| B13 | 连续保存重复点击 | 忽略重复点击或 disable 保存按钮 | 不产生重复题目记录 | S1 |
| B14 | Camera 权限拒绝/受限 | 提示权限说明 + 跳转系统设置入口 | 不创建空题目 | S2 |
| B15 | Camera 权限后续被系统撤销 | 再次进入 Camera 时立即提示，不出现黑屏假死 | 不写入半成品记录 | S2 |
| B16 | Photo Library 权限拒绝/受限 | 提示权限缺失，不静默返回 | 不生成空白导入任务 | S2 |
| B17 | 空题库 | 显示空状态 + 采集入口引导 | 不显示脏数据 | S2 |
| B18 | 搜索/过滤无结果 | 保留用户已选条件，显示无结果状态 | 不修改列表数据 | S2 |
| B19 | 无到期复习题 | Dashboard 显示 0 待复习，Review 不进入空卡片流 | 不创建伪复习记录 | S2 |
| B20 | OCR 返回空文本 | 允许继续编辑保存图片题 | 图片和手填字段正常保存 | S2 |
| B21 | 通知权限拒绝后再次开启提醒开关 | 提示权限已被系统拒绝，引导跳转系统设置 | 不发送本地通知 | S2 |
| B22 | 未裁剪直接保存整页试卷（大尺寸图片） | 给予裁剪引导提示，或保留更高清晰度 | 图片清晰度满足再次放大查看需求 | S2 |
| B23 | 媒体缓存清理误删题目原图 | 缓存清理只清理 Caches/ 临时文件，不触碰 Documents/ 或 Application Support/ | 任何缓存清理不得导致题目原图、备份文件、SwiftData 数据丢失 | S0 |
| B24 | 用户尝试删除最后一个 Profile | 删除按钮 disabled，提示「至少保留一个 Profile」 | 设备上始终存在至少一个 Profile，不出现零 Profile 崩溃 | S1 |
| B25 | 切换 Profile 后 TipKit 提示状态 | 按 Profile 隔离（#532 已修复） | 切换 Profile 后 TipKit 提示状态独立 | S2 |
| B26 | 删除非最后 Profile | 二次确认；删除后级联移除该 Profile 的题库、图片、复习进度与配置；若删除的是当前活跃 Profile，UI 自动 fallback 到剩余 Profile 并提示 | 不得遗留孤儿数据、错误引用或活跃 Profile 悬空状态 | S1 |
