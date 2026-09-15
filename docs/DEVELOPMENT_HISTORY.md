# 开发阶段与正式提交

2026-09-14，用户完成 GitHub CLI 登录后，10 个原始开发阶段已形成正式提交。此前按真实完成顺序保存了开发阶段与验证摘要；正式提交全部采用创建时的真实时间，未回填为开发观察时间。

每次提交正文保留该阶段的观察时间及验证摘要。下面的 hash 是本地真实 commit ID；原始开发阶段提交在当前分支的完整历史中可检查，并非仅有 tree 快照。文档与交接后续更新另行提交，不影响这 10 个开发阶段。2026-09-15 对历史文档和工具链入口作发布清理，保留全部阶段、父子顺序、作者、提交时间及提交说明；库实现和测试源码逐提交核对未变。表中使用清理后的提交 ID。

| 阶段 | 提交 | 改动 | 当时的验证摘要 |
|---|---|---|---|
| 1 | `6eb744abffc0512c75f82b3427dd4f54b5541a70` | feat: establish path-aware JSON regression baseline | 28 tests passed on Wasm; earlier Native baseline passed |
| 2 | `7829f483498ef69d83855f1636376184ecddd928` | feat: validate and compare numeric tensors with JSON Pointer adapters | 41/41 tests on Wasm and Native |
| 3 | `201bd758c0b71d7498bcb97620026dd3311ff385` | feat: connect pinned MoonXi-net CPU linear layer through a validated adapter | 115 upstream CPU tests and 1 integration smoke test passed; pinned checkout clean |
| 4 | `0778ff4391b1c46e847bcf526791de977bf19704` | test: verify real MoonXi outputs against independent Python references | 3 integration tests passed, including numeric, shape and dtype mutants; reference regeneration check passed |
| 5 | `025f473bf298d56dada28e86e9eecfe74607b148` | feat: demonstrate deterministic world-model inference using real MoonXi layers | 5 integration tests passed; showcase passed, latent mutation detected; Python references reproducible |
| 6 | `92149ff9d87cf0b3dd37aa82dd08d7ba7104a17d` | feat: validate RL trajectory timing, continuity and separate episode end flags | 4 trajectory contract tests passed on Wasm and Native; field-level mutation detection |
| 7 | `37413c3b05731629a6b56b24250c1a2a357b95c7` | feat: demonstrate RL rollout regression with independent episode references | 49 library and scenario tests passed on Wasm; RL demonstration detects shifted action |
| 8 | `3f7c9395ac603d0f097bfded0eac2722e621be3b` | fix: reject trajectory step underflow and protect numeric compatibility boundaries | 53 tests passed on Wasm and Native; 196 scalar parity cases, sample-limit and immutable export checks; strict fixture source verification |
| 9 | `a4782b2176fde402c7576abd9e11b989b6ed7116` | ci: verify core, RL and pinned ML integration with a reproducible local runner | Full local runner passed: formatting, checks, build, 53 tests on each backend, 5 integration tests and examples; commit guard correctly reports zero actual commits |
| 10 | `850ffc8dd9c0523aecfdccd6f2491c2284910624` | docs: deliver verified ML use cases, executable usage and proposal reference | 54/54 tests on Wasm and Native; 5/5 integration tests; 26 Markdown files and 67 local links valid; 7 YAML files parsed; local packaging inspected |


核验命令：

```sh
python3 scripts/check-commits.py
git log --oneline --reverse
```

本地数量检查排除空提交与合并提交。是否被活动主办方认可仍以实际审查为准；这里记录的是工程事实，不代表已经报名、验收或付款。发布时保留这些提交，不把完整开发历史压成单个提交。

## 2026-09-15：用户确认的 M5 增量

- `2a31119`：公开同类项目核验与两项增量建议，保留固定来源，未把计划写成已完成。
- `975d4c2`：文件比较、版本化报告、检查点诊断与可携带比较重放；13 项 checking 测试在双后端通过，19 项 Native CLI 进程验收通过。
- `37b7fd7`：真实三步模型与 RL 双后端导出、独立参考、实际输出比较和注错重放；6 个实际输出对照与 7 个负例通过。

后续交付文档提交记录上述实现、协议和验证边界。当前总数由检查脚本计算；原始 10 个开发阶段保留，没有压缩历史或空提交。
