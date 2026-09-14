# 开发阶段与正式提交

2026-09-14，用户完成 GitHub CLI 登录后，10 个原始开发阶段已形成正式提交。此前按真实完成顺序保存的树与验证摘要保持不变；正式提交全部采用创建时的真实时间，未回填为开发观察时间。

每次提交正文保留该阶段的观察时间及验证摘要。下面的 hash 是本地真实 commit ID；原始开发阶段提交在当前分支的完整历史中可检查，并非仅有 tree 快照。文档与交接后续更新另行提交，不影响这 10 个开发阶段。

| 阶段 | 提交 | 改动 | 当时的验证摘要 |
|---|---|---|---|
| 1 | `12278e7c604cf0ce672dfa69a5437d38d30dc480` | feat: establish path-aware JSON regression baseline | 28 tests passed on Wasm; earlier Native baseline passed |
| 2 | `c2382c3b9f2e7371d2d9d43b6bbbd71b3f07b990` | feat: validate and compare numeric tensors with JSON Pointer adapters | 41/41 tests on Wasm and Native |
| 3 | `bac6dca6f59d9743aa4a502c647c7462f6334d26` | feat: connect pinned MoonXi-net CPU linear layer through a validated adapter | 115 upstream CPU tests and 1 integration smoke test passed; pinned checkout clean |
| 4 | `7729988ca5e5f96c4f94269414f62a2654d80b8f` | test: verify real MoonXi outputs against independent Python references | 3 integration tests passed, including numeric, shape and dtype mutants; reference regeneration check passed |
| 5 | `339079adbc6d7723c444e909b268e1d15ab8c49a` | feat: demonstrate deterministic world-model inference using real MoonXi layers | 5 integration tests passed; showcase passed, latent mutation detected; Python references reproducible |
| 6 | `a5cb8b308cf3983f6ec56fce0ea5da1a744ee62d` | feat: validate RL trajectory timing, continuity and separate episode end flags | 4 trajectory contract tests passed on Wasm and Native; field-level mutation detection |
| 7 | `70d97598ecae2c772168bb90a511e7a1b5194822` | feat: demonstrate RL rollout regression with independent episode references | 49 library and scenario tests passed on Wasm; RL demonstration detects shifted action |
| 8 | `95e3903d58f997d55c350ef96052ff479ea0546a` | fix: reject trajectory step underflow and protect numeric compatibility boundaries | 53 tests passed on Wasm and Native; 196 scalar parity cases, sample-limit and immutable export checks; strict fixture source verification |
| 9 | `28fff4bd81d92f08c673823da7c2fe22f640cf5f` | ci: verify core, RL and pinned ML integration with a reproducible local runner | Full local runner passed: formatting, checks, build, 53 tests on each backend, 5 integration tests and examples; commit guard correctly reports zero actual commits |
| 10 | `ef405fc56259f14892ddb3e41fe246fd6956db10` | docs: deliver verified ML use cases, executable usage and proposal reference | 54/54 tests on Wasm and Native; 5/5 integration tests; 26 Markdown files and 67 local links valid; 7 YAML files parsed; local packaging inspected |


核验命令：

```sh
python3 scripts/check-commits.py
git log --oneline --reverse
```

本地数量检查排除空提交与合并提交。是否被活动主办方认可仍以实际审查为准；这里记录的是工程事实，不代表已经报名、验收或付款。发布时保留这些提交，不把完整开发历史压成单个提交。
