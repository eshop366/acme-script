#!/bin/bash
# =============================================================
#  acme_manager.sh — SSL 证书一键管理脚本
#  仓库: https://github.com/eshop366/acme-script
# =============================================================

# ---------- 颜色定义 ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ---------- 全局变量 ----------
ACME_SH="$HOME/.acme.sh/acme.sh"

# =============================================================
#  工具函数
# =============================================================

# 检查是否以 root 运行
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}❌ 请以 root 用户运行此脚本${NC}"
        exit 1
    fi
}

# 按任意键继续
press_any_key() {
    echo ""
    read -rp "按 Enter 键返回菜单..." _
}

# =============================================================
#  模块一：系统环境检测
# =============================================================
check_env() {
    echo -e "\n${BLUE}=== 系统环境检测 ===${NC}\n"

    # 操作系统
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo -e "  操作系统   : ${GREEN}${PRETTY_NAME}${NC}"
    else
        echo -e "  操作系统   : ${YELLOW}未知${NC}"
    fi

    # 内核版本
    echo -e "  内核版本   : ${GREEN}$(uname -r)${NC}"

    # 检测常用命令
    for cmd in curl socat crontab nginx apache2 httpd; do
        if command -v "$cmd" >/dev/null 2>&1; then
            echo -e "  ${cmd}       : ${GREEN}✅ 已安装${NC}"
        else
            echo -e "  ${cmd}       : ${YELLOW}⚠️  未安装${NC}"
        fi
    done

    # 检测 acme.sh
    if [ -f "$ACME_SH" ]; then
        local ver
        ver=$("$ACME_SH" --version 2>/dev/null | head -n2 | tail -n1)
        echo -e "  acme.sh    : ${GREEN}✅ 已安装 ($ver)${NC}"
    else
        echo -e "  acme.sh    : ${RED}❌ 未安装${NC}"
    fi

    # 80 端口占用检测
    echo ""
    if ss -tlnp 2>/dev/null | grep -q ':80 ' || netstat -tlnp 2>/dev/null | grep -q ':80 '; then
        echo -e "  80 端口    : ${YELLOW}⚠️  已被占用（HTTP 验证前需暂停 Web 服务）${NC}"
    else
        echo -e "  80 端口    : ${GREEN}✅ 空闲${NC}"
    fi

    press_any_key
}

# =============================================================
#  模块二：安装 acme.sh
# =============================================================
install_acme() {
    echo -e "\n${BLUE}=== 安装 acme.sh ===${NC}\n"

    if [ -f "$ACME_SH" ]; then
        echo -e "${GREEN}✅ acme.sh 已安装，无需重复安装${NC}"
        press_any_key
        return
    fi

    echo -e "${YELLOW}正在安装 acme.sh...${NC}"
    if curl -fsSL https://get.acme.sh | bash; then
        # 重新加载环境变量
        # shellcheck source=/dev/null
        source "$HOME/.bashrc" 2>/dev/null || true
        echo -e "${GREEN}✅ acme.sh 安装成功！${NC}"
    else
        echo -e "${RED}❌ 安装失败，请检查网络连接${NC}"
    fi

    press_any_key
}

# =============================================================
#  模块三：申请新证书（HTTP 验证）
# =============================================================
issue_cert() {
    echo -e "\n${BLUE}=== 申请新证书（HTTP 验证）===${NC}\n"

    if [ ! -f "$ACME_SH" ]; then
        echo -e "${RED}❌ 未检测到 acme.sh，请先在主菜单选择安装${NC}"
        press_any_key
        return
    fi

    read -rp "请输入域名（例如 example.com）: " domain
    if [ -z "$domain" ]; then
        echo -e "${RED}❌ 域名不能为空${NC}"
        press_any_key
        return
    fi
    if [[ ! "$domain" =~ ^[a-zA-Z0-9._-]+\.[a-zA-Z]{2,}$ ]]; then
        echo -e "${RED}❌ 域名格式不合法${NC}"
        press_any_key
        return
    fi

    echo -e "\n${YELLOW}正在申请证书，将使用 standalone 模式（临时占用 80 端口）...${NC}"
    echo -e "${YELLOW}⚠️  如果 Nginx/Apache 正在运行，请先停止后再申请${NC}\n"

    if "$ACME_SH" --issue -d "$domain" --standalone; then
        echo -e "\n${GREEN}✅ 证书申请成功！${NC}"
        echo -e "证书目录  : ${CYAN}$HOME/.acme.sh/${domain}/${NC}"
        echo -e "全链证书  : ${CYAN}$HOME/.acme.sh/${domain}/fullchain.cer${NC}  ← 配置 Web 服务器请用此文件"
        echo -e "私钥文件  : ${CYAN}$HOME/.acme.sh/${domain}/${domain}.key${NC}"
        echo -e "\n${YELLOW}⚠️  请勿直接使用 .cer 单域名证书，否则浏览器会提示「不安全」${NC}"
    else
        echo -e "\n${RED}❌ 证书申请失败，请检查：${NC}"
        echo -e "  1. 域名是否已正确解析到本服务器 IP"
        echo -e "  2. 80 端口是否开放（防火墙/安全组）"
        echo -e "  3. 是否有其他程序占用 80 端口"
    fi

    press_any_key
}

# =============================================================
#  模块四：部署证书到 Nginx / Apache
# =============================================================
deploy_cert() {
    echo -e "\n${BLUE}=== 部署证书到 Web 服务器 ===${NC}"
    echo "1) 部署到 Nginx"
    echo "2) 部署到 Apache"
    echo "3) 返回"
    read -rp "选择 [1-3]: " web_opt

    case $web_opt in
        1|2)
            read -rp "请输入已申请证书的域名: " domain
            if [ -z "$domain" ]; then
                echo -e "${RED}❌ 域名不能为空${NC}"
                press_any_key
                return
            fi

            local cert_dir="$HOME/.acme.sh/$domain"
            if [ ! -d "$cert_dir" ]; then
                echo -e "${RED}❌ 未找到该域名的证书，请先申请${NC}"
                press_any_key
                return
            fi

            local fullchain_file="/etc/ssl/${domain}_fullchain.crt"
            local key_file="/etc/ssl/${domain}.key"

            echo -e "${YELLOW}正在安装证书到 /etc/ssl/ ...${NC}"

            if "$ACME_SH" --install-cert -d "$domain" \
                --fullchain-file "$fullchain_file" \
                --key-file       "$key_file"; then

                echo -e "${GREEN}✅ 证书文件已复制到:${NC}"
                echo -e "  全链证书: ${CYAN}${fullchain_file}${NC}  ← Web 服务器使用此文件"
                echo -e "  私钥    : ${CYAN}${key_file}${NC}"

                if [ "$web_opt" -eq 1 ]; then
                    echo -e "\n${YELLOW}请在 Nginx 配置中加入以下内容并 reload：${NC}"
                    echo -e "${CYAN}  ssl_certificate     ${fullchain_file};${NC}"
                    echo -e "${CYAN}  ssl_certificate_key ${key_file};${NC}"
                    echo ""
                    read -rp "是否立即 reload Nginx？[y/N]: " confirm
                    [[ "$confirm" =~ ^[Yy]$ ]] && nginx -t && systemctl reload nginx \
                        && echo -e "${GREEN}✅ Nginx 已重载${NC}" \
                        || echo -e "${YELLOW}跳过重载${NC}"
                else
                    echo -e "\n${YELLOW}请在 Apache 配置中加入以下内容并 reload：${NC}"
                    echo -e "${CYAN}  SSLCertificateFile    ${fullchain_file}${NC}"
                    echo -e "${CYAN}  SSLCertificateKeyFile ${key_file}${NC}"
                    echo ""
                    read -rp "是否立即 reload Apache？[y/N]: " confirm
                    [[ "$confirm" =~ ^[Yy]$ ]] && \
                        (systemctl reload apache2 2>/dev/null || systemctl reload httpd 2>/dev/null) \
                        && echo -e "${GREEN}✅ Apache 已重载${NC}" \
                        || echo -e "${YELLOW}跳过重载${NC}"
                fi
            else
                echo -e "${RED}❌ 证书部署失败${NC}"
            fi
            ;;
        3) return ;;
        *) echo -e "${RED}输入错误${NC}" ;;
    esac

    press_any_key
}

# =============================================================
#  模块五：证书续期与管理
# =============================================================
manage_cron() {
    echo -e "\n${BLUE}=== 证书续期与管理 ===${NC}"
    echo "1) 查看所有证书列表 (含到期时间)"
    echo "2) 开启/检查自动续期任务"
    echo "3) 手动强制续期所有证书"
    echo "4) 删除某个证书"
    echo "5) 返回主菜单"
    read -rp "选择 [1-5]: " sub_opt

    case $sub_opt in
        1)
            echo -e "${YELLOW}当前已管理的证书列表：${NC}"
            "$ACME_SH" --list
            ;;
        2)
            echo -e "\n${YELLOW}正在检查并安装自动续期任务 (Cron)...${NC}"
            if ! command -v crontab >/dev/null 2>&1; then
                if command -v apt >/dev/null; then
                    apt update && apt install -y cron
                    systemctl enable --now cron 2>/dev/null || service cron start
                elif command -v yum >/dev/null; then
                    yum install -y cronie
                    systemctl enable --now crond 2>/dev/null || service crond start
                fi
            fi

            "$ACME_SH" --install-cronjob >/dev/null 2>&1

            if crontab -l 2>/dev/null | grep -q "acme.sh"; then
                echo -e "${GREEN}✅ 自动续期任务已生效！${NC}"
                echo -e "系统每天会自动巡检，在证书到期前 30 天内会自动完成续期。"
            else
                echo -e "${RED}❌ 定时任务安装失败，请手动检查系统的 cron 服务状态${NC}"
            fi
            ;;
        3)
            echo -e "${YELLOW}正在强制续期所有证书...${NC}"
            if "$ACME_SH" --renew-all --force; then
                echo -e "${GREEN}✅ 所有证书续期完成${NC}"
            else
                echo -e "${RED}❌ 部分或全部证书续期失败，请检查 acme.sh 日志${NC}"
            fi
            ;;
        4)
            read -rp "输入要删除的域名: " d
            if [ -z "$d" ]; then
                echo -e "${RED}❌ 域名不能为空${NC}"
                press_any_key
                return
            fi
            if [[ ! "$d" =~ ^[a-zA-Z0-9._-]+$ ]]; then
                echo -e "${RED}❌ 域名格式不合法${NC}"
                press_any_key
                return
            fi
            read -rp "⚠️  确认删除证书 '$d'？此操作不可恢复 [y/N]: " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                if "$ACME_SH" --remove -d "$d"; then
                    echo -e "${GREEN}✅ 证书 '$d' 已成功删除${NC}"
                else
                    echo -e "${RED}❌ 删除失败，请检查域名是否存在${NC}"
                fi
            else
                echo -e "${YELLOW}操作已取消${NC}"
            fi
            ;;
        5) return ;;
        *) echo -e "${RED}输入错误，请选择 1-5${NC}" ;;
    esac

    press_any_key
}

# =============================================================
#  主菜单
# =============================================================
main_menu() {
    while true; do
        clear
        echo -e "${CYAN}"
        echo "╔══════════════════════════════════════╗"
        echo "║       SSL 证书一键管理脚本           ║"
        echo "║  https://github.com/eshop366/acme-script  ║"
        echo "╚══════════════════════════════════════╝"
        echo -e "${NC}"
        echo "  1) 系统环境检测"
        echo "  2) 安装 acme.sh"
        echo "  3) 申请新证书（HTTP 验证）"
        echo "  4) 部署证书到 Nginx / Apache"
        echo "  5) 证书续期与管理"
        echo "  6) 退出"
        echo ""
        read -rp "请选择 [1-6]: " opt
        case $opt in
            1) check_env ;;
            2) install_acme ;;
            3) issue_cert ;;
            4) deploy_cert ;;
            5) manage_cron ;;
            6)
                echo -e "${GREEN}再见！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}输入错误，请选择 1-6${NC}"
                sleep 1
                ;;
        esac
    done
}

# =============================================================
#  脚本入口
# =============================================================
check_root
main_menu
