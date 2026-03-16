#!/bin/bash

# ======================================================
# ACME 证书管理脚本 - 全球全能版 (纠正 & 增强)
# 支持：阿里云、腾讯云、Cloudflare、HTTP/Standalone 模式
# 特点：自动处理 ECC 路径、国内镜像加速、依赖自动安装
# ======================================================

set -e

# 路径定义
ACME_SH="$HOME/.acme.sh/acme.sh"
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查环境与安装 acme.sh
check_env() {
    # 1. 检查并安装必要组件
    if ! command -v socat >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1; then
        echo -e "${YELLOW}正在安装必要组件 (socat/curl)...${NC}"
        if command -v apt >/dev/null; then
            sudo apt-get update && sudo apt-get install -y socat curl
        elif command -v yum >/dev/null; then
            sudo yum install -y socat curl
        fi
    fi

    # 2. 安装 acme.sh (自动识别中国大陆环境)
    if [ ! -f "$ACME_SH" ]; then
        echo -e "${YELLOW}正在安装 acme.sh...${NC}"
        if curl -s --connect-timeout 3 https://www.google.com > /dev/null; then
            curl https://get.acme.sh | sh
        else
            echo -e "${BLUE}检测到国内环境，使用 Gitee 镜像加速安装...${NC}"
            curl https://gitee.com/neilpang/acme.sh/raw/master/acme.sh | sh -s -- --install-online
        fi
    fi

    # 3. 强制切换默认 CA 为 Letsencrypt (ZeroSSL 在某些地区握手较慢)
    $ACME_SH --set-default-ca --server letsencrypt >/dev/null 2>&1
}

# 申请证书函数
issue_cert() {
    echo -e "\n${BLUE}=== 申请证书 (默认使用 ECC 256位加密) ===${NC}"
    read -p "请输入域名 (例如 example.com): " domain
    [ -z "$domain" ] && return

    echo -e "请选择验证方式:"
    echo "1) Webroot 模式 (需指定网站根目录)"
    echo "2) Standalone 模式 (需确保 80 端口未被占用)"
    echo "3) Cloudflare API"
    echo "4) 腾讯云 (DNSPod) API"
    echo "5) 阿里云 API"
    read -p "请选择 [1-5]: " method

    case $method in
        1)
            read -p "输入 Web 根目录: " wr
            $ACME_SH --issue -d "$domain" -w "$wr" --keylength ec-256
            ;;
        2)
            $ACME_SH --issue -d "$domain" --standalone --keylength ec-256
            ;;
        3)
            read -p "CF_Email: " cf_mail && read -p "CF_Key: " cf_key
            export CF_Email="$cf_mail" && export CF_Key="$cf_key"
            $ACME_SH --issue --dns dns_cf -d "$domain" --keylength ec-256
            ;;
        4)
            read -p "DP_Id: " dp_id && read -p "DP_Key: " dp_key
            export DP_Id="$dp_id" && export DP_Key="$dp_key"
            $ACME_SH --issue --dns dns_dp -d "$domain" --keylength ec-256
            ;;
        5)
            read -p "Ali_Key: " ali_key && read -p "Ali_Secret: " ali_sec
            export Ali_Key="$ali_key" && export Ali_Secret="$ali_sec"
            $ACME_SH --issue --dns dns_ali -d "$domain" --keylength ec-256
            ;;
        *) echo -e "${RED}无效选项${NC}" ;;
    esac
}

# 自动识别 ECC/RSA 路径并显示内容
show_cert_path() {
    echo -e "\n${BLUE}=== 证书路径 & 导入信息 ===${NC}"
    read -p "输入主域名: " domain
    [ -z "$domain" ] && return

    # 核心纠正：acme.sh 默认 ECC 证书存放在 domain_ecc 文件夹
    if [ -d "$HOME/.acme.sh/${domain}_ecc" ]; then
        CERT_DIR="$HOME/.acme.sh/${domain}_ecc"
    elif [ -d "$HOME/.acme.sh/${domain}" ]; then
        CERT_DIR="$HOME/.acme.sh/${domain}"
    else
        echo -e "${RED}错误：未找到该域名的证书文件夹！${NC}"
        return
    fi

    echo -e "\n${BLUE}--- 路径信息 ---${NC}"
    echo -e "证书文件 (FullChain): ${GREEN}$CERT_DIR/fullchain.cer${NC}"
    echo -e "私钥文件 (Key):       ${GREEN}$CERT_DIR/$domain.key${NC}"

    echo -e "\n${YELLOW}是否显示证书内容用于面板手动导入? (y/n)${NC}"
    read -p "> " show_content
    if [[ "$show_content" == "y" ]]; then
        echo -e "\n${BLUE}----- FULLCHAIN.CER (复制以下全部内容) -----${NC}"
        cat "$CERT_DIR/fullchain.cer"
        echo -e "\n${BLUE}----- PRIVATE.KEY (复制以下全部内容) -----${NC}"
        cat "$CERT_DIR/$domain.key"
    fi
}

# 续期与管理
manage_cron() {
    echo -e "\n=== 证书管理 ==="
    echo "1) 查看所有证书列表"
    echo "2) 强制续期所有证书"
    echo "3) 删除某个证书"
    echo "4) 返回"
    read -p "选择: " sub_opt

    case $sub_opt in
        1) $ACME_SH --list ;;
        2) $ACME_SH --renew-all --force ;;
        3) read -p "输入要删除的域名: " d && $ACME_SH --remove -d "$d" ;;
        4) return ;;
    esac
}

# 主菜单
menu() {
    echo -e "\n${GREEN}==============================================${NC}"
    echo -e "      ACME 证书管理脚本 (全球全能版)"
    echo -e "${GREEN}==============================================${NC}"
    echo " 1) 申请新证书"
    echo " 2) 查看证书路径 / 导出内容"
    echo " 3) 证书续期与列表管理"
    echo " 4) 退出"
    echo -e "${GREEN}----------------------------------------------${NC}"
    read -p "请选择 [1-4]: " opt

    case $opt in
        1) issue_cert ;;
        2) show_cert_path ;;
        3) manage_cron ;;
        4) exit 0 ;;
        *) echo -e "${RED}选择错误，请重试${NC}" ;;
    esac
}

# 脚本入口
check_env
while true; do
    menu
done
