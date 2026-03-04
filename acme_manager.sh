#!/bin/bash

# ACME 全球全能版证书管理脚本（修复管道输入版）
# 支持：多域名独立申请、独立删除、互不干扰
# 支持：阿里云、腾讯云、Cloudflare、HTTP、Standalone、ECC

set -e

ACME_SH="$HOME/.acme.sh/acme.sh"
ACME_CONF="$HOME/.acme.sh/account.conf"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 关键修复：强制从终端读取输入
read_tty() {
    read -r "$@" < /dev/tty
}

# 检查并设置邮箱
check_email() {
    if [ ! -f "$ACME_CONF" ] || ! grep -q "ACCOUNT_EMAIL" "$ACME_CONF"; then
        echo -e "${YELLOW}请输入邮箱（用于证书过期提醒）${NC}"
        read_tty -p "邮箱: " USER_EMAIL
        if [ -z "$USER_EMAIL" ]; then
            echo -e "${RED}邮箱不能为空${NC}"
            exit 1
        fi
        echo "ACCOUNT_EMAIL='$USER_EMAIL'" >> "$ACME_CONF"
        echo -e "${GREEN}邮箱已保存: $USER_EMAIL${NC}"
    fi
}

# 检查依赖 + 安装 acme.sh
check_acme() {
    if ! command -v socat >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1; then
        echo -e "${YELLOW}安装依赖 socat curl...${NC}"
        if command -v apt >/dev/null; then
            apt update >/dev/null 2>&1 && apt install -y socat curl
        elif command -v yum >/dev/null; then
            yum install -y socat curl
        fi
    fi

    if [ ! -f "$ACME_SH" ]; then
        echo -e "${YELLOW}正在安装 acme.sh...${NC}"
        curl -s https://gitee.com/neilpang/acme.sh/raw/master/acme.sh | sh -s -- --install-online
        source ~/.bashrc 2>/dev/null || true
        echo -e "${GREEN}acme.sh 安装完成${NC}"
    fi

    check_email
    $ACME_SH --set-default-ca --server letsencrypt >/dev/null 2>&1
}

# 申请证书（多域名完全独立）
issue_cert() {
    echo -e "\n${BLUE}=== 申请 ECC 证书（新域名随便申请，互不影响）===${NC}"
    read_tty -p "请输入域名 (如 ccc.bbb.com): " domain
    [ -z "$domain" ] && return

    echo "1) Webroot       (有网站运行)"
    echo "2) Standalone    (80端口空闲)"
    echo "3) Cloudflare    API"
    echo "4) 腾讯云 DNSPod API"
    echo "5) 阿里云        API"
    read_tty -p "选择验证方式 [1-5]: " m

    case $m in
        1)
            read_tty -p "Web 根目录: " wr
            $ACME_SH --issue -d "$domain" -w "$wr" --keylength ec-256
            ;;
        2)
            $ACME_SH --issue -d "$domain" --standalone --keylength ec-256
            ;;
        3)
            read_tty -p "CF_Email: " cf_mail
            read_tty -p "CF_Key: " cf_key
            export CF_Email="$cf_mail"
            export CF_Key="$cf_key"
            $ACME_SH --issue --dns dns_cf -d "$domain" --keylength ec-256
            ;;
        4)
            read_tty -p "DP_Id: " dp_id
            read_tty -p "DP_Key: " dp_key
            export DP_Id="$dp_id"
            export DP_Key="$dp_key"
            $ACME_SH --issue --dns dns_dp -d "$domain" --keylength ec-256
            ;;
        5)
            read_tty -p "Ali_Key: " ali_key
            read_tty -p "Ali_Secret: " ali_sec
            export Ali_Key="$ali_key"
            export Ali_Secret="$ali_sec"
            $ACME_SH --issue --dns dns_ali -d "$domain" --keylength ec-256
            ;;
        *)
            echo -e "${RED}无效选项${NC}"
            ;;
    esac
}

# 查看证书路径（自动识别 ECC / 普通）
show_cert_path() {
    echo -e "\n${BLUE}=== 查看域名证书路径 ===${NC}"
    read_tty -p "输入要查看的域名: " domain
    [ -z "$domain" ] && return

    if [ -d "$HOME/.acme.sh/${domain}_ecc" ]; then
        DIR="$HOME/.acme.sh/${domain}_ecc"
    elif [ -d "$HOME/.acme.sh/${domain}" ]; then
        DIR="$HOME/.acme.sh/${domain}"
    else
        echo -e "${RED}未找到该域名证书${NC}"
        return
    fi

    echo -e "\n证书目录: ${GREEN}$DIR${NC}"
    echo -e "FullChain: ${GREEN}$DIR/fullchain.cer${NC}"
    echo -e "PrivKey   : ${GREEN}$DIR/$domain.key${NC}"
    echo -e "Cert      : ${GREEN}$DIR/$domain.cer${NC}"
}

# 续期管理
renew_manager() {
    echo -e "\n=== 续期管理 ==="
    echo "1) 查看 cron 任务"
    echo "2) 安装自动续期任务"
    echo "3) 强制续期所有证书"
    read_tty -p "选择: " r

    case $r in
        1) crontab -l 2>/dev/null | grep acme || echo "未配置续期" ;;
        2) $ACME_SH --install-cronjob && echo "自动续期已开启" ;;
        3) $ACME_SH --renew-all --force ;;
    esac
}

# 主菜单
menu() {
    echo -e "\n========================================"
    echo "       ACME 全能证书管理脚本（多域名版）"
    echo "========================================"
    echo " 1) 申请新证书   2) 所有证书列表   3) 删除域名证书"
    echo " 4) 查看证书路径 5) 续期管理       6) 退出"
    echo "========================================"
    read_tty -p "请选择: " opt

    case $opt in
        1) issue_cert ;;
        2) $ACME_SH --list ;;
        3)
            read_tty -p "输入要删除的旧域名 (如 aaa.bbb.com): " d
            [ -n "$d" ] && $ACME_SH --remove -d "$d" && echo "已删除 $d"
            ;;
        4) show_cert_path ;;
        5) renew_manager ;;
        6) exit 0 ;;
        *) echo -e "${RED}输入错误${NC}" ;;
    esac
}

# 启动
check_acme
while true; do menu; done
