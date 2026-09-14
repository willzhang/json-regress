# 架构与边界

```text
MoonBit / 标准 Json 调用方
  ├─ JSON 核心：路径规则 → Difference[] → 报告 / 断言
  ├─ numeric：Tensor 校验 → shape/dtype → 数据容差 → 全量统计 + 有界样本
  └─ trajectory：规范化步骤校验 → JSON 元信息 + numeric 向量比较

独立 Python 算式 → fixtures JSON / 嵌入源码 / SHA-256
                           ↓
MoonXi CPU 独立模块 → 真实 Linear / ReLU → numeric
自建确定性小环境 → 两段实际 RL 轨迹 → trajectory
```

核心 `json_regress.mbt`、`numeric/`、`trajectory/` 只依赖 MoonBit 标准类型和本模块；第三方框架不进入核心依赖图。`fixtures/` 保存独立参考数据与可在无文件 IO 的后端运行的嵌入源码，来源是 `scripts/generate-references.py`。`examples/rl/` 是确定性小环境，`cmd/rl/` 与 `cmd/main/` 为可运行展示。

`integrations/moonxi/` 是自己的 MoonBit 模块，`moon.work` 引用根模块与 `.external/moonxi-net/moonxi-net` CPU 模块，覆盖上游包含 CUDA 的工作区范围。上游版本/许可证见 `upstream.json`，通过 `scripts/fetch-moonxi.py` 下载并校验确切提交与干净工作树。适配器从实际框架 shape 和 Float 数据读取，不用期望 shape 覆盖实际 shape。

`artifacts/` 存诊断和可重建结果，`.external/` 存第三方源码，均被 Git 忽略。Python 是独立参考生成工具，不是运行核心库的依赖。当前包归档检查没有包含缓存、上游源码或 Git 私有状态；GitHub/技能等点目录用于源码仓库协作，不等同于 Mooncakes 包内容。

模型固定输入和权重，比较链路真正执行第三方 CPU 层；RL 则执行自建小环境并明确来源，不声称接入 Gymnasium。没有模型训练、GPU、付费服务、自动求导实现、分布式服务或大规模性能承诺。


M5 新增 `checking/` 纯 MoonBit 协议层，组合 core/numeric/trajectory，承担严格规则解析、检查点来源与结构检查、稳定报告及比较重放。`cli/` 是自己的模块与工作区，文件 IO 只依赖官方 x/fs，不进入核心库依赖图；构建包装保留调用方工作目录。

`cmd/export_rl` 执行自建环境导出轨迹；`integrations/moonxi/cmd/export` 执行锁定模型的三步真实推断并导出检查点。`scripts/check-ml-replay.py` 分别运行 Native/Wasm 生成器，再使用同一 CLI 做独立参考和跨后端比较、注错与携带式重放。参考端计算仍是独立 Python 标量算式。
