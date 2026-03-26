# 续期与管理
manage_cron() {
    echo -e "\n${BLUE}=== 证书续期与管理 ===${NC}"
    echo "1) 查看所有证书列表 (含到期时间)"
    echo "2) 开启/检查自动续期任务 (到期前自动续期)"
    echo "3) 手动强制续期所有证书"
    echo "4) 删除某个证书"
    echo "5) 返回主菜单"
    read -p "选择 [1-5]: " sub_opt
    case $sub_opt in
        1)
            echo -e "${YELLOW}当前已管理的证书列表：${NC}"
            "$ACME_SH" --list
            ;;
        2)
            echo -e "\n${YELLOW}正在检查并安装自动续期任务 (Cron)...${NC}"
            # 安装 crontab 依赖（如果缺失的话）
            if ! command -v crontab >/dev/null 2>&1; then
                if command -v apt >/dev/null; then
                    apt update && apt install -y cron
                    systemctl enable --now cron 2>/dev/null || service cron start
                elif command -v yum >/dev/null; then
                    yum install -y cronie
                    systemctl enable --now crond 2>/dev/null || service crond start
                fi
            fi

            # 让 acme.sh 注入定时任务
            "$ACME_SH" --install-cronjob >/dev/null 2>&1

            # 验证是否成功
            if crontab -l 2>/dev/null | grep -q "acme.sh"; then
                echo -e "${GREEN}✅ 自动续期任务已生效！${NC}"
                echo -e "系统每天会自动巡检，在证书到期前 30 天内会自动完成续期。"
            else
                echo -e "${RED}❌ 定时任务安装失败，请手动检查系统的 cron 服务状态。${NC}"
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
            read -p "输入要删除的域名: " d
            # 格式校验
            if [ -z "$d" ]; then
                echo -e "${RED}域名不能为空${NC}"
                return 1
            fi
            if [[ ! "$d" =~ ^[a-zA-Z0-9._-]+$ ]]; then
                echo -e "${RED}❌ 域名格式不合法，请重新输入${NC}"
                return 1
            fi
            # 二次确认
            read -p "⚠️  确认删除证书 '$d'？此操作不可恢复 [y/N]: " confirm
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
        5)
            return
            ;;
        *)
            echo -e "${RED}输入错误，请选择 1-5${NC}"
            ;;
    esac
}
