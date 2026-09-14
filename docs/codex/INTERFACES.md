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

## 场景数据契约草案：M3

- 世界模型一步预测：记录模型版本、固定 observation/action、初始 state、推断模式、随机噪声或确定性分支；比较预测向量和可选 reward/continue 输出。潜在维度、轴顺序和采样方式必须说明。
- RL：声明一种自己的规范化轨迹格式，而不声称存在统一的框架格式。每步建议含 episode_id、step、observation、action、reward、next_observation、terminated、truncated。写明 step 的含义和 observation 在动作前后的时序，跨 episode 不连续拼接。
- terminated 与 truncated 不合并成一个无说明的 done；不得未经环境定义就假设两者互斥。对原始框架字段的映射须显式记录。
- 可选 JSONL 中非有限数值处理必须明确；JSON 标准数值不能直接表示 NaN/Infinity，不采用静默转 null 的导出器。

参考数据元信息至少有：schema 版本、来源 URL/许可证、上游版本或提交、生成命令、输入/权重摘要、随机性条件和校验和。现有接口尚不读写这些文件；随 M2/M3 实现更新。
