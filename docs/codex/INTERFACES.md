# 接口与数值契约

## 已实现 API

实际签名以 [pkg.generated.mbti](../../pkg.generated.mbti) 为准：

- `compare(expected, actual, rules?) -> Array[Difference] raise InvalidRule`
- `assert_matches(expected, actual, rules?) -> Unit raise`
- `format_differences(items) -> String`
- `Rules::new(ignore_paths?, tolerances?)`

`Tolerance` 含 `path`、`absolute`、`relative`。`Difference` 含 `path`、`reason`、`expected: Json?`、`actual: Json?`；None 表示缺失，Some(Null) 表示 null。当前原因有 ValueMismatch、TypeMismatch、Missing、Unexpected、OutsideTolerance、UnsupportedNumber、DepthLimit。

已公开语义：对象不受键插入顺序影响；数组按原下标比较；路径使用 JSON Pointer 字符串语法，`~0`/`~1` 转义；空路径指根。忽略优先于比较，不存在的规则路径不报错。无通配符，无自动数组重排。

对两个支持的数值 a、b，容差条件是 `|a-b| <= absolute` 或 `|a-b| / max(|a|,|b|) <= relative`，两个零相等。容差须有限非负，重复数值路径报错。无容差路径按 Double 相等比较。

当前拒绝非有限值及 `abs(value) >= 2^53`。这是一项保守限制，会同时拒绝部分本可容差比较的大幅度浮点值。ML 扩展首轮沿用并记录这一限制；若真实用例要求扩大支持范围，另行设计区分整数精度风险与浮点溢出的策略并补测试，不静默删除保护。

报告按编码路径的 UTF-16 字典序排列；深度超过 128 产生差异。完整规则与上游下溢限制见 [README](../../README.mbt.md)。

## 数值数组 API（M1 已实现）

公开接口见 [numeric/pkg.generated.mbti](../../numeric/pkg.generated.mbti)。`Tensor::new(shape, dtype, data)` 复制并校验输入；访问 shape/data 也返回副本。`Tensor::from_json(document, pointer?)` 读取精确 JSON Pointer 下的 `{shape, dtype, data}`，`to_json()` 返回这一格式。额外元信息字段允许存在；不做字符串/数字、嵌套数组或 dtype 的隐式转换。

shape 为非负 Int 维度；空 shape 是一个标量，任一零轴表示空 data，其余情况乘积须不超过 2147483647。dtype 是非空、区分大小写的源类型标签，严格比较；不声称验证或恢复原始二进制表示。data 按行优先展开，拒绝非有限值及绝对值大于等于 2^53。JSON 保留的非零下溢字面量也拒绝；已被解析器丢弃的信息无法恢复。

`numeric.compare(expected, actual, absolute?=0, relative?=0, max_samples?=8)` 使用与核心相同的对称绝对或相对规则，返回 `ShapeMismatch`、`DtypeMismatch` 或 `Values(Summary)`。形状优先于 dtype；结构不同时不比较重叠前缀。无效输入抛 `InvalidInput`，无效规则抛 `InvalidRule`，断言失败抛 `Mismatch`。

Summary 含 total、mismatched、所有元素的 max_absolute_error 和有上限的错误样本；每条样本包含原下标、行优先坐标、期望/实际值和绝对误差。`max_samples=0` 仍完整计数并正确失败。`Outcome::is_match()` 和 `format()` 可用于 CI 断言和报告。

不支持广播、隐式 reshape、自动转置或 dtype 转换。公式不是 PyTorch 的绝对加相对阈值。[PyTorch 官方参考](https://docs.pytorch.org/docs/stable/testing)

## 轨迹接口（M3 已实现）

`trajectory.validate(document)` 检查规范化步骤数组，`compare(expected, actual, absolute?, relative?, max_samples?)` 返回 metadata 差异和带原行路径的 tensor 差异；`assert_matches` 在有差异时抛 Mismatch。格式错误为 InvalidTrajectory，张量/数值输入错误沿用 numeric.InvalidInput；规则错误沿用 numeric.InvalidRule。

每步必须有 episode_id、step、observation、action、reward、next_observation、terminated、truncated，未知字段拒绝。三个观测/动作字段使用 numeric 的 Tensor JSON；reward 为支持的有限标量。元信息严格比较，只有 reward 应用明确容差。相邻同 episode 步号连续且 next_observation 与后一步 observation 严格匹配，不能靠放大回归容差跳过这一输入契约。

允许空数组、最后 episode 的前缀，以及同时 terminated/truncated；不接受非零步号开头片段、重复 episode id 或无结束标志的跨 episode 拼接。详细时序和边界见 [RL 场景](../RL_TRAJECTORY.md)。

世界模型固定 state/observation/action、权重、输入拼接及轴顺序，直接调用 MoonXi 的两层 Linear 与 ReLU。数值推断以独立 Python 算式为参考，详见 [世界模型场景](../WORLD_MODEL.md)。所有参考的生成命令与 JSON 校验和见 [manifest](../../fixtures/manifest.json)，上游提交与许可证见 [upstream](../../integrations/moonxi/upstream.json)。
