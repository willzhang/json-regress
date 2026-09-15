# 发布与交付

当前发行版为 [willzhang/json_regress@0.1.2](https://mooncakes.io/docs/willzhang/json_regress)，源码为 [willzhang/json-regress](https://github.com/willzhang/json-regress)，默认分支为 `codex/ml-regression`。

```sh
moon add willzhang/json_regress@0.1.2
```

## 发行验证

- `moon publish` 返回 200 OK。
- 发布源提交：`9a05dca9efdb0f63bee520b0fda38ed20a3fd5fd`；[远程 CI](https://github.com/willzhang/json-regress/actions/runs/34963192482) 在 moonc v0.10.13 下通过。
- 本地 moonc v0.10.12 验证通过。库测试、真实集成、CLI 与模型输出对照的结果见 [验证记录](codex/VALIDATION.md)。
- 包内 100 个文件。`.moonignore` 排除仓库管理及申报文档；源码、可达历史与归档的发布检查均无命中。
- 原有开发阶段、顺序、署名和时间保留；库行为与比较协议未变。`tool_version` 继续标识 0.1.0 比较引擎，以兼容已有比较重放文件。
- 独立项目从注册表安装成功，100 个文件与检查过的归档逐字节一致；根库、numeric、trajectory、checking 在 Wasm/Native 各 3 项消费测试通过。

## 发布检查

```sh
python3 scripts/check-publication.py --history
moon package --list
python3 scripts/check-publication.py --archive <archive.zip>
```

归档从已提交内容导出，未跟踪的本地设置和未提交材料不参与发布。检查仅输出位置和类别；项目规则保留在源码仓库中。

## 报名顺序

根据 2026-09-15 读取的[官方首页源码](https://github.com/moonbitlang/Hackathon2026/blob/main/src/App.tsx)，报名需参赛信息、公开仓库和一页项目说明；随后进行资格审核、公开持续开发与验收。因此应先有可访问的公开仓库，再提交报名。当前公开说明没有把 Mooncakes 发包列为报名的前置条件，也不要求先完成所有功能再报名。

1. 填入上面的公开仓库地址；目前这一步已经具备。
2. 理解并修改 [申报参考稿](PROPOSAL_REFERENCE.md)，以本人表述整理一页说明。
3. 通过[官网](https://moonbitlang.github.io/Hackathon2026/)或其明确链接的[飞书报名表](https://bxup9uklfcb.feishu.cn/share/base/form/shrcnWUMlgpbwHaXgzV7HmNhNhg)提交资料。
4. 按官方入口加入赛事交流群，继续保留实质开发和修复记录，并按审核反馈准备验收。

官网写明本期 9 月 24 日验收并截止报名，最终执行口径以[赛事章程](https://bxup9uklfcb.feishu.cn/wiki/Dx4Bwd6D1i3GfHkajQCcF7SznEd)和官方通知为准。本轮核验了官网实际指向的链接；没有代填报名表、提交个人资料或联系赛事人员。仓库公开和 CI 通过不代表资格审核、验收或奖励发放已完成。
