# json-regress

面向 MoonBit 的 JSON、数值数组与轨迹回归断言库。对明确路径忽略易变字段，对浮点输出设置容差，严格校验 shape/dtype，并报告具体路径、错误坐标和超差统计。已接入真实 MoonXi-net CPU 层，提供世界模型一步预测和 RL 短轨迹展示。

当前模块名 `local/json_regress` 是本地占位名称，尚未上传 GitHub 或发布到 Mooncakes。核心使用现有 `Json` 类型，无第三方运行时依赖；可选 ML 集成在独立模块中。

## 快速运行

在本项目目录执行（先安装官方工具链）：

```sh
bash scripts/check-local.sh              # 核心、数值数组、RL：无额外下载
bash scripts/check-local.sh --integration # 加上固定版本 MoonXi CPU 集成
```

可单独执行 `bash scripts/moon-local.sh run cmd/main`、`run cmd/rl` 或 `-C integrations/moonxi run cmd/showcases --target native`。首次 ML 集成会下载锁定的公开源码与其 Mooncakes 依赖。各展示都包括通过例与植入错误；与预期不符时以非零状态退出。

安装 [MoonBit 官方工具链](https://www.moonbitlang.com/download) 后，可直接运行 `moon test`。包装脚本默认使用 PATH 中的 `moon`；也可设置 `JSON_REGRESS_MOON_HOME`，或在未跟踪的 `.moon-home` 文件中填写工具链目录。

开发时验证的版本：`moon 0.1.20260904`，`moonc v0.10.12+1634b282e (2026-09-07)`。

## 使用方式

在调用方的 `moon.pkg` 中导入：

```moonbit nocheck
///|
import {
  "local/json_regress" @regress,
}
```

下面是库的可执行文档测试；测试中的 `@json_regress` 即当前模块。

```mbt check
///|
test "readme regression example" {
  let rules = @json_regress.Rules::new(ignore_paths=["/request_id"], tolerances=[
    { path: "/score", absolute: 0.01, relative: 0.0, },
  ])
  @json_regress.assert_matches(
    { "request_id": "old", "score": 0.8, "count": 100 },
    { "request_id": "new", "score": 0.805, "count": 100 },
    rules~,
  )
  let differences = @json_regress.compare({ "count": 100 }, { "count": 99 })
  assert_eq(differences[0].path, "/count")
  assert_eq(differences[0].reason, @json_regress.ValueMismatch)
}
```

`compare(expected, actual, rules?)` 返回 `Array[Difference]`，空数组表示符合规则；每项含路径、原因、期望值和实际值。`assert_matches` 在不匹配时抛出 `Mismatch`；非法规则抛出 `InvalidRule`。`format_differences` 提供文本报告，例如：

```text
"/loss": OutsideTolerance; expected=0.25; actual=0.28
"/sample_count": ValueMismatch; expected=100; actual=99
```

## 数值数组、真实集成与轨迹

| 能力 | 可运行证据 | 说明 |
|---|---|---|
| `numeric.Tensor` | [可执行用法](numeric/README.mbt.md) | 显式 shape/dtype/data；整块容差、坐标和有上限的错误样本 |
| MoonXi CPU Linear | [集成入口](integrations/moonxi/README.md) | 真实第三方前向计算与独立 Python 参考比较 |
| 一步世界模型 | [场景说明](docs/WORLD_MODEL.md) | 真实 Linear/ReLU 层的小型未训练动力学示例 |
| `trajectory` 与 RL | [场景说明](docs/RL_TRAJECTORY.md) | 实际运行自建小环境；独立参考和时间/终止语义检查 |

numeric 默认零容差，保持下文的对称绝对或相对公式。形状和 dtype 不同时先报告结构差异，不进行广播或自动变换。默认最多展示 8 个超差元素，完整统计和通过判定不受截断影响。

## 比较语义

- 对象不考虑键插入顺序，数组按原始下标比较；不做数组重排或按 id 匹配。
- 缺失用 `None` 表示，JSON null 用 `Some(Null)` 表示；缺失节点与 null 不相等。
- 路径采用 [RFC 6901](https://www.rfc-editor.org/rfc/rfc6901) 的 JSON Pointer 字符串语法。`""` 指向根，`"/"` 指向空字符串键；键中的 `~` 写成 `~0`，`/` 写成 `~1`。不支持 URI fragment、JSONPath、通配符、正则或 Unicode 归一化。
- 规则只匹配完整路径。忽略某路径会跳过该节点及其子树，也会忽略该节点的缺失。忽略父节点优先于子节点容差。数组中的忽略只作用于原始下标，不会移动其余元素。
- 不存在的规则路径不生效，也不报错。`/00` 不会命中数组下标 0，`/-` 不匹配数组元素；它们可以匹配同名对象键。这里借用 Pointer 语法作为比较规则标识，并非提供独立的完整 Pointer 求值器。
- 数值容差只作用于该路径的两个数值，不把字符串转成数字，也不继承到子节点。通过条件是 `abs(a-b) <= absolute` **或** `abs(a-b) / max(abs(a),abs(b)) <= relative`；两个零视为相等。相对误差使用两侧较大绝对值，对调输入不改变结果。
- 容差必须是有限非负值。同一路径多条容差会报错，避免先后顺序影响结果；即使忽略根节点，也会先检查全部规则。
- 报告按编码后路径的 UTF-16 字典序排序；因此数组的 `/10` 排在 `/2` 前。报告中的对象也按键字典序输出。深度超过 128 层时返回 `DepthLimit`，不视为匹配。

## 数值和输入边界

默认数值相等指 **Double 数值相等**，不代表任意精度十进制相等。`1` 与 `1.0`、正零与负零可以相等；数值仍受上游解析或构造时的浮点舍入影响。

对于参与数值比较的节点，原型保守拒绝 `abs(value) >= 2^53`、NaN、无穷值，返回 `UnsupportedNumber`，即使两侧相同也不通过；大整数标识符可在业务 JSON 中使用字符串。若 Json 保留了表明非零数下溢为零的 `repr`，也会拒绝。

**已知限制：当前标准解析器会将 `1e-999` 解析为 0 且不保留原文。只接收 Json 的接口无法恢复已经丢失的数值信息；它与 0 比较会相等。**同理，超出 Double 精度的普通小数可能被上游舍入成相同值。不要用于要求原始十进制完全一致的金额核对。需要精确小数时应在输入层保留字符串，或另行设计精确数值接口。

输入应是有限、无环的 JSON 树。本库不重新解析 JSON，不检测被上游解析器覆盖的重复对象键；不做超大文档性能或安全加固承诺。忽略路径会跳过该子树中的数值检查。差异报告保留输入 Json 的引用，应在检查和报告期间避免修改输入。

## 当前验证与交付状态

2026-09-14，本机 Wasm、Native 各 54 项测试通过；5 项真实 MoonXi CPU 集成测试通过；三个参考夹具的独立 Python 再生成检查通过。完整验证命令包括格式、check/build、测试和展示。上游 CPU 自身 115 项测试另有通过记录，不计入本库测试数量。

`.github/workflows/check.yml` 已复用本地验证脚本，远程 Actions 尚未运行。发布前仍需确认署名、形成至少 10 个有实质内容的 Git 提交、确定 Mooncakes namespace 与仓库地址、发布并获得实际 CI 结果。当前署名未定，开发阶段仅保存本地 tree 快照，正式提交数为 0；详见 [Git 交接](docs/GIT_HANDOFF.md)。

暂无快照文件管理、自动更新快照、JSON Patch、无序数组匹配、CLI 文件对比或性能承诺。简化世界模型与 RL 场景不证明模型质量或算法收益。核心为原创实现，未移植同类库源码；ML 集成直接调用 MIT 许可的 MoonXi-net，源码置于被忽略的 `.external/`。本项目采用 [Apache-2.0](LICENSE)，实现与文档由 AI 辅助生成，需由维护者理解、审阅后再发布。

## 项目协作

入口为 [当前状态](docs/codex/CURRENT_STATUS.md)、[路线图](docs/codex/ROADMAP.md) 和 [验证记录](docs/codex/VALIDATION.md)。项目规则见 [AGENTS.md](AGENTS.md)，工程 skill 见 [SKILL.md](.agents/skills/json-regress-engineering/SKILL.md)。申报材料的可调整文本见 [AI 辅助参考稿](docs/PROPOSAL_REFERENCE.md)。
