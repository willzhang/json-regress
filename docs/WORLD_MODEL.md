# 一步世界模型输出回归展示

执行 `bash scripts/moon-local.sh -C integrations/moonxi run cmd/showcases --target native`。

这个**未训练的小型动力学模型**使用真实 MoonXi-net CPU `Linear → ReLU → Linear`。固定初始 latent state `[0.5, -0.25]`、observation `[0.75]`、action `[-1]`，按 `[state, observation, action]` 拼接，输出形状 `[batch=1, latent=2]`。模型没有随机采样或训练模式变化。固定权重、轴顺序和输入见 [参考数据](../fixtures/world_model.json)。

独立期望值由 Python 标量循环按矩阵乘法定义生成，未调用 MoonXi-net 或本库。参考以 Double 算术计算；被测后端是 Float，绝对容差 `1e-6` 用于这一小算例的舍入差异。不会把这个阈值宣称为其他模型的通用默认值。

正例实际执行前向计算并校验两个 latent 值。负例改变一个 latent 值、交换 batch/latent 形状或提供 NaN，分别产生坐标差异、结构失败或无效输入错误。该展示证明固定推断输出的回归检查链路；没有验证世界模型的学习能力、长时预测、Dreamer 实现或真实任务收益。

参考生成与校验：`python3 scripts/generate-references.py --check`。上游版本与许可证见 [集成记录](../integrations/moonxi/upstream.json)。
