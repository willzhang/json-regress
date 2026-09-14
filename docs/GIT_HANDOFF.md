# Git 身份与提交交接

用户要求至少 10 个有实际开发价值的提交。本机尚未配置 Git 姓名/邮箱；用户要求稍后提供查询命令，故没有替用户编造身份。独立仓库已建在本项目，分支 `codex/ml-regression`，当前正式提交数 **0**。

开发过程中按验证完成的顺序实时保存 tree 快照：`.git/local-milestones.json` 记录树、阶段说明、验证摘要和观察时间，`refs/local-milestones/01` 等本地引用保护这些树。它们不包含署名，**不是 commit，也不能计入赛事提交数量**；不会随普通分支推送到 GitHub。不能回填观察时间作为提交时间。

10 个阶段分别为：JSON 原型基线；完整 numeric API；锁定 MoonXi CPU 薄适配器；独立数值参考；真实层的一步世界模型展示；轨迹校验库；双 episode 的 RL 展示；边界缺陷与兼容性修复；统一验证与 CI；文档、用法测试和申报参考。

## 查询身份

本机已经安装 GitHub CLI。已登录时执行：

```sh
gh api user --jq '{login: .login, name: (.name // .login), public_email: .email, id: .id, created_at: .created_at}'
```

若提示未登录，先 `gh auth login`，在自己的浏览器完成 GitHub 登录，不发送令牌。

推荐从 [GitHub 邮箱设置](https://github.com/settings/emails) 复制其显示的 noreply 邮箱，避免在公开提交里使用私人邮箱。2017-07-18 之后注册的账户通常使用 `ID+USERNAME@users.noreply.github.com`；旧账户取决于设置，以页面显示为准。[官方说明](https://docs.github.com/en/account-and-profile/reference/email-addresses-reference)

选择姓名和邮箱后，仅配置本仓库（替换下面占位文字）：

```sh
git config --local user.name "你选择的署名"
git config --local user.email "GitHub 显示的 noreply 邮箱"
```

## 接续代理操作

用户确认身份后，检查上述快照及当前工作树，按记录顺序把每个阶段生成有父子关系的正式提交；使用实际提交时间，不造回溯日期、不覆盖后来的修改。树与验证摘要可用来核验每个阶段的实质内容；不能凭此声称历史远程 CI 已运行。更新本页和 CURRENT_STATUS 的提交状态，然后执行：

```sh
python3 scripts/check-commits.py
git log --oneline --reverse
```

检查脚本排除空提交和合并提交；阶段的实际开发价值仍需审阅。当前没有 remote，没有推送授权；注册、公开发布、Mooncakes 命名和远程 CI 是独立后续步骤。
