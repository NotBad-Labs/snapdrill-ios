本目录用于存放文档中引用的各类静态资源，如架构图、流程图、数据模型图等。

**命名规范**:
- 格式: `<文档简称>-<描述>.<扩展名>`
- 示例:
  - `tdd-clean-architecture-layers.png`
  - `prd-user-journey-map.svg`
  - `adr002-cloudkit-sync-flow.drawio`

**引用方式**:
在 Markdown 文档中，使用相对路径引用图片：
```markdown
![Clean Architecture分层图](../assets/tdd-clean-architecture-layers.png)
```

**建议**:
- 优先使用矢量图格式（如 `.svg`, `.drawio`）以便缩放和修改。
- 提交图片前进行压缩，减小仓库体积。
