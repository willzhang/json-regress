# 同类项目核验与增量建议

调研：2026-09-14 至 2026-09-15。基线：本仓库 `16f44a0`。本文件保留当时的选题评估。后续用户确认实施 A/B，两项已完成；当前结果见 [文件接口](FILE_COMPARISON.md) 与 [验证记录](codex/VALIDATION.md)。下文“未实现”“候选”描述的是评估时的基线。

## 当前判断

**M0–M3 已完成约定的本地范围；M4 尚未完成。** 本地材料和至少 10 个实质开发提交已经具备，但公开仓库、远程 CI、Mooncakes 包名及发布、正式申报和验收仍待办。现有 Wasm / Native 各 54 项测试和 5 项 Native 集成测试，是之前的实测记录；本轮只做源码与资料核验，没有重新执行模型或对方仓库。

当前项目已经具备继续交付的工程基础。官方更看重可用性、测试、文档和清晰范围，增加模型名称或代码规模不能直接换来奖励。公开页面显示本期报名与验收截止为 9 月 24 日，具体执行口径仍以正式通知为准。[官方说明](https://github.com/moonbitlang/Hackathon2026/blob/main/src/App.tsx)

建议保留「MoonBit 数值与机器学习输出回归验证」定位。先完成 M4；若继续投入，只增加一条能够从用户文件运行、定位失败并复现比较结果的流程。不要把已完成的一步未训练动力学示例描述为完整世界模型，也不要把自建确定性环境描述为真实 RL 算法接入。

## 核验方法与参赛身份

读取了下列 7 个公开 GitHub 仓库的 README、接口或相关实现，并检查所选提交对应的 Actions 记录。固定提交见文末，结论只覆盖阅读到的范围。

- moon-diff 含项目申报书；MoonRewardForge 含 OSC2026 自检材料；moonbit-pathfinding 的工作流包含面向 OSC2026 的项目描述。这些是作者公开准备参赛的证据。
- 未获得能逐一确认它们已报名**九月 Hackathon2026**、通过验收或获奖的官方名单。OSC2026 与九月活动不能仅凭年份相同就视为同一届。
- 其余项目作为功能或工程参考，未确认参赛。官方 QuickCheck 是生态基础设施。
- 不以星数、README 中的“唯一”“生产级”、测试总数或一个绿色 CI 图标推定竞争排名。未在本地复跑对方项目，CI 结果只代表对应工作流报告的状态。

## 最相关的对照

| 项目及证据 | 已确认的能力 | 对本项目的启发与边界 |
|---|---|---|
| [moon-diff](https://github.com/yuzhiblue/moon-diff/tree/07b97fdc6dac684f93cae40d86f4ce23540002b2)，含申报书 | 文本 diff/patch、语义 JSON Patch、CLI；源码 `json_diff` 接收两个 Json 与路径前缀 | 通用“JSON 结构比较”已有重叠。所读接口没有我们的张量 shape/dtype 与容差规则。应强调 ML 诊断，避免扩成另一套文本 diff。README 的文件系统 IO 仍列待办，不能把有 CLI 等同于完整文件工具。 |
| [moonbit-jsonpatch](https://github.com/Xu107-hhh/moonbit-jsonpatch/tree/be869e385f26e63098b6960c8d522080606ab87d)，参赛未核实 | JSON Patch、Merge Patch、Pointer、语义 diff、CLI；包含社区 JSON Patch 测试集 | 可借鉴公开样例、标准语义验证和低门槛入口。Patch 是变换文档；我们的核心是判断受控数值误差是否可接受。其 README 的测试通过数量未在本机复验，社区套件也不是官方认证。 |
| [MoonRewardForge](https://github.com/weidekais/MoonRewardForge/tree/52eae47f44b7dde7c1d5f126d25d6fb0e1e6f6f2)，含 OSC2026 自检 | 奖励项加权、归一化、裁剪、轨迹汇总、质量告警和确定性场景矩阵 | 它回答奖励信号怎样构成、是否异常；我们回答两次实现的观测、动作、奖励和结束标志是否一致。可借鉴稳定诊断类别与成组负例，不需要重做奖励设计库。 |
| [MbTorch](https://github.com/c-tomioka/mbtorch/tree/093238d66aec9b105c87d7e8b9bc0f846859a708)，参赛未核实 | 现有示例把 PyTorch 模型导出为 ONNX、safetensors 与参考 JSON，再与 MoonBit MLP 输出按元素比较 | **“Python/PyTorch 对照 MoonBit 推理”本身已经存在。** 其所读示例采用固定绝对误差并打印 OK/NG。我们的增量应是可复用规则、稳定报告、跨层定位与 CI 接入；第二个框架适配只有真实使用价值，不应单独包装成创新。 |
| [quint-connect-moonbit](https://github.com/mizchi/quint-connect-moonbit/tree/a8e24e3ed972c40e453dcba6dcb8fa8c025a3bfc)，参赛未核实 | 将 Quint 轨迹映射给 MoonBit driver，逐步比较投影状态，记录种子并区分解析、驱动与状态偏离错误 | 确定性重放和首个状态偏离已经有实现。我们可进一步围绕张量坐标、数值容差及模型检查点组织诊断；不要宣称发明了轨迹重放。其 README 明确尚无 trace shrinking。 |

另外阅读了 [moonbit-pathfinding 的 CI](https://github.com/Suquster/moonbit-pathfinding/blob/1d56d10e34b7fb5adeff183487b0d6a8bd035583/.github/workflows/ci.yml)：有四后端矩阵及 WASI 产物检查安排。值得借鉴的是同一输入跨后端的实际输出验证，而非复制其大量功能。我们现有两个后端都通过测试，并不等于已经把同一 ML 模型的跨后端输出拿来互相比较。

[官方 QuickCheck](https://github.com/moonbitlang/quickcheck/tree/d7a561aa615674d3afc322be9eaa47cd0dd5e212) 提供性质测试参考。若采用，应先做小范围工具链兼容验证；不能为了测试数量引入额外维护负担。

## 当前优势与缺口

现有优势是已经组合了精确 JSON 路径、数值容差、张量 shape/dtype、错误坐标、轨迹时间约束、真实 MoonXi CPU 接入和独立参考计算。功能定位比“通用 JSON diff”更具体，且核心不依赖训练或 GPU。

目前最影响实际使用的缺口有三处：

1. 用户还不能直接给一个命令传入自己的基线、候选和规则文件；现有命令运行内置示例。
2. 结果是 MoonBit 类型和文本，没有稳定版本的机器可读报告与统一退出码。
3. 世界模型只有一步固定示例，缺少把多层、多时间步输出组织起来、指出首次观察到偏离的位置并复现比较的通用机制。

因此，优先补“可使用、可定位、可复现”。本轮有限检索没有证明这套组合在所有生态中独有，不应使用“首创”“唯一”的宣传。

## 推荐扩展 A：文件入口与稳定报告

目标：让不了解库内部 API 的开发者也能把它用于 CI。这主要提高工程可用性。

- 输入：基线 JSON、候选 JSON、显式规则 JSON；第一版不增加 JSONL、大文件流处理、网页管理后台。
- 输出：文本摘要及带 `schema_version` 的 JSON 报告，含比较状态、路径/坐标、shape/dtype、误差、规则和有界样本。
- 退出码候选：`0` 一致、`1` 有差异、`2` 输入/规则/运行错误。格式或来源错误不能伪装成普通数值不一致。
- 核心比较保持纯 MoonBit；读写文件放在 Native 命令边界。不得自动覆盖基线，也不得自行放宽阈值。
- 最小验收：从临时工作目录读取外部文件，分别验证正常、数值超限、shape 错误、无效规则、畸形 JSON 的输出与退出码；同一输入产生稳定报告。负例必须真的让 CI 失败。

## 推荐扩展 B：按层、按时间步定位的 ML 比较包

目标：回答“模型移植或后端变化后，从哪个检查点开始不一致”。这是比增加展示名称更有价值的领域适配。

输入候选为带版本的输出包：模型标识、输入/权重摘要、生成器版本、后端、dtype、随机条件，以及具有明确顺序和唯一标识的检查点。检查点包含层名或 episode/step、张量 shape/dtype/data。调用方显式声明哪些元数据必须相同、哪些是本次比较变量，例如后端；不能要求所有元数据相同而阻止跨后端比较。

最小实现只复用现有 MoonXi 小模型与 RL 场景：

- 世界模型记录 Linear、ReLU、输出层，并将固定动力学展开为少量时间步。仍是未训练的 CPU 教学模型。
- RL 沿用现有轨迹契约，报告首次观察到不一致的 episode、step、字段与张量坐标；不放宽从 step 0 开始、连续观测及结束标志约束。
- 区分缺少检查点、来源不可比较、shape/dtype 差异和数值偏差；有序数组的核心语义不变。
- 失败时导出两个输入、规则及来源清单，使另一个环境能**重现同一次比较**。只有实际执行了锁定版本的模型/环境生成器，才能另称“重新运行模型/环境”；复制结果文件不算执行模型。
- 优先验证同一轻量算例在 Native 与 Wasm 上的实际输出；先做 MoonXi 后端支持探测。若实际模型无法在两个后端执行，如实记录限制，只保留已验证链路，不把夹具重放称为跨后端模型运行。
- 保留独立 Python 参考，避免两个后端共享同一个错误也被判正确。

最小验收：正确结果通过；人为注入一个中间层误差、一次时间错位、一个同 shape 的布局错误及一个来源不匹配，各自得到预期类别与位置；仅用导出文件即可在独立进程重现比较结论。所谓“首次偏离”只限已记录的检查点，不能据此自动断言根因，也不承诺自动找到最小反例。

## 后续技术边界

可以保留为后续方向的有：变长/填充序列 mask、显式的 PyTorch 容差模式、基于具体模型约束的不变量检查。它们会增加新的数值和数据语义，应由真实输入需求驱动。默认对称“绝对或相对”公式不改，也不根据误差结果自动选一个能通过的容差。

本轮不建议完整世界模型训练、RL 算法库、GPU 后端、训练收益排名、自动阈值学习或大型可视化平台。

建议申报定位（仅方向草案）：**面向 MoonBit 模型迁移与多后端开发的数值回归工具；在张量、模型检查点和 RL 轨迹层面判断允许误差，定位偏离并复现比较结果。** 当前申报只能写已经实现的部分，A/B 实现并验证后再更新正式功能描述。

## 固定证据与 Actions 状态

以下结果是查询时的工作流状态，没有下载并逐项复核日志，也不保证兼容今天的工具链。无结果不等于没有测试；失败也不能直接归因于库实现。

| 仓库 | 查阅提交 | 对应工作流状态 |
|---|---|---|
| moon-diff | `07b97fdc6dac684f93cae40d86f4ce23540002b2` | [CI success](https://github.com/yuzhiblue/moon-diff/actions/runs/32921810875) |
| moonbit-jsonpatch | `be869e385f26e63098b6960c8d522080606ab87d` | [CI success](https://github.com/Xu107-hhh/moonbit-jsonpatch/actions/runs/34826920390) |
| MoonRewardForge | `52eae47f44b7dde7c1d5f126d25d6fb0e1e6f6f2` | [Moon CI success](https://github.com/weidekais/MoonRewardForge/actions/runs/31890955385) |
| MbTorch | `093238d66aec9b105c87d7e8b9bc0f846859a708` | [CI success](https://github.com/c-tomioka/mbtorch/actions/runs/27458062127) |
| quint-connect-moonbit | `a8e24e3ed972c40e453dcba6dcb8fa8c025a3bfc` | 查询该提交未返回 Actions runs；未据此否定其 README 的本地验证记录 |
| moonbit-pathfinding | `1d56d10e34b7fb5adeff183487b0d6a8bd035583` | [ci success](https://github.com/Suquster/moonbit-pathfinding/actions/runs/29339658982) |
| quickcheck | `d7a561aa615674d3afc322be9eaa47cd0dd5e212` | [2026-09-08 check failure](https://github.com/moonbitlang/quickcheck/actions/runs/34214139863)，未调查原因 |

关键实现与参赛材料：

- [moon-diff 申报书](https://github.com/yuzhiblue/moon-diff/blob/07b97fdc6dac684f93cae40d86f4ce23540002b2/docs/%E7%94%B3%E6%8A%A5%E4%B9%A6-moon-diff.md)；[JSON diff 实现](https://github.com/yuzhiblue/moon-diff/blob/07b97fdc6dac684f93cae40d86f4ce23540002b2/src/diff/semantic.mbt)。
- [moonbit-jsonpatch diff 实现](https://github.com/Xu107-hhh/moonbit-jsonpatch/blob/be869e385f26e63098b6960c8d522080606ab87d/diff.mbt)；[社区测试夹具来源](https://github.com/Xu107-hhh/moonbit-jsonpatch/blob/be869e385f26e63098b6960c8d522080606ab87d/suite/fixtures/README.md)。
- [MoonRewardForge OSC2026 自检](https://github.com/weidekais/MoonRewardForge/blob/52eae47f44b7dde7c1d5f126d25d6fb0e1e6f6f2/docs/OSC2026_CHECKLIST.md)；[公开 API](https://github.com/weidekais/MoonRewardForge/blob/52eae47f44b7dde7c1d5f126d25d6fb0e1e6f6f2/pkg.generated.mbti)。
- [MbTorch 对照示例实现](https://github.com/c-tomioka/mbtorch/blob/093238d66aec9b105c87d7e8b9bc0f846859a708/examples/import_mlp/main.mbt)；[PyTorch 导出脚本](https://github.com/c-tomioka/mbtorch/blob/093238d66aec9b105c87d7e8b9bc0f846859a708/examples/import_mlp/export_from_pytorch.py)。
- [Quint 轨迹适配与比较实现](https://github.com/mizchi/quint-connect-moonbit/blob/a8e24e3ed972c40e453dcba6dcb8fa8c025a3bfc/adapter.mbt)。

公开源码阅读缓存存于被 Git 忽略的 `artifacts/competitor-review-20260914/`。本文件保留固定来源链接，缓存不作为发行包的一部分。
