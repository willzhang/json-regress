# 文件比较、检查点诊断与比较重放

已实现：纯 MoonBit `checking` API 与独立 Native CLI。既能检查普通 JSON，也能比较张量、规范轨迹和模型检查点。默认容差保持对称的“绝对或相对”，没有自动放宽阈值或更新基线。

## 直接试用

从项目根目录运行：

```sh
bash scripts/json-regress.sh compare examples/files/baseline.json examples/files/candidate.json examples/files/json.rules.json --format json
```

这个示例退出 0。首次构建 CLI 需要官方 `moonbitlang/x@0.4.43` 的文件接口；核心库仍不依赖它。已安装 MoonBit 的新机器先执行 `moon update` 更新索引。包装脚本保留调用者的工作目录，输入、输出相对路径以调用位置为准。

故意失败并重放，两个比较命令都应退出 **1**：

```sh
demo_dir="$(mktemp -d)"
bash scripts/json-regress.sh compare examples/files/baseline.json examples/files/regression.json examples/files/json.rules.json --format json --report "$demo_dir/report.json" --repro "$demo_dir/failure.json"
bash scripts/json-regress.sh replay "$demo_dir/failure.json" --format json
```

也可以只构建一次，再从任意目录使用生成的 Native 可执行文件：

```sh
binary="$(bash scripts/build-cli.sh)"
"$binary" --help
```

完整验证：`bash scripts/check-local.sh`；加入真实模型及跨后端验证：`bash scripts/check-local.sh --integration`。

## 命令契约

```text
json-regress compare EXPECTED ACTUAL RULES [--format text|json] [--report NEW_FILE] [--repro NEW_FILE]
json-regress replay REPRO_FILE [--format text|json] [--report NEW_FILE]
```

| 退出码 | 状态 | 含义 |
|---|---|---|
| 0 | match | 在明确规则下匹配 |
| 1 | mismatch | 有效输入存在结构、时序位置或数值差异 |
| 2 | error | JSON、规则、张量/轨迹格式错误，来源不可比较，重放记录漂移或文件操作错误 |

stdout 默认是一段文本摘要，`--format json` 输出一份完整 JSON 报告；构建日志在 stderr。`--report` 总是写 JSON；`--repro` 仅在已读取三个输入后的失败比较时写出。缺失文件、输出失败等命令边界错误使用同一报告封装，但无法捕获完整比较输入时不生成失败包。

指定的输出文件必须不存在，包括已存在的输入文件、其符号链接和已有报告。父目录需要已存在。工具不会创建父目录或覆盖基线。重复的选项、未知选项和不适用的选项都报错。第一版将文件整体读入内存，没有 JSONL 或流处理接口。

## 版本 1 规则

每份规则必须含 `schema_version: 1` 和 `mode`。未知字段及不适用于当前模式的字段拒绝，容差必须有限非负。`max_findings` 默认 100、`max_samples` 默认 8，允许 0–1000；截断只限制展示，不改变完整错误计数或退出码。`max_findings: 0` 时仍保留首条诊断。

| mode | 专用可选字段 | 输入 |
|---|---|---|
| json | `ignore_paths`、`tolerances` | 任意标准 Json 文档；路径和容差语义沿用核心 |
| tensor | `pointer`、`absolute`、`relative`、`max_samples` | 精确 pointer 下的 `{shape,dtype,data}`；pointer 默认根 |
| trajectory | `absolute`、`relative`、`max_samples` | [规范步骤数组](RL_TRAJECTORY.md) |
| checkpoints | `absolute`、`relative`、`max_samples`、`variable_metadata` | 下述模型检查点包 |

JSON 模式的 `tolerances` 项只接受 `path`、`absolute`、`relative`，path 必填，未给的容差分量为 0。数值模式也默认零容差。具体文件见 [JSON 规则](../examples/files/json.rules.json)、[张量规则](../examples/files/tensor.rules.json)、[轨迹规则](../examples/files/trajectory.rules.json)、[检查点规则](../examples/files/checkpoints.rules.json)。

文件接口额外扫描合法 JSON 中字符串以外的数字字面量：非有限结果以及非零数下溢成零会报错，即使位于忽略字段中。标准解析器的缺省解析深度上限为 1024，随后输入结构限制为 128 层。核心 `compare(Json, Json)` 仍不能恢复调用方已经丢弃的数值精度；文件检查也不提供任意精度十进制运算或保留重复对象键的能力。

## 模型检查点格式

可运行完整输入见 [独立 Python 参考](../fixtures/world_model_checkpoints.json)。每份包包含：

- `schema_version: 1`。
- `metadata`：`model_id`、`input_sha256`、`weights_sha256`、`generator`、`backend`、`dtype`、`randomness` 必须是非空字符串；两个摘要必须是 64 位小写十六进制。可添加其他来源字段，默认同样比较。
- `checkpoints`：有序数组，每项恰好包含 `id`、`episode_id`、`step`、`layer`、`tensor`。字符串非空，step 为非负 Int，tensor 遵守 numeric 的形状、数据与有限数值约束。

id 在包内唯一，episode/step/layer 组合也唯一。一个 episode 的检查点连续出现，step 不得倒退；同一步可以记录不同层。检查点包允许选定步的稀疏采样，**不替代 RL 轨迹的连续性契约**。

比较顺序明确：

1. 两侧格式都必须有效。
2. 默认严格比较所有 metadata。仅 `variable_metadata` 中明确列出的顶层字段允许变化，且这些字段必须存在于两侧；例如跨后端与独立实现对照时显式允许 `backend` 和 `generator` 不同。摘要是生成者对输入与权重的声明，比较器不能验证其真实性。
3. 检查 id 集合、数组顺序及 episode/step/layer 对齐；有结构差异时先报告，不继续给出可能误导的数值比较。不会自动重排后判为通过。
4. 对齐后逐检查点调用 numeric，保留 shape/dtype、超差数量与坐标。按输入记录顺序选择首次观察到的偏差；没有记录的中间计算无法定位，不推断根因。

`source_mismatch` 是退出 2；`missing_checkpoint`、`unexpected_checkpoint`、`checkpoint_order_mismatch`、`checkpoint_location_mismatch` 是退出 1；`shape_mismatch`、`dtype_mismatch`、`numeric_mismatch` 也为退出 1。即便把 metadata 的 dtype 声明为变量，张量自身的 dtype 仍严格比较。

## 标准报告

`Report.to_json()` 和 CLI JSON 使用同一个 schema。对象键按 UTF-16 字典序编码，报告没有时间戳；相同输入与规则生成相同输出。

| 字段 | 含义 |
|---|---|
| `schema_version`、`tool_version` | 当前为 1、0.1.0 |
| `mode`、`status`、`exit_code` | 模式、match/mismatch/error、0/1/2 |
| `rules` | 解析成功时保留调用者提供的规则；语义仍包含文档规定的默认值 |
| `findings_total` | 未截断的诊断项数量；不是出错元素总数 |
| `findings`、`findings_truncated` | 有界诊断列表及是否截断 |
| `first_difference` | 首条诊断，成功为 null；也可表示输入或操作错误 |
| `statistics` | 模式相关统计；tensor 含完整数值统计，checkpoints 含检查点数量与有效数值比较的最大绝对误差 |

诊断项包含 `code`、`location`、`details`。JSON 模式的值使用 `{present:false}` 和 `{present:true,value:null}` 区分缺失与 null。张量 details 包含两侧 shape/dtype，数值比较时还含 `total`、`mismatched`、`max_absolute_error`、`samples` 与截断标记。样本给出扁平下标、行优先坐标、两侧值及绝对误差；`max_samples:0` 时不输出坐标样本，但错误总数与失败状态保留。

轨迹诊断带 row、episode_id、step、field，按行的数字顺序处理，所以 step 2 在 step 10 前。同行按 episode_id、step、observation、action、reward、next_observation、terminated、truncated 排序。JSON 模式继续沿用原有编码路径字典序。无效轨迹先拒绝；不会靠容差放过断裂的 observation/next_observation 或非法 reset。

## 比较重放与实际模型运行

失败包是一个 JSON 文件，包含版本、kind、三个原始文本、当时的报告以及来源文件路径清单。`replay` 从内嵌文本重新执行比较，不读取旧路径；再核对结果是否与记录一致，不一致报 `replay_drift`。它能检查比较结果漂移，不是防篡改签名，也不执行模型或环境。

实际生成器的单独入口：

```sh
bash scripts/moon-local.sh -C integrations/moonxi run cmd/export --target native
bash scripts/moon-local.sh -C integrations/moonxi run cmd/export --target wasm
bash scripts/moon-local.sh run cmd/export_rl --target native
bash scripts/moon-local.sh run cmd/export_rl --target wasm
```

参考中的 float32 标签表示预期的输出类型契约，Python 标量参考采用 Double 精度计算，未声称模拟逐操作 Float 舍入。世界模型命令实际执行锁定 MoonXi 的 Linear/ReLU，三步递推来自前一步的真实 Float 输出，每步保存 linear1、relu、latent 共 9 个检查点；仍是固定、未训练的小型动力学示例。后端标签由编译目标生成。RL 命令实际执行项目自建确定性环境，输出完整规范轨迹。

`scripts/check-ml-replay.py` 比较这四份实际输出、独立 Python 参考及跨后端结果，并验证中间层、同 shape 布局、检查点时间/缺失、来源、RL reward/时间等 7 个负例及重放。可重建证据位于被 Git 忽略的 `artifacts/ml-replay/`；长期结果摘要见 [验证记录](codex/VALIDATION.md)。
