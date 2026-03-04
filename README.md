# acme-script
an acme_manager to manage acme
一、VPS 上直接运行的 2 种方式（首选第一种一键执行）
你的脚本已经上传完成，核心一键执行命令如下，直接复制到你的 Linux VPS 终端执行即可拉起脚本：
bash
运行
# 一键执行（首选，无需下载、无需手动赋权，直接运行）
curl -s https://raw.githubusercontent.com/eshop366/acme-script/main/acme_manager.sh | bash
备选方式（先下载再运行，适合想先查看 / 修改脚本内容的场景）
bash
运行
# 1. 下载脚本到本地
wget https://raw.githubusercontent.com/eshop366/acme-script/main/acme_manager.sh

# 2. 给脚本添加执行权限
chmod +x acme_manager.sh

# 3. 运行脚本
./acme_manager.sh
运行前置要求（必须满足，否则证书申请会失败）
已经给目标域名做好 A 记录解析，指向当前 VPS 的公网 IP；
VPS 防火墙 / 云厂商安全组，已放通对应端口：
Standalone 模式：必须放通 80 端口
Webroot 模式：必须放通 80/443 端口
DNS API 模式：无端口要求，无需公网 IP 也可申请
建议使用 root 用户执行，或使用带 sudo 权限的普通用户执行（安装依赖需要管理员权限）。
二、可直接复制使用的完整 README.md 模板
你可以直接替换掉当前仓库里的 README.md 内容，开箱即用，新手也能看懂：
markdown
# acme-script
一个开箱即用的 ACME 全能证书管理脚本，基于 acme.sh 封装，支持多域名独立证书管理、多 DNS 厂商 API 验证、自动续期，一键申请 Let's Encrypt 免费 SSL 证书。

## 功能特性
- ✅ 单域名/多域名独立证书申请，互不干扰、互不覆盖
- ✅ 支持 ECC 证书（ec-256），兼容性强、性能更优
- ✅ 多种验证方式：Webroot、Standalone、Cloudflare API、腾讯云 DNSPod API、阿里云 API
- ✅ 证书列表查看、路径查询、一键删除、自动续期全生命周期管理
- ✅ 自动安装依赖和 acme.sh 环境，零配置开箱即用
- ✅ 兼容 Debian/Ubuntu/CentOS/RHEL 等主流 Linux 发行版

## 前置要求
1.  目标域名已做好 A 记录解析，指向当前服务器的公网 IP（DNS API 模式无此要求）
2.  服务器防火墙/安全组已放通对应端口：
    - Standalone 模式：80 端口
    - Webroot 模式：80/443 端口
3.  服务器已安装 curl/wget，建议使用 root 用户或带 sudo 权限的用户执行

## 一键运行（首选）
直接在服务器终端执行以下命令，即可拉起脚本：
```bash
curl -s https://raw.githubusercontent.com/eshop366/acme-script/main/acme_manager.sh | bash
分步运行（备选）
bash
运行
# 1. 下载脚本
wget https://raw.githubusercontent.com/eshop366/acme-script/main/acme_manager.sh

# 2. 添加执行权限
chmod +x acme_manager.sh

# 3. 运行脚本
./acme_manager.sh
使用说明
脚本为交互式菜单，运行后按菜单提示选择对应功能即可：
申请新证书：输入域名，选择验证方式，按提示完成证书申请
所有证书列表：查看当前服务器上所有已申请的证书信息
删除域名证书：删除不再使用的域名证书，停止自动续期
查看证书路径：查询指定域名的证书、私钥、全链证书的完整路径
续期管理：查看 / 安装自动续期任务、强制续期所有证书
证书路径说明
每个域名的证书完全独立存储，互不影响：
ECC 证书默认存储路径：~/.acme.sh/你的域名_ecc/
私钥文件：~/.acme.sh/你的域名_ecc/你的域名.key
证书文件：~/.acme.sh/你的域名_ecc/你的域名.cer
全链证书文件：~/.acme.sh/你的域名_ecc/fullchain.cer
注意事项
Let's Encrypt 单域名证书有申请频率限制，请勿频繁重复申请测试
脚本默认开启证书自动续期，无需手动操作，服务器需保持正常运行
更换域名时，直接申请新域名证书即可，旧域名证书可单独删除，互不干扰
开源协议
MIT License
