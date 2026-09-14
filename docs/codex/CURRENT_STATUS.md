# 当前项目状态

更新：2026-09-15。M0–M3 与本轮 M5 两项扩展均已完成本地实现与验证，M4 发布/申报仍待完成。独立 Git 仓库位于项目根，分支 `codex/ml-regression`。GitHub 登录已确认（willzhang）；仅为本仓库配置公开署名及 noreply 邮箱。**10 个开发阶段均已形成正式提交，数量检查通过**，另有交接文档更新提交，当前总数以检查脚本为准。见 [开发历史](../DEVELOPMENT_HISTORY.md) 和 [Git 交接](../GIT_HANDOFF.md)。

## 已完成与证据

| 对象 | 状态 |
|---|---|
| JSON 核心 | 原有 28 项测试仍通过；路径、缺失/null、容差与报告语义保留 |
| M1 numeric | 形状/dtype、输入保护、JSON Pointer 适配、整块容差、完整统计与有界样本；含文档测试共 17 项 |
| trajectory | 5 项格式、连续性、重置与结束标志测试 |
| RL 场景 | 4 项测试；两段自建小环境实际轨迹与独立 Python 参考一致 |
| 全库 | Wasm / Native 各 **67/67**；格式、check/build 均通过，核心使用 deny-warn |
| M2 MoonXi | MIT；锁定 `b485c25faaefa768e035a534fb1e64fdbfac68a6`；真实 CPU Linear 输出与独立算式一致 |
| M3 世界模型 | 真实 CPU Linear–ReLU–Linear 的固定未训练动力学示例；最大绝对误差约 `1.1920928910669204e-8` |
| 集成测试 | Native / Wasm 各 **6/6**；包括真实三步模型检查点 |
| 上游测试 | MoonXi CPU **115/115**，与本库数量分开；有上游弃用警告，未修改上游源码 |
| 参考数据 | 5 个可再生成文件组：原 3 个、三步输入说明、独立三步检查点参考；JSON/嵌入源码/SHA-256 检查通过 |
| M5 文件比较 | json/tensor/trajectory/checkpoints；schema 1 标准报告、0/1/2 退出码、文本数字下溢检查；13 项单测及 19 项进程验收 |
| M5 模型定位与重放 | 三步 9 检查点、来源门槛、顺序/时间/shape/dtype/坐标诊断；6 个真实输出对照和 7 个注错及重放通过 |
| 跨后端结果 | 本次模型 Native/Wasm 差为 0；两者相对独立 Python 最大绝对误差约 5.96e-8，预设阈值 1e-6 |
| CI / 发布 / 报名 | CI 配置完成但远程 NOT_RUN；未建公开仓库、未发布 Mooncakes、未报名 |

## 复现入口

`bash scripts/check-local.sh`：核心、数值数组、RL、checking 与 Native 文件 CLI；首次 CLI 构建可能获取官方 x 文件接口，不下载额外 ML 框架。

`bash scripts/check-local.sh --integration`：加上锁定源码、真实 MoonXi Native/Wasm 测试、两个模型展示及实际输出/重放验收。长日志在 `artifacts/moonxi-validation.log`，机器可读证据在 `artifacts/ml-replay/summary.json`，均不提交。

文件入口、示例与报告格式见 [FILE_COMPARISON](../FILE_COMPARISON.md)。

本机工具链：moon 0.1.20260904，moonc v0.10.12+1634b282e (2026-09-07)，Apple Silicon macOS。包装脚本支持 `JSON_REGRESS_MOON_HOME`；工具链位置通过本地配置指定，其他机器可直接安装官方工具链。

## 已知边界与下一步

数值基于 Double，保守拒绝非有限值和绝对值大于等于 2^53；无法恢复上游已丢失精度。dtype 是源类型标签，不是二进制转换。轨迹要求从 step 0 开始，允许最后 episode 是前缀，同 episode 观测连续性严格相等。ML 只验证本次固定 CPU 算例，未验证 GPU、模型训练质量或算法收益。当前模块名 `local/json_regress` 仍是占位。

下一步确认 Mooncakes 包名、仓库地址和公开发布授权，实际运行远程 CI、包发布和官方提交。

2026-09-15：[同类项目评估](../COMPETITIVE_REVIEW-2026-09-15.md) 后，用户确认实施文件报告与模型检查点/比较重放，两项已完成。任务契约见 [M5](tasks/M5-FILE-REPORT-REPLAY.md)。原始核心 API 和默认容差不变；比较重放不执行模型，真实生成器运行独立记录。后续进入 M4，不继续扩建训练或 GPU 范围。
