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

## 数值数组适配契约草案：M1，尚非公开 API

目标输入：数值数组、显式 shape、dtype 元信息及容差；可从 JSON 子树适配。建议夹具表达：

```json
{"shape":[2,2],"dtype":"float32","data":[0.1,0.2,0.3,0.4]}
```

data 按行优先排列。M1 需明确空形状是否表示标量、零长度维度与空数据是否合法、shape 元素范围及元素数溢出的处理；基准决策写入 M1 后再实现。dtype 是声明的源数据类型，Json 中的数值已转换为 Double；比较 dtype 不等于恢复原始张量存储或量化语义。

首版要求：shape 与元素数一致；双方 shape、dtype 按约定严格校验；整块 data 应用同一条明确容差；拒绝非数值/非有限值；保留错误坐标。建议报告总元素数、超差数量、最大绝对误差和限定数量的错误样本。限制展示条数不能改变总超差数或通过判定。

该草案不支持广播、隐式 reshape、自动转置或自动 dtype 转换。期望值和实际值的参数方向延续现有 API；若以后添加 PyTorch 模式，必须显式命名。PyTorch 的公式为 `|actual-expected| <= atol + rtol*|expected|`，与本库当前规则不同。[官方参考](https://docs.pytorch.org/docs/stable/testing)

## 场景数据契约草案：M3

- 世界模型一步预测：记录模型版本、固定 observation/action、初始 state、推断模式、随机噪声或确定性分支；比较预测向量和可选 reward/continue 输出。潜在维度、轴顺序和采样方式必须说明。
- RL：声明一种自己的规范化轨迹格式，而不声称存在统一的框架格式。每步建议含 episode_id、step、observation、action、reward、next_observation、terminated、truncated。写明 step 的含义和 observation 在动作前后的时序，跨 episode 不连续拼接。
- terminated 与 truncated 不合并成一个无说明的 done；不得未经环境定义就假设两者互斥。对原始框架字段的映射须显式记录。
- 可选 JSONL 中非有限数值处理必须明确；JSON 标准数值不能直接表示 NaN/Infinity，不采用静默转 null 的导出器。

参考数据元信息至少有：schema 版本、来源 URL/许可证、上游版本或提交、生成命令、输入/权重摘要、随机性条件和校验和。现有接口尚不读写这些文件；随 M2/M3 实现更新。
