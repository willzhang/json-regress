# 协作文件接入检查

## 本次适配

- [x] 读取用户提供的归档，检查路径并核对全部 MANIFEST 哈希。
- [x] 保留现有代码、测试、生成接口、MoonBit 约定及 CI 文件。
- [x] 重写项目 AGENTS 和 json-regress-engineering skill；配置 skill 展示元数据。
- [x] 填写当前状态、架构、接口、验证、路线图及三份具体任务契约。
- [x] 适配贡献指南、资料边界、PR 与数值/集成/场景/缺陷模板。
- [x] 合并忽略规则，区分固定夹具、第三方缓存与生成结果。
- [x] 在父工作区放入 AGENTS 入口；完整协作文件随项目目录携带。
- [x] 项目 skill frontmatter 与脚本校验通过。
- [x] YAML 模板解析、相对链接与正文一致性检查通过。

2026-09-14 验证结果：skill-creator 自带 quick_validate 返回 `Skill is valid!`；展示元数据通过长度与调用名检查；6 个 YAML 文件成功解析，Issue 字段 ID 无重复；19 个 Markdown 文件的 57 个本地链接全部可解析。此轮不修改比较器代码，也不重跑已有 28 项代码测试；已有结果在 CURRENT_STATUS 中标为历史原型验证。

## 后续真实验收

- [ ] M1 数值数组实现与正负例测试。
- [ ] M2 锁定并实际运行一个第三方 MoonBit ML 项目。
- [ ] M3 世界模型与 RL 分别提供可重跑展示。
- [ ] 在独立项目目录的新任务中验证 skill 的 UI 发现；父工作区目前通过 AGENTS 链接读入。
- [ ] 发布前将项目作为仓库根，确认 `.github/` 和 skill 一并保留。
- [ ] 按真实开发过程建立提交，确认 namespace、仓库地址和 Mooncakes 发布材料。
- [ ] 用户自行重写申报参考稿，并核实官方材料与验收流程。

## 使用入口

推荐提示：`使用 $json-regress-engineering，读取当前状态，按 M1 契约实现数值数组适配，保留现有容差语义并完成相关验证。`

如果当前任务的 skill 选择器尚未显示它，可以直接指定 `.agents/skills/json-regress-engineering/SKILL.md`；从父工作区使用 `json-regress/.agents/skills/json-regress-engineering/SKILL.md`。不需要把本项目规则安装到全局。
