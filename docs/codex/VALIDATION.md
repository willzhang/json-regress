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

已验证工具链：moon 0.1.20260904，moonc v0.10.12+1634b282e (2026-09-07)，Apple Silicon macOS。本机路径在脚本中定义，支持 `JSON_REGRESS_MOON_HOME`；临时目录若消失，应报告环境问题并恢复官方工具链，不伪造测试通过。CI 安装 latest，未来版本漂移可能需要单独处理。项目已初始化为独立 Git 仓库，`.github/` 位于其根目录；已形成 10 个开发阶段正式提交；远程 CI 尚未运行。

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

## 2026-09-14 本轮结果

- 全库 54/54，Wasm 和 Native 均通过；包括原核心 28、numeric 17、trajectory 5、RL 场景 4。numeric 的兼容性测试内部另覆盖 196 组核心/数组标量规则一致性，不额外算作 196 个测试。
- 格式、check/build、通用示例、RL 展示通过。`bash scripts/check-local.sh --integration` 是复现入口，CI 使用同一脚本。
- MoonXi 原始 CPU 模块 115/115：`MOON_WORK=off bash scripts/moon-local.sh -C .external/moonxi-net/moonxi-net test --target native`。独立集成 5/5，`-C integrations/moonxi test -p local/json_regress_moonxi --target native`。
- 世界模型正例最大绝对误差 `1.1920928910669204e-8`，固定绝对阈值 `1e-6`；修改第二个 latent 后在坐标 `[0,1]` 失败。线性基准为二进制精确小算例，零容差通过；单独测试微扰在 `2e-6` 内通过及 `0.1` 错误失败。
- 三个参考夹具通过 `python3 scripts/generate-references.py --check`，校验 JSON、嵌入源码与 SHA-256 清单。生成器没有调用被测实现。
- MoonXi 记录在 upstream.json；实际 checkout 无源码修改。其弃用警告保存在 `artifacts/moonxi-validation.log`，集成不使用 deny-warn；核心仍严格 deny-warn。
- `moon package --list` 本地成功打包，未包含 `.external`、`artifacts` 或 `.git`。这不是 Mooncakes 发布；repository 仍为空，工具对此提示警告。
- Git 快照不是提交；身份配置前 `python3 scripts/check-commits.py` 曾正确失败并报告 0/10。现已将原始 10 个开发阶段的精确 tree 形成正式提交，检查通过；另有状态交接文档更新提交。提交使用真实创建时间，每个阶段的原始观察时间和验证摘要保留在提交正文中。远程 CI、发布、官方验收、付款仍未完成。

## 2026-09-15：M5 完整本地验证

用户确认实现文件入口/标准报告和检查点/比较重放，任务基线 0900883。相同 MoonBit 工具链、Apple Silicon macOS，实际运行 `bash scripts/check-local.sh --integration` 成功。随后补充轨迹缺失行路径修复及回归测试，根模块 Native/Wasm 单测与 CLI 进程验收再次通过，下面记录最终 67 项结果。

- `STATIC_VERIFIED`：根模块 fmt/check/build deny-warn；独立 Native CLI build deny-warn 与定向格式检查；集成 Native/Wasm 检查。接口仅对本项目包执行 info，第三方源码最终干净。
- `UNIT_VERIFIED`：全库 **67/67 Wasm、67/67 Native**（原 54 + checking 13）；独立集成 **6/6 Native、6/6 Wasm**（原 5 + 三步模型）。没有重复统计测试内的数据组合。
- `FIXTURE_VERIFIED`：5 组 JSON/嵌入源码再生成与 SHA-256 一致，包括新增三步输入说明和独立 Python 检查点；原 3 组未改变。
- 文件接口：**19 个进程验收用例**通过，覆盖外部工作目录、0/1/2、稳定输出、形状与布局、无效规则/JSON、数字下溢、符号链接指向输入时拒绝覆盖、帮助与未知选项。移走失败包并删除原始输入后，独立进程仍重现同一报告；修改记录则报告 replay_drift。
- `INTEGRATION_VERIFIED`：实际运行 MoonXi 三步 Linear/ReLU 模型，Native/Wasm 各生成 9 个检查点；两个后端相对独立 Python 的最大绝对误差均为 **5.960464463661275e-8**，预设阈值 **1e-6**；本次 Native/Wasm 输出差为 **0**。
- 实际执行自建 RL 环境，两个后端均与独立 Python 轨迹一致；没有真实 RL 算法或 Gymnasium 集成声明。
- **6 个实际输出对照**：模型与 RL 各自的 Python→Native、Python→Wasm、Native→Wasm。
- **7 个注错与比较重放**：模型中间层、同 shape 布局、时间位移、缺失检查点、输入来源变化、RL reward 变化和非法步号；分别返回预期类别。中间层失败定位在 `1/linear1`、坐标 `[0,1]`；reward 失败定位在 goal episode 的 step 1。来源及无效轨迹退出 2，其余回归退出 1。
- 可重建长日志和 JSON 证据位于 `artifacts/moonxi-validation.log` 与 `artifacts/ml-replay/`，不加入发行包；源码与明确生成命令保留在 Git。

本轮没有重跑上游原始 115 项测试，旧结果仍按日期保留。远程 CI 配置调用更新后的同一检查脚本，但 **远程 CI / 包发布 / 官方验收仍 NOT_RUN**。跨后端相等只证明本次固定算例，不保证任意模型、工具链或训练运行一致。重放验证的是捕获的比较；实际模型运行由单独的生成器命令提供证据。


## 2026-09-15：首次 GitHub 公开发布

`CI_VERIFIED`：提交 `3620117dd3f03f95cc0f346d1f547dcab8984dfd` 的[GitHub Actions](https://github.com/willzhang/json-regress/actions/runs/34912598554) conclusion 为 success。仓库 https://github.com/willzhang/json-regress 已公开，默认分支 codex/ml-regression，原开发历史保留。该工作流实际执行完整本地检查入口，不以本地测试替代远程结果。远程日志缓存在 artifacts/github-ci-34912598554.log，不提交。Mooncakes 包发布与官方报名仍未完成；后续状态见 [PUBLICATION](../PUBLICATION.md)。

## 2026-09-15 Mooncakes 正式 namespace

`willzhang/json_regress@0.1.0` 替换主库占位名，内部导入和两个本地模块的依赖同步更新；`moon info` 重新生成接口，未改变比较逻辑。完整 `bash scripts/check-local.sh --integration` 再次通过：Wasm/Native 各 67 项、真实集成各 6 项、19 项 CLI 进程验收、6 个实际输出对照和 7 个注错重放；五组独立参考仍一致。日志在忽略的 `artifacts/mooncakes-prepublish-validation.log`。此处记录发布前本地验证，注册表上传及独立安装结果在 PUBLICATION 中补充。

## 2026-09-15 注册表发布与独立消费

`REGISTRY_VERIFIED`：发布源提交 `dde5140df0234f718f2ae16ff36364aa319a3028` 的远程 CI 通过；`moon publish` 返回 200 OK。[Mooncakes 包页](https://mooncakes.io/docs/willzhang/json_regress) 可访问，版本为 0.1.0。全新独立目录从注册表下载依赖，无本地路径替代；归档 120 个文件与本地审计包逐字节一致。根库、numeric、trajectory、checking 消费测试在 Wasm/Native 各 3/3，通过、差异和非法输入语义均符合预期。元数据与哈希在忽略的 artifacts/mooncakes-release.json；完整发布记录见 [PUBLICATION](../PUBLICATION.md)。本轮没有改动或提交用户正在编辑的申报参考稿。
