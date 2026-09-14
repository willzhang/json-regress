# 验证策略与证据

## 分项记录，不能互相替代

| 证据类别 | 达成条件 | 不能据此声称 |
|---|---|---|
| `IMPLEMENTED` | 文件或代码已完成 | 可以运行或通过验收 |
| `STATIC_VERIFIED` | 对应格式、检查或构建命令成功 | 业务行为正确 |
| `UNIT_VERIFIED` | 受影响行为测试实际通过 | 真实库已经接入 |
| `FIXTURE_VERIFIED` | 在记录来源的固定输入与独立预期上运行 | 训练质量提升或真实框架当前可运行 |
| `INTEGRATION_VERIFIED` | 锁定版本的真实第三方库实际产生输出并通过本库检查 | 其他版本、后端均兼容 |
| `CI_VERIFIED` | 远程 CI 在对应提交成功，有可访问运行记录 | 比赛官方验收通过 |
| `NOT_RUN` / `FAILED` / `INCONCLUSIVE` | 写明未运行、失败或不足以判断的原因 | 可以用计划替代结果 |

这些是不同维度。每项写明对象、版本、命令和结果，不仅报一个最高等级。CPU 集成不等于 GPU 验证；合成数据、固定导出数据和真实第三方调用分别标记。官方验收与付款记录独立于工程测试。

## 现有命令

从项目根目录执行；本机使用包装脚本，已有 MoonBit 环境可把 `bash scripts/moon-local.sh` 换成 `moon`。

```sh
bash scripts/moon-local.sh info
bash scripts/moon-local.sh fmt
bash scripts/moon-local.sh fmt --check
bash scripts/moon-local.sh check --deny-warn
bash scripts/moon-local.sh build --deny-warn
bash scripts/moon-local.sh test --deny-warn
bash scripts/moon-local.sh test --target native --deny-warn
bash scripts/moon-local.sh run cmd/main
```

这是代码/API 改动后的检查集合，按实际影响选择执行。小型文档或协作模板改动只检查链接、结构与内容一致性。`moon info`/`fmt` 会修改生成接口和格式；不得把自动更新测试期望当成发现正确答案的方法。

已验证工具链：moon 0.1.20260904，moonc v0.10.12+1634b282e (2026-09-07)，Apple Silicon macOS。本机路径在脚本中定义，支持 `JSON_REGRESS_MOON_HOME`；临时目录若消失，应报告环境问题并恢复官方工具链，不伪造测试通过。CI 安装 latest，未来版本漂移可能需要单独处理。现有 `.github/` 位于项目子目录；GitHub 以未来独立发布的项目仓库根目录识别它，当前父工作区并未在 GitHub 运行该工作流。

## M1 数值规则检查

固定通过/失败输入：严格 shape、dtype；转置或维度颠倒；非矩形输入；空数据与标量；元素数错误或溢出；边界容差、零与负数；NaN/Infinity；现有大幅度数值限制；错误坐标、错误总数与展示截断一致性。采用明确可计算的参考值，避免照抄内部实现产生期望。

## M2 独立证据

记录候选选择、来源/许可证、确切版本或提交、运行环境、固定输入/权重、独立参考计算方式和实际命令。至少一条链路现场运行第三方库，不以手工 JSON 冒充。小型输入的参考值可由独立数学计算或另一实现产生，不能由被测库更新基准后自证。

至少演示：合理浮点差异通过；一个数值错误失败；一个结构/布局错误失败。保留失败输出摘要及上游版本，不只展示全部绿色的屏幕。

## M3 科学结论边界

世界模型只验证固定条件下一步输出的结构与数值。若使用简化模型，清楚注明，不能称为完整 Dreamer 或真实世界模型训练实验。

RL 只验证记录轨迹和确定性组件契约。环境版本、随机源、动作序列、reset、终止与时间限制影响结果；“同一个 seed”不足以证明跨平台确定性。对于非确定性训练性能，须另设多次独立运行与统计方法，不能用当前 JSON 容差断言得出算法好坏。[PyTorch 可复现性](https://docs.pytorch.org/docs/stable/notes/randomness)、[Gymnasium 时间限制](https://gymnasium.farama.org/tutorials/gymnasium_basics/handling_time_limits/)

## 证据记录最小格式

日期 / 任务 / 被测代码提交或文件哈希：
来源版本 / 输入与参考值 / 随机性条件：
实际命令 / 后端 / 环境：
期望结果 / 实际结果 / 失败样例：
证据类别 / 未运行范围 / 下一步：

小型文本摘要可提交；运行缓存与长日志放 `artifacts/`，明确命名后再选择需要保留的摘要。不要覆盖参考夹具来消除失败。
