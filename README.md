# x-ui Recovered

`x-ui Recovered` 是一个 x-ui recovered binary install repository，用于在原 Go 源码不可用的情况下，继续一键安装并运行同版本 x-ui。

> 重要提示：本仓库不是完整源码仓库。服务器上没有找到原 Go 源码，恢复得到的 `x-ui` 是 stripped Linux x86-64 binary，因此无法完整还原源码，也不能像源码项目一样修改后重新编译。

当前恢复版本：

- x-ui：`1.10.2`
- Xray：`26.2.6`
- GitHub：<https://github.com/kelenetwork/x-ui-recovered>

## 🚀 快速开始

### 一键安装（推荐）

在 Debian/Ubuntu 等使用 `systemd` 的 Linux x86-64 服务器上，以 `root` 或具备 `sudo` 权限的用户执行：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/kelenetwork/x-ui-recovered/main/install.sh)
```

> 注意：上面的 raw 一键命令要求仓库是 **Public**，否则未登录机器会拿到 GitHub `404: Not Found`。如果仓库保持 Private，请先在目标机器完成 GitHub 认证后 `git clone`，再使用下面的“手动安装”。

一键脚本会执行以下操作：

- 如果是通过 `curl` 远程执行，会先自动下载完整仓库 tarball 到临时目录
- 安装恢复文件到 `/usr/local/x-ui`
- 创建运行数据目录 `/etc/x-ui`
- 安装管理命令 `/usr/bin/x-ui`
- 注册并启动 `x-ui.service`
- 删除仓库内占位/恢复过程中不应直接复用的 Xray 运行配置 `/usr/local/x-ui/bin/config.json`
- 安装结束后清理临时目录

安装完成后可查看面板状态和连接信息：

```bash
x-ui status
x-ui settings
```

## 手动安装

如果希望先审查脚本再安装，可手动克隆仓库：

```bash
git clone https://github.com/kelenetwork/x-ui-recovered.git
cd x-ui-recovered
sudo bash install.sh
```

安装脚本来自当前仓库的 `install.sh`，不会调用已失效或未知的上游安装地址。

## 管理命令

安装后使用 `x-ui` 命令管理服务：

```bash
x-ui status
x-ui settings
x-ui restart
x-ui log
x-ui version
```

常用命令说明：

- `x-ui status`：查看 `x-ui.service` 状态
- `x-ui settings`：显示面板设置和访问地址
- `x-ui restart`：重启 x-ui 服务
- `x-ui log`：跟随查看 systemd journal 日志
- `x-ui version`：显示恢复的面板版本

## 升级

当本仓库中的恢复二进制、脚本或 systemd unit 已更新后，可在仓库目录执行：

```bash
git pull
sudo bash upgrade.sh
```

升级脚本会把当前仓库中的恢复文件覆盖安装到 `/usr/local/x-ui`，更新 `/usr/bin/x-ui` 和 `x-ui.service`，然后重启服务。`/etc/x-ui` 会被保留。

## 卸载

交互式卸载：

```bash
sudo bash uninstall.sh
```

非交互式卸载：

```bash
sudo bash uninstall.sh --yes
```

卸载脚本会停止并禁用 `x-ui.service`，删除 `/usr/local/x-ui`、`/etc/x-ui`、`/etc/systemd/system/x-ui.service` 和 `/usr/bin/x-ui`。

## 恢复内容

本仓库已恢复并整理以下内容：

- x-ui 面板二进制：`recovered/usr-local-x-ui/x-ui`
- Xray 二进制：`recovered/usr-local-x-ui/bin/xray-linux-amd64`
- geo 数据：`geoip.dat`、`geosite.dat`、`geoip_IR.dat`、`geosite_IR.dat`
- 原安装中的管理脚本：`recovered/usr-local-x-ui/x-ui.sh`
- 原 `/usr/bin/x-ui` wrapper：`recovered/usr-bin/x-ui`
- 当前仓库使用的安全 wrapper：`scripts/x-ui`
- systemd unit：`systemd/x-ui.service`、`systemd/x-ui.service.template`
- SQLite schema：`docs/x-ui.schema.sql`
- 示例配置：`examples/config.example.json`

完整恢复记录、路径和校验信息见：[docs/recovery-report.md](docs/recovery-report.md)。

## 敏感数据策略

本仓库不包含真实运行敏感数据，也不应提交这些内容：

- `/etc/x-ui/x-ui.db`
- 真实 `/usr/local/x-ui/bin/config.json`
- 证书和私钥
- 面板账号、密码和登录信息
- 订阅数据
- 访问日志、运行日志和用户流量数据

`docs/x-ui.schema.sql` 仅包含 SQLite 表结构；`examples/config.example.json` 只是占位示例，不是原服务器的真实运行配置。

## 源码说明 / 能不能二开

可以继续使用本仓库安装和运行恢复出的同版本 x-ui，但不能把它当作完整源码项目进行二次开发。

原因是服务器上没有找到原 Go 源码，`recovered/usr-local-x-ui/x-ui` 是 stripped Linux x86-64 binary。它可以被执行、安装和纳入 systemd 管理，但无法可靠恢复成可维护的 Go 源码，也不能像正常源码仓库一样修改后重新编译。

如果需要二开，应寻找并确认原始上游源码及其 license，或迁移到具备明确源码和授权的替代项目。

## 恢复范围

本仓库的目标是保留可安装、可运行的恢复版本：

- 面板二进制和 Xray 二进制可继续部署
- systemd 服务和管理命令可继续使用
- `/etc/x-ui` 运行数据目录由安装脚本创建，但不提供真实业务数据
- 数据库仅恢复 schema，不恢复用户、节点、订阅、流量统计等真实记录
- Xray 真实运行配置不恢复，安装时会移除恢复目录中的 `bin/config.json`

## License / Notice

x-ui panel binary 和 recovered scripts 未能从安装文件中确认 license，当前授权状态未知。公开传播、商用或重新分发前，应先确认原项目授权和相关依赖授权。

Xray 组件随恢复文件保留了 license，位于 `recovered/usr-local-x-ui/bin/LICENSE`，对应 MPL-2.0 license。

更多说明可参考仓库中的 `LICENSE.md`、`NOTICE.md` 和 [docs/recovery-report.md](docs/recovery-report.md)。
