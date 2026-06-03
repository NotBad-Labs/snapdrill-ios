# SnapDrill 官网子目录建设 Spec（v2）

> **协作模式**：Claude 写 spec → Codex / Antigravity 执行 → Claude 验收
> **决策依据**：snapdrill-ios `docs/decisions/ADR-003-dual-region-release.md`
> **日期**：2026-05-28（v2 — 含 Cloudflare / Firebase / Workspace 控制台 + curl 实证核查）
> **v2 变更**：①§1 新增"已验证基建事实"（执行勿重复勘察）②URL 结构定为方案 B ③§10 新增 Firebase 阻塞依赖

---

## 0. 任务一句话

在 **notbadhq.com/snapdrill** 子目录**扩建**（产品页已存在）：产品落地页（双语化）+ 隐私政策 + 服务条款 + 支持，共 4 页，**中英双语**，满足 App Store Connect 必填的 Privacy Policy URL + Support URL。

---

## 1. ✅ 已验证的基建事实（2026-05-28 实证，执行 agent 直接采用，勿重复勘察）

### 托管 & DNS & 邮箱
| 项 | 已核实事实 |
|---|---|
| 托管平台 | **Firebase Hosting**，项目 `notbad-website`（`.firebaserc` default）|
| 部署目录 | `dist`（Astro 产物）；`firebase.json`: cleanUrls=true, trailingSlash=false, 无 rewrites/redirects |
| 部署流程 | `npm run build` → `firebase deploy`；最近部署 2026-03-26（admin@notbadhq.com）|
| DNS | **Cloudflare**（Free 方案，notbadhq.com 为账户唯一域名，DNS Setup=Full）|
| A 记录 | `notbadhq.com A 199.36.158.100`（Firebase Hosting IP，**灰云 DNS-only**）|
| SSL/TLS | Cloudflare 模式 = **Full**；notbadhq.com 自定义域名在 Firebase **已连接**（SSL 就绪）|
| 邮箱 | Google Workspace；别名 `support@` `hello@` `legal@` `billing@` 均汇入 admin@notbadhq.com |

### 站点技术栈
| 项 | 已核实事实 |
|---|---|
| 框架 | Astro `output: 'static'` + **AstroWind** 模板（tailwind + `src/components/widgets/`）|
| **i18n** | **⚠️ 框架级未配置**（`config.yaml` 仅 `language: en`，无 `@astrojs/i18n`）→ **双语是净新增工作** |
| 现有路由 | `/`、`/snapdrill`(英文,102行)、`/privacy`(.md)、`/terms`(.md)、`/404` |
| 设计 token | AstroWind 默认；theme `light:only`；OG 图 `notbad_hero.png` |

### 线上实测（curl，2026-05-28）
| URL | 状态 | 备注 |
|---|---|---|
| `notbadhq.com`（裸域）| **200 ✅** | Fastly/Firebase CDN 直连 |
| `/snapdrill` `/privacy` `/terms` | **200 ✅** | 已存在 |
| `/support` | **404** | 待建 |
| `www.notbadhq.com` | **404 ⚠️** | Firebase 未登记 www（见下）|

### 发现的基建问题（执行时一并修，均非阻塞）
1. **`www.notbadhq.com` → 404**：Cloudflare 加 `www → 裸域` 301 重定向规则（或 Firebase 登记 www 自定义域名）
2. `notbadhq.com/works.html → 404`：旧外链指向的页面新站没有（低优先，可加 301→首页）
3. 旧 Firebase 项目 `notbad-snapdrill` 仍 serve 一条死重定向（301→works.html→404），对应本地 `notbad-snapdrill-redirect` 目录，可清理（零紧急）

---

## 2. 背景与硬约束

- SnapDrill = **一个产品两区域发行版**（国内"小本本-智能错题本" + 海外"SnapDrill"），非两个独立产品
- **子目录非子域名**（ADR-003；`snapdrill.notbadhq.com` 已实测不存在，**勿建**）
- **双语**：中文（PIPL）+ 英文（CCPA/GDPR）
- **不要**：ccTLD / 独立子域名 / 两套独立站

---

## 3. 目标产物（URL 结构 = 方案 B，PO 2026-05-28 决策）

```
notbadhq.com/snapdrill           产品落地页（现有英文页扩建为双语）
notbadhq.com/snapdrill/privacy   隐私政策（新建，产品级）
notbadhq.com/snapdrill/terms     服务条款（新建，产品级）
notbadhq.com/snapdrill/support   支持（新建）
```

- 根级 `/privacy` `/terms`：留作公司级，或 301 → `/snapdrill/...`（执行 agent 与帅哥确认；现有内容过期，见 §5.2）
- 双语路由：因框架级无 i18n，执行 agent 按 AstroWind 现状二选一 —— 路径前缀 `/zh/snapdrill/...`（默认英文）或 单页 + 语言切换组件

---

## 4. 内容来源（精确路径，直接提取勿重写）

**权威源 = snapdrill-ios app 的 `Localizable.strings`**（最后更新 2026年3月，比网站现有 privacy.md 新且准）：

| 内容 | 文件 | 规模 |
|---|---|---|
| 中文文案 | `SnapDrill/Resources/zh-Hans.lproj/Localizable.strings` | `privacy.*` 27 keys / `terms.*` 34 keys |
| 英文文案 | `SnapDrill/Resources/en.lproj/Localizable.strings` | 同上 |
| section 结构 | `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Policy.swift` | — |
| 产品介绍/ASO | `docs/product/appstore-metadata.md` | — |

提取命令示例：
```bash
grep '^"privacy\.' SnapDrill/Resources/zh-Hans.lproj/Localizable.strings
grep '^"terms\.'   SnapDrill/Resources/en.lproj/Localizable.strings
```

⚠️ **不要用网站现有 `src/pages/privacy.md` 作源** —— 它过期（提 ATT，与 ADR-002 已移除 ATT 矛盾；Firebase 未做区域差异）。

---

## 5. 各页面规格

### 5.1 落地页 `/snapdrill/`（扩建现有页）
- 现状：`src/pages/snapdrill.astro` 英文单页（102 行）+ `snapdrill_concept.png`；**扩建为双语**
- **Hero**：App 名（中文区"小本本-智能错题本" / 英文区"SnapDrill"）+ slogan（appstore-metadata 提取）
- **核心功能 5 点**：拍照/扫描/PDF 采集 → OCR 识别 → 多维分类 → SM-2 间隔复习 → PDF 导出（隐私本地）
- **截图区**：占位（待 app 截图就绪）
- **App Store badge**：占位（上架后填真实 URL）
- **隐私承诺区块**：零注册 / 数据本地 / 不收集身份信息
- **footer**：链接 privacy / terms / support

### 5.2 隐私政策 `/snapdrill/privacy/`（新建）🔴 内容有阻塞依赖
- 提取 app `privacy.*` 全文（27 keys）
- 中文符合 PIPL + 英文符合 CCPA/GDPR
- **区域差异附录（ADR-003）**：国内版数据流 vs 海外版数据流分别声明
- 🔴 **Firebase 阻塞依赖（见 §10.1）**：app 实测捆绑 Firebase Analytics + Crashlytics（opt-in），但 ADR-003 说国内版应无 Firebase。**"第三方服务"节内容取决于此决策，PO 未定前不能 finalize 隐私页**。
  - app 文案现状（可参考）：Firebase 为"明确开启后启用"的 opt-in，可在「设置→隐私」关闭，不提 ATT

### 5.3 服务条款 `/snapdrill/terms/`（新建）
- 提取 app `terms.*`（34 keys，约 17 节）
- 版权：2026 NotBad Labs L.L.C.

### 5.4 支持页 `/snapdrill/support/`（新建）
- **联系 Email：`support@notbadhq.com`**（已验证 Workspace 别名存在，可收信）；法务/隐私可用 `legal@notbadhq.com`
- **FAQ 5-8 条**（product docs 提炼）：如何拍照录入 / 如何复习 / 数据存哪 / 如何备份 / 如何导出 PDF / 是否需注册 / 是否收费

---

## 6. 技术约束

- 子目录（非子域名）/ 双语（净新增 i18n）
- **响应式（移动优先，375px 不破版**，家长多用手机）
- HTTPS（Firebase 默认）
- **中国大陆可达性**：部署后中国网络实测（见 §10.2，关键 — Apple 中国审核员必须能访问）
- 视觉复用 AstroWind 现有 token，与首页一致
- SEO：每页 `<title>` / `<meta description>` / OG meta
- 部署：`firebase deploy`（项目 `notbad-website`）；**不破坏**现有 Home/404 页
- **不引入重型框架**（保持 Astro 静态 + AstroWind，无 React/Vue）

---

## 7. 验收标准（Claude 最终 check）

- [ ] 4 个 URL 可访问（`/snapdrill` + `/snapdrill/privacy` + `/snapdrill/terms` + `/snapdrill/support`）
- [ ] 双语正常（路由或切换组件）
- [ ] 隐私/条款逐 section 对照 app `Localizable.strings`，一致（不得自创/删减）
- [ ] 隐私政策含 PIPL（中文）+ CCPA/GDPR（英文）要素
- [ ] 隐私政策"第三方服务"节与 §10.1 Firebase 决策一致（决策落定后验收）
- [ ] 服务条款约 17 section 完整
- [ ] 支持页有有效 Email（support@notbadhq.com）+ FAQ 5-8 条
- [ ] `www.notbadhq.com` 404 已修（301→裸域）
- [ ] 移动端 375px 截图证明
- [ ] **中国大陆可达性实测**（中国网络打开截图）
- [ ] notbadhq.com 现有页面（Home/404/根级 privacy/terms）未被破坏
- [ ] 每页 SEO meta 完整
- [ ] 生产部署成功（真实 URL 可访问）

---

## 8. 交付物（执行 agent 完成后提交）

1. 4 个生产 URL
2. 改动文件清单（`git diff --stat`）
3. 中国大陆可达性测试截图
4. 移动端（375px）+ 桌面截图各 1 张
5. 部署确认（firebase deploy 日志）

---

## 9. 边界（不要做）

- ❌ 不做子域名 `snapdrill.notbadhq.com`
- ❌ 不做独立站 / 不脱离 notbadhq.com
- ❌ 不自创隐私/条款文案（必须提取 app `Localizable.strings`）
- ❌ 不用网站现有 `privacy.md` 作内容源（已过期）
- ❌ 不动 App Store badge 真实链接（上架后才有，现在占位）
- ❌ 不引入重型框架（保持 Astro + AstroWind）
- ❌ 不做后端/表单（支持页 Email 用 mailto:，除非现有 Contact 已有可复用表单组件）
- ❌ 不动 notbad-website 那 7 个未提交的本地 WIP 改动（与本任务无关，交还帅哥处理）

---

## 10. 🔴 阻塞依赖 & 盲点（v2 新增）

### 10.1 Firebase / ADR-003 决策（PO 决策，阻塞隐私页内容）
- **现状**：当前要上国内 TestFlight 的 build（`com.snapdrill.app`）**实测捆绑 Firebase**（`SnapDrill/App/GoogleService-Info.plist` 存在 + `SnapDrillInfrastructure/Package.swift` 声明 FirebaseAnalytics/Crashlytics/Core），为 opt-in（默认关）。app 隐私文案已诚实披露，不提 ATT。
- **矛盾**：ADR-003 写"国内版无 Firebase"。
- **影响**：①隐私政策"第三方服务"节内容 ②PIPL 跨境数据（发 Google 美国服务器）合规 ③app 是否需为国内 build strip Firebase（C 路径 xcconfig 工程）。
- **需 PO 定**：国内版保留 opt-in Firebase（修订 ADR-003 措辞 + 补 PIPL 跨境同意）vs strip Firebase（按 ADR-003，工程改造）。**这是 app 侧 + 官网侧共同前置依赖**。

### 10.2 中国大陆可达性（ADR-003 盲点 #1）
- notbadhq.com 裸域走 Firebase IP `199.36.158.100`（灰云直连 Google），www 走 Cloudflare 边缘；均无 ICP 备案（美国域名不能备案）。
- 两条路在中国的可达性需**真机中国网络实测**，截图不能定。Apple 中国审核员打不开 = 拒审风险。
