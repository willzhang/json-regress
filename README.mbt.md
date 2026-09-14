# json-regress（本地原型）

面向 MoonBit 测试的 JSON 回归断言库：对明确路径忽略易变字段，对指定数值设置容差，同时保留其他业务字段的严格比较和可定位的失败报告。

当前模块名 `local/json_regress` 是本地占位名称，尚未上传 GitHub 或发布到 Mooncakes。使用现有 `Json` 类型，无第三方运行时依赖。

## 快速运行

在本项目目录执行（先安装官方工具链）：

```sh
bash scripts/moon-local.sh test
bash scripts/moon-local.sh run cmd/main
```

示例程序包含接口响应、实验指标、生成配置三个场景，每个场景都检查一个应通过的结果和一个应失败的结果。示例断言不符合预期时，进程会以非零状态退出。

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

## 当前范围与待办

已实现路径忽略、逐路径容差、结构化报告、断言接口、边界测试和三个可运行示例。尚未验证真实下游项目集成或大规模性能。暂无快照文件管理、自动更新快照、JSON Patch、JSON Schema、无序数组匹配、CLI 文件对比和可视化界面。

`.github/workflows/check.yml` 配置检查、构建、测试和示例运行；尚未上传仓库，GitHub Actions 未实际运行。发布前需要确定 Mooncakes 用户名、替换模块占位名和仓库地址、进行外部项目试用，并补齐真实开发提交记录。

原创实现，未移植同类库源码；工具链模板和标准库来自 MoonBit。当前项目采用模板附带的 Apache-2.0 许可证，见 [LICENSE](LICENSE)。实现与文档由 AI 辅助生成，需由维护者理解、审阅后再作为自己的项目发布。

## 项目协作与下一阶段

用户已确定下一步增加数值数组适配、接入一个真实 MoonBit 机器学习项目，并以世界模型一步预测和强化学习短轨迹作为两个展示场景。这些扩展目前处于规划阶段；上文测试结果只覆盖现有 JSON 原型。

从 [协作文件入口](docs/codex/README.md) 进入，优先阅读 [当前状态](docs/codex/CURRENT_STATUS.md) 与 [路线图](docs/codex/ROADMAP.md)。项目规则见 [AGENTS.md](AGENTS.md)，项目 skill 位于 [.agents/skills/json-regress-engineering](.agents/skills/json-regress-engineering/SKILL.md)。
