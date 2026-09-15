# Git 身份与提交交接

2026-09-14 已核验 GitHub CLI 登录账号 `willzhang`，本项目配置了该账号公开署名 `will zhang` 与 `220442040+willzhang@users.noreply.github.com`。配置只对本仓库生效；登录令牌保留在系统凭据管理中，没有显示、导出或写入项目。

项目根为独立仓库，分支 `codex/ml-regression`。**10 个实质开发阶段已经形成正式提交**，数量检查通过；另有状态说明更新提交，当前总数请运行检查脚本。完整记录见 [开发历史](DEVELOPMENT_HISTORY.md)。

## 历史形成方式

开发过程中按验证完成的顺序实时保存 tree 快照；身份确认后逐一生成有父子关系的 commit，形成时每个 commit 的树均与原阶段树完全一致。后续发布清理更新了历史文档、忽略规则和工具链入口，保留了库代码、阶段顺序与署名时间；阶段表使用当前可达提交。正式提交使用真实创建时间，原始观察时间与验证摘要写在说明中，未回填日期、重新拆分代码或添加空提交。

本地 `.git/local-milestones.json`、`refs/local-milestones/01` 等引用保留原始树；`.git/materialized-milestones.json` 记录树到正式提交的映射。它们是本地辅助记录，阶段内容现已由当前分支的正式提交保存；将来正常推送分支即可携带提交历史。

## 接续

```sh
python3 scripts/check-commits.py
git log --oneline --reverse
gh auth status --hostname github.com
```

检查脚本排除空提交和合并提交，实际开发价值需审阅。保护现有历史，后续按内聚改动及时提交，不通过 squash 丢失这些阶段。

以上历史形成说明对应 2026-09-14。后续 M5 已将全库扩展到 Wasm/Native 各 67 项、真实集成各 6 项；当前结果见 CURRENT_STATUS 与 VALIDATION。

2026-09-15 用户明确授权公开发布。origin 已设置为 https://github.com/willzhang/json-regress.git，默认分支已推送；[首次远程 CI](https://github.com/willzhang/json-regress/actions/runs/34912598554) 通过。Mooncakes `willzhang/json_regress@0.1.0` 已发布，来源提交 `dde5140` 的远程 CI 与独立安装验证通过；报名尚未提交。详见 [发布交接](PUBLICATION.md)。
