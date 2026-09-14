---
name: json-regress-engineering
description: Plan, implement, review, or validate this json-regress MoonBit library, its numeric-array rules, real ML integrations, and world-model or reinforcement-learning regression examples. Use for work in this project; not for general model training or unrelated repositories.
---

# JSON Regress Engineering

以本 skill 向上三级、含 `moon.mod` 的目录为项目根目录。先读 [AGENTS](../../../AGENTS.md) 和 [当前状态](../../../docs/codex/CURRENT_STATUS.md)，再读取目标代码。当前用户指示优先于历史任务文档。

## 按任务选择材料

| 任务 | 重点 | 按需读取 |
|---|---|---|
| `core` / `numeric-array` | 路径、容差、形状和失败报告 | [接口](../../../docs/codex/INTERFACES.md)、[M1](../../../docs/codex/tasks/M1-NUMERIC-ARRAY.md) |
| `integration` | 真实库版本、独立参考值、CPU 最小链路 | [架构](../../../docs/codex/ARCHITECTURE.md)、[M2](../../../docs/codex/tasks/M2-REAL-INTEGRATION.md) |
| `scenario` | 固定样例、时间对齐和随机性边界 | [世界模型与 RL](../../../docs/codex/tasks/M3-WORLD-MODEL-RL-DEMOS.md) |
| `documentation` / `handoff` | 已完成与计划、后续入口 | [路线图](../../../docs/codex/ROADMAP.md)、[决策](../../../docs/codex/DECISIONS.md) |

跨模块修改先明确谁产生输入、谁适配、谁比较，以及一条能验证该接口的用例。非微小任务复用已有 M1/M2/M3 契约；没有合适契约时使用 [任务模板](../../../docs/codex/TASK_CONTRACT.md) 的相关字段即可。

## 实现与验证的判断标准

- 为正在解决的真实失败增加行为测试，至少包含应通过和应失败的输入；不以测试数量、源码行数或提交次数替代价值判断。
- 保持核心与框架依赖分离。可用小型 CPU 例子验证时，不启动完整训练、不引入 GPU 依赖。
- 逐路径相对容差与 PyTorch 的公式不同。对齐测试框架之前明确公式；结果不符时先检查数据、形状、布局、dtype、时间步和误差尺度，不先放宽阈值。
- “统计摘要”不能掩盖逐元素错误；NaN/Infinity 不能因均值或误差计算异常而被判为通过。
- 真实框架跑通、固定导出文件回放、合成示例是不同证据。按 [验证策略](../../../docs/codex/VALIDATION.md) 分别记录，不把名称里包含世界模型或 RL 的样例当成模型效果验证。
- 对已经确定的可逆实现细节自行推进。若集成失败，记录证据并尝试契约中的备选；超过探索预算时继续可独立完成的工作，报告未证实的链路，不擅自把合成案例改称真实集成。

## 留下可继续工作的状态

按改动更新当前状态、接口或决策。重复尝试使用 [尝试记录](../../../docs/codex/ATTEMPT_LOG.md)。最终说明可运行入口、实际命令和结果、未运行部分及下一项任务；只有用户明确需要时才创建远程 Issue/PR 或新的 Codex 任务。
