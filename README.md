# x-ui Recovered ✨

一个面向普通用户的 **x-ui 一键安装恢复版**。

适合你想继续安装、运行老版本 x-ui，但原始 Release / 安装包已经不好找、不可用，或者只想要一个能直接部署的恢复包。

> ⚠️ 本项目是 **非官方恢复仓库**，不是完整源码仓库。  
> 当前提供的是已恢复的 Linux x86-64 可执行文件、管理脚本和 systemd 服务文件。

---

## 🚀 一键安装

在支持 `systemd` 的 Linux x86-64 服务器上，以 `root` 用户执行：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/kelenetwork/x-ui-recovered/main/install.sh)
```

安装完成后，脚本会自动输出：

- 🔐 随机生成的用户名
- 🔑 随机生成的密码
- 🌐 面板端口
- 🧩 Web Base Path
- 🔗 面板访问地址

如果忘记登录信息，可以执行：

```bash
x-ui settings
```

---

## ✅ 当前版本

| 组件 | 版本 |
|---|---:|
| x-ui | `1.10.2` |
| Xray | `26.2.6` |
| 架构 | `linux/amd64` |

---

## 🧰 常用命令

安装后直接输入：

```bash
x-ui
```

即可打开交互式管理菜单。

常用快捷命令：

```bash
x-ui settings   # 查看面板设置
x-ui status     # 查看服务状态
x-ui restart    # 重启服务
x-ui log        # 查看运行日志
x-ui version    # 查看版本
```

---

## 🛡️ 安全默认值

首次安装时，如果检测到默认账号 `admin/admin`，脚本会自动随机生成新的登录信息：

- ✅ 随机用户名
- ✅ 随机密码
- ✅ 随机 Web Base Path
- ✅ 可选择自定义端口；不设置则随机端口

这样可以避免默认账号和默认路径直接暴露在公网。

---

## 📦 这个仓库包含什么？

本仓库整理了可继续部署 x-ui 所需的运行文件：

- 🧠 x-ui 面板二进制
- ⚙️ Xray 二进制
- 🌍 geoip / geosite 数据文件
- 🕹️ `x-ui` 交互式管理脚本
- 🧩 systemd 服务文件
- 🧪 示例配置与数据库结构说明

详细恢复记录见：[`docs/recovery-report.md`](docs/recovery-report.md)

---

## 💻 系统要求

推荐环境：

- Debian / Ubuntu / CentOS / Rocky / AlmaLinux 等常见 Linux 发行版
- `systemd`
- `root` 权限
- `x86_64 / amd64` 架构

暂不支持：

- ❌ ARM / ARM64
- ❌ Windows
- ❌ macOS
- ❌ 不使用 systemd 的环境

---

## 🔄 重新安装 / 更新

如果你已经安装过旧版本，可以直接重新运行一键安装命令：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/kelenetwork/x-ui-recovered/main/install.sh)
```

脚本会尽量保留 `/etc/x-ui` 下的运行数据，并重新安装恢复版文件。

> 建议操作前自行备份重要配置。

---

## 🗑️ 卸载

如果你是克隆仓库后安装的，可以在仓库目录执行：

```bash
sudo bash uninstall.sh
```

非交互卸载：

```bash
sudo bash uninstall.sh --yes
```

卸载会移除：

- `/usr/local/x-ui`
- `/etc/x-ui`
- `/usr/bin/x-ui`
- `/etc/systemd/system/x-ui.service`

---

## ❓ 常见问题

### 这是原版 x-ui 吗？

不是完整源码意义上的原版。  
这是基于已恢复运行文件整理出的安装仓库，目标是让同版本 x-ui 可以继续安装和运行。

### 可以二次开发吗？

不适合。  
当前恢复的是 stripped Linux 二进制文件，不是完整 Go 源码，无法像正常源码项目一样修改后重新编译。

### 会包含我的面板数据吗？

不会。  
仓库不包含真实数据库、账号密码、证书、私钥、节点配置或访问日志。

### 为什么只支持 amd64？

因为当前成功恢复到的可运行二进制是 Linux amd64 版本。

---

## 🔐 隐私与敏感数据

本仓库不会提交真实运行数据，例如：

- 面板数据库 `x-ui.db`
- 真实 Xray 运行配置
- 证书和私钥
- 面板账号密码
- 订阅数据
- 访问日志

请不要把自己的生产配置直接提交到公开仓库。

---

## 📜 License / Notice

本项目是恢复整理仓库。x-ui 面板二进制及相关脚本的授权状态请以原项目为准。  
Xray 组件保留其原始 license，见：`recovered/usr-local-x-ui/bin/LICENSE`

更多说明见：[`LICENSE.md`](LICENSE.md)、[`NOTICE.md`](NOTICE.md)、[`docs/recovery-report.md`](docs/recovery-report.md)

---

## ⭐ 提示

如果这个恢复版帮你重新跑起了旧 x-ui，欢迎 Star 支持一下。  
也建议部署后立刻检查登录信息、防火墙和服务器安全策略。 🛡️
