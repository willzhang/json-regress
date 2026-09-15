# 公开发布与报名交接

更新：2026-09-15。仓库和软件包的交付入口如下。

## 已完成

- 公开仓库：[willzhang/json-regress](https://github.com/willzhang/json-regress)。默认分支 `codex/ml-regression`，保留原始 10 个开发阶段及后续实质改动，未 squash。
- 首次推送提交：`3620117dd3f03f95cc0f346d1f547dcab8984dfd`。
- 首次远程验证：[GitHub Actions 34912598554](https://github.com/willzhang/json-regress/actions/runs/34912598554)，conclusion 为 success。该流程调用与本地相同的 `scripts/check-local.sh --integration`。
- README、许可证、源码、测试、可运行示例及申报参考已公开。Git 历史的凭据特征检查未发现令牌、私钥或非 noreply 邮箱；本地凭据、构建缓存、第三方源码缓存与运行产物没有推送。

## Mooncakes 发行记录

2026-09-15，`moon whoami` 已确认 `Logged in as willzhang`。主模块统一为 `willzhang/json_regress@0.1.0`，内部导入和独立模块依赖同步更新。CLI 与 MoonXi 集成继续是源码仓库中的本地模块，不单独发布。

本轮问题：将本地占位包转为可从注册表安装的正式依赖。基线为已公开且 CI 通过的代码；行为与容差保持不变。输入是已确认的 namespace 与完整 Git 提交；输出是发布包和独立消费验证。先运行现有全量验证，再从提交导出干净目录打包，避免把正在编辑的申报稿带入发布。发布后在仓库外添加 `willzhang/json_regress@0.1.0`，验证根库与 checking/numeric/trajectory 导入，以及应通过和应失败的比较。无需新增训练或付费资源。

发布结果：`moon publish` 返回 `Server status: 200 OK`。公开包页为 [willzhang/json_regress@0.1.0](https://mooncakes.io/docs/willzhang/json_regress)，公开 ZIP 的 120 个文件与审计后的归档逐字节一致。

- 发布来源提交：`dde5140df0234f718f2ae16ff36364aa319a3028`。
- 该提交的[远程 CI](https://github.com/willzhang/json-regress/actions/runs/34930620813) 已通过。
- 发布归档 SHA-256：`43a010e854bf899a35f6a8a051e973d8434f624741de7eec2a99acbad849f6d4`。
- 独立临时项目仅声明注册表依赖，无本地 workspace/path 引用；`moon add willzhang/json_regress@0.1.0` 实际下载成功。Wasm 和 Native 各 3 项消费测试通过，覆盖根库、numeric、trajectory、checking 导入，以及匹配、差异和非法输入三个结果。
- 原工作区正在编辑的申报参考稿保持原样，未纳入这次提交或发布；发布使用上述 Git 提交中的公开参考稿。

安装命令：

```sh
moon add willzhang/json_regress@0.1.0
```

本轮发布已完成。官方包管理说明：[账号与发布](https://docs.moonbitlang.com/en/latest/toolchain/moon/package-manage-tour.html)。

## 报名顺序

根据 2026-09-15 读取的[官方首页源码](https://github.com/moonbitlang/Hackathon2026/blob/main/src/App.tsx)，报名需参赛信息、公开仓库和一页项目说明；随后进行资格审核、公开持续开发与验收。因此应先有可访问的公开仓库，再提交报名。当前公开说明没有把 Mooncakes 发包列为报名的前置条件，也不要求先完成所有功能再报名。

1. 填入上面的公开仓库地址；目前这一步已经具备。
2. 理解并修改 [申报参考稿](PROPOSAL_REFERENCE.md)，以本人表述整理一页说明。
3. 通过[官网](https://moonbitlang.github.io/Hackathon2026/)或其明确链接的[飞书报名表](https://bxup9uklfcb.feishu.cn/share/base/form/shrcnWUMlgpbwHaXgzV7HmNhNhg)提交资料。
4. 按官方入口加入赛事交流群，继续保留实质开发和修复记录，并按审核反馈准备验收。

官网写明本期 9 月 24 日验收并截止报名，最终执行口径以[赛事章程](https://bxup9uklfcb.feishu.cn/wiki/Dx4Bwd6D1i3GfHkajQCcF7SznEd)和官方通知为准。本轮核验了官网实际指向的链接；没有代填报名表、提交个人资料或联系赛事人员。仓库公开和 CI 通过不代表资格审核、验收或奖励发放已完成。

## 0.1.1 发布准备

本轮将环境相关设置迁至未跟踪的本地配置，并通过 `.moonignore` 将仓库管理和申报文档排除出软件包。原有开发阶段保留；库代码及比较协议不变。安装目标为 `willzhang/json_regress@0.1.1`，本节在注册表上传和独立安装完成后记录结果。

检查命令：`python3 scripts/check-publication.py --history`、`moon package --list` 以及 `python3 scripts/check-publication.py --archive <archive.zip>`。检查只输出文件位置与类别。
