# 🔐 SSL 证书一键管理脚本

> 傻瓜式 SSL 证书申请与自动续期工具，基于 [acme.sh](https://github.com/acmesh-official/acme.sh)，无需任何专业知识，几分钟搞定 HTTPS。

---

## ✨ 功能介绍

| 功能 | 说明 |
|------|------|
| 📋 证书列表 | 查看所有已申请的证书及到期时间 |
| 🔄 自动续期 | 一键开启定时任务，证书到期前 30 天自动续期，永不过期 |
| 💪 手动续期 | 强制立即续期所有证书 |
| 🗑️ 删除证书 | 安全删除指定域名的证书（含二次确认保护） |

---

## 🚀 快速开始

### 第一步：安装依赖

确保你的服务器已安装 `curl`：

```bash
# Debian / Ubuntu
apt update && apt install -y curl

# CentOS / RHEL
yum install -y curl
```

### 第二步：安装 acme.sh

```bash
curl https://get.acme.sh | sh
source ~/.bashrc
```

### 第三步：下载并运行本脚本

```bash
# 下载脚本
curl -O https://raw.githubusercontent.com/eshop366/acme-script/main/acme_manager.sh

# 赋予执行权限
chmod +x acme_manager.sh

# 运行
./acme_manager.sh
```

### 第四步：按菜单操作

运行后你会看到如下菜单，输入对应数字即可：

```
=== 证书续期与管理 ===
1) 查看所有证书列表 (含到期时间)
2) 开启/检查自动续期任务
3) 手动强制续期所有证书
4) 删除某个证书
5) 返回主菜单

选择 [1-5]:
```

---

## 📖 使用说明

### 1. 查看证书列表

选择 `1`，脚本会列出所有已托管的域名及其到期日期，方便你随时掌握证书状态。

### 2. 开启自动续期

选择 `2`，脚本会自动：
- 检测系统是否安装了 `cron`，如未安装则自动安装并启动
- 注入定时任务，**每天自动巡检**证书状态
- 在证书到期前 **30 天内**自动完成续期

> ✅ 开启一次即可，后续完全无需人工干预。

### 3. 手动强制续期

选择 `3`，立即对所有证书执行续期操作，适合刚迁移服务器或需要立即刷新证书的场景。

### 4. 删除证书

选择 `4`，输入要删除的域名，脚本会：
1. 校验域名格式是否合法
2. **弹出二次确认提示**，防止误操作
3. 确认后再执行删除

> ⚠️ 删除操作不可恢复，请谨慎操作。

---

## ❓ 常见问题 FAQ

**Q：运行脚本提示"Permission denied"怎么办？**

```bash
chmod +x acme_manager.sh
```

---

**Q：自动续期任务安装失败怎么办？**

请检查 cron 服务是否正在运行：

```bash
# Debian / Ubuntu
systemctl status cron

# CentOS / RHEL
systemctl status crond
```

如未运行，手动启动：

```bash
systemctl start cron   # 或 crond
```

---

**Q：证书申请失败，提示域名验证错误？**

请确认：
- 域名的 DNS 已正确解析到当前服务器 IP
- 服务器 **80 端口**（HTTP 验证）或 **443 端口**未被防火墙拦截

---

**Q：支持通配符证书（`*.example.com`）吗？**

支持，但需要配置 DNS API 验证方式。详情请参考 [acme.sh DNS API 文档](https://github.com/acmesh-official/acme.sh/wiki/dnsapi)。

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

MIT License © 2024

---

> 💡 如有问题，欢迎提交 [Issue]([](https://github.com/eshop366/acme-script/issues)。
