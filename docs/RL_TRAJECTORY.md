# 强化学习轨迹回归展示

执行 `bash scripts/moon-local.sh run cmd/rl`，无需下载 ML 框架。这个项目自建的确定性小环境实际运行两段轨迹；不是 Gymnasium 接入或完整 RL 训练。独立 Python 算式生成 [参考轨迹](../fixtures/rl.json)，没有把被测 MoonBit 输出复制成期望值。

环境定义：从位置 0 出发，`next_position = position + action`，奖励是 `-abs(3-next_position)`，位置达到 3 时 terminated。第一段 `goal` 动作为 `[1,2]`、时间上限 4；第二段 `time` 动作为 `[-1,1]`、时间上限 2。时间达到上限时 truncated。规则允许两个条件同时成立。

`trajectory` 包的自有规范化格式为：episode_id、step、observation、action、reward、next_observation、terminated、truncated。step 从 0 起；observation 是动作前观测，reward 和 next_observation 属于执行该 action 后的转移。三个数组字段使用 numeric 的显式 shape/dtype/data 格式，reward 是有限标量。

校验要求步号连续、同 episode 内前一步 next_observation 与当前 observation 严格一致；结束后必须使用新 episode_id 并从 0 开始；跨 episode 之前必须有至少一个结束标志。最后一段允许只是 rollout 前缀；当前不接受从非零 step 开始的任意片段。空轨迹有效，但与非空轨迹不同。未知步字段会拒绝，新增元信息应显式扩展格式。

比较 metadata 时，只有 reward 使用调用者明确提供的容差，其余字段严格比较。三个 tensor 字段共用数值数组规则。报告保留 `/行号/字段` 与 tensor 内坐标。缺失 `truncated`、合并为无说明的 `done`、错误 reset、时间错位、奖励符号及终止类型改变均有负例。

`terminated` 与 `truncated` 的区分参考 [Gymnasium 官方说明](https://gymnasium.farama.org/tutorials/gymnasium_basics/handling_time_limits/)。本包没有把二者合并，也不据短轨迹或单次奖励判断算法收益。


## M5：文件诊断与比较重放

`bash scripts/moon-local.sh run cmd/export_rl --target native` 或 `--target wasm` 实际运行上述环境并输出 JSON 轨迹。使用 examples/files/trajectory.rules.json 可由 Native CLI 直接比较用户文件。

报告增加 row、episode_id、step、field，按数字行号选择首条诊断，保留 reward 与张量错误详情。输入连续性与结束标志校验仍由 trajectory 执行；无效时间步退出 2，有效轨迹中的回归退出 1。奖励修改与时间错位的失败包已验证可独立重放；重放只重新比较捕获的轨迹，不重新执行环境。见 [文件接口](FILE_COMPARISON.md)。
