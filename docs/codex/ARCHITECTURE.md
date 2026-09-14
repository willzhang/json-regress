# 架构与边界

## 当前实际结构

```text
MoonBit 调用方 / cmd/main
        │ Json + Rules
        ▼
json_regress.mbt
  规则校验 → 递归比较 → Difference[] → 文本报告 / Mismatch
        │
        └─ 标准 Json、Map、Array；无第三方运行时依赖
```

- `json_regress.mbt`：当前全部核心实现。
- `json_regress_test.mbt`、`README.mbt.md`：行为与文档测试。
- `cmd/main/`：三个已运行的原型示例。
- `pkg.generated.mbti`：生成的公开接口；由 `moon info` 更新。
- `scripts/moon-local.sh`：本机工具链入口。

## 已接受的扩展方向，尚未实现

```text
真实 MoonBit ML 库 ──小型 CPU 前向输出──┐
独立参考实现 ──固定输入/权重/结果───────┤
世界模型一步预测 / RL 短轨迹样例──────┤
                                      ▼
                     明确格式的适配器与数据夹具
                                      ▼
                数值数组规则 + JSON 回归核心
                                      ▼
                   错误位置、误差摘要、失败退出
```

建议新增 `numeric/` 包保存数值数组逻辑；核心只在需要时提取共用数学助手。`examples/integration/` 保存真实项目的薄调用方与版本记录，`examples/world_model/` 和 `examples/rl/` 保存两个展示。名称是目录设计建议，执行任务时可调整并更新本文；这些路径目前未创建。

`fixtures/` 只保存小型可公开参考数据及其元信息，`artifacts/` 保存可重建结果。Python 若用于产生独立参考数据，属于可选工具，不成为核心库的运行依赖。第三方源码与缓存放 `.external/`，不作为本库原创源码复制提交。

## 为什么要有真实接入

至少一条证据链应包括：固定版本的第三方 MoonBit 库实际运行 → 取得输出 → 调用本库 → 对合理波动通过、对植入错误失败。只回放预先导出的 JSON 属于固定数据验证，不能证明当前框架可运行或适配正确。

优先探查 MoonXi-net 的 CPU 部分，若需要修改编译器或大量环境修复，转查 MbTorch 的小型 CPU/Wasm 模型。候选来源：[MoonXi-net](https://github.com/moonxi-net/moonxi-net)、[MbTorch](https://github.com/c-tomioka/mbtorch)。选择前核对当前版本、许可证、接口和实测结果。

## 成本与扩展约束

不新增训练框架、GPU 算子、自动求导、分布式服务、可视化站点或实验管理平台。张量 JSON 只服务小型回归夹具，不用于承诺高吞吐模型权重交换。目录拆分由依赖隔离需要驱动，不为层数或代码量扩张项目。
