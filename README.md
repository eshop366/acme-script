# 🔐 SSL 证书一键管理脚本

> 傻瓜式 SSL 证书申请与自动续期工具，基于 [acme.sh](https://github.com/acmesh-official/acme.sh)，无需任何专业知识，几分钟搞定 HTTPS。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/eshop366/acme-script/blob/main/LICENSE)
[![Shell](https://img.shields.io/badge/Shell-Bash-blue.svg)](https://github.com/eshop366/acme-script)
[![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey.svg)](https://github.com/eshop366/acme-script)

---

## ✨ 功能介绍

| 功能 | 说明 |
|------|------|
| 🔍 环境检测 | 自动检测系统依赖、端口状态、acme.sh 安装情况 |
| ⚙️ 一键安装 | 自动安装并配置 acme.sh |
| 📜 申请证书 | HTTP 验证方式申请域名 SSL 证书 |
| 🚀 自动部署 | 一键将证书部署到 Nginx 或 Apache，支持自动 reload |
| 📋 证书列表 | 查看所有已申请的证书及到期时间 |
| 🔄 自动续期 | 一键开启定时任务，证书到期前 30 天自动续期，永不过期 |
| 💪 手动续期 | 强制立即续期所有证书 |
| 🗑️ 删除证书 | 安全删除指定域名的证书（含二次确认保护） |

---

## 🚀 快速开始

### 第一步：安装 curl（如未安装）

```bash
# Debian / Ubuntu
apt update && apt install -y curl

# CentOS / RHEL
yum install -y curl
```

### 第二步：下载并运行脚本

```bash
# 下载脚本
curl -O https://raw.githubusercontent.com/eshop366/acme-script/main/acme_manager.sh

# 赋予执行权限
chmod +x acme_manager.sh

# 运行（需要 root 权限）
bash acme_manager.sh
```

### 第三步：按主菜单操作

运行后你会看到如下主菜单，输入对应数字即可：

```
╔══════════════════════════════════════╗
║       SSL 证书一键管理脚本           ║
╚══════════════════════════════════════╝

  1) 系统环境检测
  2) 安装 acme.sh
  3) 申请新证书（HTTP 验证）
  4) 部署证书到 Nginx / Apache
  5) 证书续期与管理
  6) 退出

请选择 [1-6]:
```

> 💡 **首次使用建议顺序：** 先选 `1` 检测环境 → `2` 安装 acme.sh → `3` 申请证书 → `4` 部署到 Web 服务器 → `5` 开启自动续期

---

## 📖 使用说明

### 1. 系统环境检测

选择 `1`，脚本会自动检测：

- 操作系统版本与内核
- `curl`、`socat`、`crontab`、`nginx`、`apache2` 等依赖是否安装
- acme.sh 是否已安装及版本号
- **80 端口**是否被占用（申请证书前必须空闲）

### 2. 安装 acme.sh

选择 `2`，脚本会自动从官方源下载并安装 acme.sh。若已安装则跳过，无需重复操作。

### 3. 申请新证书

选择 `3`，输入你的域名（如 `example.com`），脚本将使用 **HTTP standalone 模式**完成验证并申请证书。

> ⚠️ 申请前请确认：
> - 域名 DNS 已解析到本服务器 IP
> - **80 端口**未被 Nginx / Apache 占用（可先停止 Web 服务）
> - 服务器防火墙已放行 80 端口

### 4. 部署证书到 Nginx / Apache

选择 `4`，再选择目标 Web 服务器，脚本会自动将证书文件复制到 `/etc/ssl/` 目录，并提示配置路径，可选择立即 reload 服务。

Nginx 配置示例：
```nginx
ssl_certificate     /etc/ssl/example.com_fullchain.crt;
ssl_certificate_key /etc/ssl/example.com.key;
```

Apache 配置示例：
```apache
SSLCertificateFile    /etc/ssl/example.com_fullchain.crt
SSLCertificateKeyFile /etc/ssl/example.com.key
```

### 5. 证书续期与管理

选择 `5` 进入续期子菜单：

| 子选项 | 说明 |
|--------|------|
| 查看证书列表 | 列出所有托管域名及到期日期 |
| 开启自动续期 | 注入 cron 定时任务，到期前 30 天自动续期 |
| 手动强制续期 | 立即对所有证书执行续期 |
| 删除证书 | 含格式校验与二次确认，防止误删 |

> ✅ 自动续期开启一次即可，后续完全无需人工干预。

---

## ❓ 常见问题 FAQ

**Q：运行提示"Permission denied"怎么办？**

```bash
chmod +x acme_manager.sh
bash acme_manager.sh
```

---

**Q：提示"必须以 root 用户运行"怎么办？**

```bash
sudo bash acme_manager.sh
```

---

**Q：证书申请失败，提示域名验证错误？**

请确认：
- 域名 DNS 已正确解析到本服务器 IP（可用 `ping example.com` 验证）
- 80 端口未被占用，且防火墙/安全组已放行
- 若使用云服务器，检查控制台安全组规则是否放行 80 端口入站

---

**Q：自动续期任务安装失败怎么办？**

检查 cron 服务状态并手动启动：

```bash
# Debian / Ubuntu
systemctl status cron
systemctl start cron

# CentOS / RHEL
systemctl status crond
systemctl start crond
```

---

**Q：支持通配符证书（`*.example.com`）吗？**

支持，但需要使用 DNS API 验证方式，本脚本当前仅内置 HTTP 验证。如需通配符证书，请参考 [acme.sh DNS API 文档](https://github.com/acmesh-official/acme.sh/wiki/dnsapi) 手动配置。

---

**Q：脚本支持哪些操作系统？**

| 系统 | 支持情况 |
|------|---------|
| Ubuntu 18.04 + | ✅ |
| Debian 9 + | ✅ |
| CentOS 7 / 8 | ✅ |
| AlmaLinux / Rocky Linux | ✅ |

---

## 📄 License

MIT License © 2026

---

> 💡 如有问题，欢迎提交 [Issue](https://github.com/eshop366/acme-script/issues)。
