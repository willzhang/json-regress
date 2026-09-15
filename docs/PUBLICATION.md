# 公开发布与报名交接

更新：2026-09-15。用户已明确授权公开发布代码和软件包。

## 已完成

- 公开仓库：[willzhang/json-regress](https://github.com/willzhang/json-regress)。默认分支 `codex/ml-regression`，保留原始 10 个开发阶段及后续实质改动，未 squash。
- 首次推送提交：`3620117dd3f03f95cc0f346d1f547dcab8984dfd`。
- 首次远程验证：[GitHub Actions 34912598554](https://github.com/willzhang/json-regress/actions/runs/34912598554)，conclusion 为 success。该流程调用与本地相同的 `scripts/check-local.sh --integration`。
- README、许可证、源码、测试、可运行示例及申报参考已公开。Git 历史的凭据特征检查未发现令牌、私钥或非 noreply 邮箱；本地凭据、构建缓存、第三方源码缓存与运行产物没有推送。

## Mooncakes 发布准备

2026-09-15，`moon whoami` 已确认 `Logged in as willzhang`。主模块统一为 `willzhang/json_regress@0.1.0`，内部导入和独立模块依赖同步更新。CLI 与 MoonXi 集成继续是源码仓库中的本地模块，不单独发布。

本轮问题：将本地占位包转为可从注册表安装的正式依赖。基线为已公开且 CI 通过的代码；行为与容差保持不变。输入是已确认的 namespace 与完整 Git 提交；输出是发布包和独立消费验证。先运行现有全量验证，再从提交导出干净目录打包，避免把正在编辑的申报稿带入发布。发布后在仓库外添加 `willzhang/json_regress@0.1.0`，验证根库与 checking/numeric/trajectory 导入，以及应通过和应失败的比较。无需新增训练或付费资源。

当前状态：namespace 已确认；包上传和独立消费仍待执行。官方包管理说明：[账号与发布](https://docs.moonbitlang.com/en/latest/toolchain/moon/package-manage-tour.html)。

## 报名顺序

根据 2026-09-15 读取的[官方首页源码](https://github.com/moonbitlang/Hackathon2026/blob/main/src/App.tsx)，报名需参赛信息、公开仓库和一页项目说明；随后进行资格审核、公开持续开发与验收。因此应先有可访问的公开仓库，再提交报名。当前公开说明没有把 Mooncakes 发包列为报名的前置条件，也不要求先完成所有功能再报名。

1. 填入上面的公开仓库地址；目前这一步已经具备。
2. 理解并修改 [申报参考稿](PROPOSAL_REFERENCE.md)，以本人表述整理一页说明。
3. 通过[官网](https://moonbitlang.github.io/Hackathon2026/)或其明确链接的[飞书报名表](https://bxup9uklfcb.feishu.cn/share/base/form/shrcnWUMlgpbwHaXgzV7HmNhNhg)提交资料。
4. 按官方入口加入赛事交流群，继续保留实质开发和修复记录，并按审核反馈准备验收。

官网写明本期 9 月 24 日验收并截止报名，最终执行口径以[赛事章程](https://bxup9uklfcb.feishu.cn/wiki/Dx4Bwd6D1i3GfHkajQCcF7SznEd)和官方通知为准。本轮核验了官网实际指向的链接；没有代填报名表、提交个人资料或联系赛事人员。仓库公开和 CI 通过不代表资格审核、验收或奖励发放已完成。
