# 项目协作文件入口

本套文件按用户提供的 TongShiDa 协作包适配，用于接续 `json-regress`，不改变现有库的运行行为。

## 快速接续

1. 看 [CURRENT_STATUS](CURRENT_STATUS.md) 区分已完成与计划。
2. 看 [ROADMAP](ROADMAP.md) 确认当前优先级。
3. 按项目 [skill](../../.agents/skills/json-regress-engineering/SKILL.md) 进入对应任务。

常用资料：[架构](ARCHITECTURE.md)、[接口](INTERFACES.md)、[验证](VALIDATION.md)、[任务模板](TASK_CONTRACT.md)、[尝试记录](ATTEMPT_LOG.md)、[决策](DECISIONS.md)、[接入检查](ADOPTION_CHECKLIST.md)。

已填写的任务：[M1 数值数组](tasks/M1-NUMERIC-ARRAY.md)、[M2 真实项目](tasks/M2-REAL-INTEGRATION.md)、[M3 世界模型与 RL](tasks/M3-WORLD-MODEL-RL-DEMOS.md)。

从 `json-regress/` 启动 Codex 时，项目 skill 位于 `.agents/skills/json-regress-engineering/`。当前父工作区的 `AGENTS.md` 也链接到它，方便从父目录继续任务；未重复安装全局 skill。项目内 skill 目录遵循 [官方发现规则](https://learn.chatgpt.com/docs/build-skills#where-codex-loads-local-skills)。本轮只验证文件结构与入口引用，不声称已在新任务 UI 中验证自动发现。

## 来源与适配

来源归档：`TongShiDa-codex-collaboration-kit-2026-08-24.zip`，由用户提供。

归档 SHA-256：`f896ea12775686eb75da3f4732118e3913c9a72210eae04fb6f32a79292ff775`。2026-09-14 检查了路径安全并验证全部清单哈希；这证明归档内容与附带清单一致，不是发布者身份认证。

| 原包机制 | 本项目适配 |
|---|---|
| 仓库规则与工程 skill | MoonBit 核心、数值数组、ML 集成和展示场景 |
| 设备/端到端验证分级 | 单元、固定数据、真实项目、CI 分项证据 |
| 算法阈值、接口与单位 | 容差公式、形状、dtype、时间步和参考值来源 |
| 硬件任务模板 | 世界模型/RL 场景模板 |
| 架构、接口、任务与交接文件 | 填入原型事实及下一阶段的验收标准 |
| 隐私与凭据规则 | 参赛个人资料、私有模型/数据、令牌的边界 |

保留现有 README、MoonBit 格式与接口生成约定、源码、测试和 CI。没有复制原项目的医学、硬件或凭据泄露结论；没有加入一律人工审批、强制远程 Issue 或多代理并行要求。原包未附单独许可证文件，保留来源说明，不把模板作者身份改写为本项目原创。
