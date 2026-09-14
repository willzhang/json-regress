# json-regress Native CLI

独立文件接口模块，依赖官方 moonbitlang/x@0.4.43 和父目录的纯 MoonBit 比较库。工作区只选择本模块与父模块。

从仓库根执行 `bash scripts/json-regress.sh --help`，或 `bash scripts/build-cli.sh` 获取可执行文件路径。完整命令、输入规则和报告协议见 [文件比较与重放](../docs/FILE_COMPARISON.md)。

本地接口更新限定为 `bash scripts/moon-local.sh -C cli info main`，格式检查限定 `-C cli fmt --check main`。不要用不限定包的工作区命令修改第三方依赖。
