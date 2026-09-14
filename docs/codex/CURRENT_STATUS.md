# 当前项目状态

更新：2026-09-14。本轮完成 M1–M3 的本地实现与验证。独立 Git 仓库位于项目根，分支 `codex/ml-regression`；尚待用户提供署名，**正式提交数为 0**。已按真实开发顺序保留 10 个阶段快照，不能算作提交，见 [Git 交接](../GIT_HANDOFF.md)。

## 已完成与证据

| 对象 | 状态 |
|---|---|
| JSON 核心 | 原有 28 项测试仍通过；路径、缺失/null、容差与报告语义保留 |
| M1 numeric | 形状/dtype、输入保护、JSON Pointer 适配、整块容差、完整统计与有界样本；含文档测试共 17 项 |
| trajectory | 5 项格式、连续性、重置与结束标志测试 |
| RL 场景 | 4 项测试；两段自建小环境实际轨迹与独立 Python 参考一致 |
| 全库 | Wasm / Native 各 **54/54**；格式、check/build 均通过，核心使用 deny-warn |
| M2 MoonXi | MIT；锁定 `b485c25faaefa768e035a534fb1e64fdbfac68a6`；真实 CPU Linear 输出与独立算式一致 |
| M3 世界模型 | 真实 CPU Linear–ReLU–Linear 的固定未训练动力学示例；最大绝对误差约 `1.1920928910669204e-8` |
| 集成测试 | **5/5** Native；数值、形状/dtype、latent 轴交换与非有限输入负例通过 |
| 上游测试 | MoonXi CPU **115/115**，与本库数量分开；有上游弃用警告，未修改上游源码 |
| 参考数据 | 3 个独立 Python 标量计算夹具，JSON 和嵌入源码严格再生成检查、SHA-256 记录 |
| CI / 发布 / 报名 | CI 配置完成但远程 NOT_RUN；未建公开仓库、未发布 Mooncakes、未报名 |

## 复现入口

`bash scripts/check-local.sh`：核心、数值数组与 RL，不下载额外 ML 依赖。

`bash scripts/check-local.sh --integration`：加上锁定源码与真实 MoonXi CPU 测试、两个模型展示。长诊断日志在 `artifacts/moonxi-validation.log`，不会提交。

本机工具链：moon 0.1.20260904，moonc v0.10.12+1634b282e (2026-09-07)，Apple Silicon macOS。包装脚本支持 `JSON_REGRESS_MOON_HOME`；工具链位置通过本地配置指定，其他机器可直接安装官方工具链。

## 已知边界与下一步

数值基于 Double，保守拒绝非有限值和绝对值大于等于 2^53；无法恢复上游已丢失精度。dtype 是源类型标签，不是二进制转换。轨迹要求从 step 0 开始，允许最后 episode 是前缀，同 episode 观测连续性严格相等。ML 只验证本次固定 CPU 算例，未验证 GPU、模型训练质量或算法收益。当前模块名 `local/json_regress` 仍是占位。

下一步由用户提供选定姓名和 GitHub noreply 邮箱，按阶段快照建立正式提交并审阅至少 10 次有效提交；再确认包名、仓库地址和公开发布授权，实际运行远程 CI、包发布和官方提交。
