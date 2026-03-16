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
            $ACME_SH --list 
            ;;
        2) 
            echo -e "\n${YELLOW}正在检查并安装自动续期任务 (Cron)...${NC}"
            # 安装 crontab 依赖（如果缺失的话）
            if ! command -v crontab >/dev/null 2>&1; then
                if command -v apt >/dev/null; then apt update && apt install -y cron
                elif command -v yum >/dev/null; then yum install -y cronie
                fi
            fi
            
            # 让 acme.sh 注入定时任务
            $ACME_SH --install-cronjob >/dev/null 2>&1
            
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
            $ACME_SH --renew-all --force 
            ;;
        4) 
            read -p "输入要删除的域名: " d 
            [ -n "$d" ] && $ACME_SH --remove -d "$d" 
            ;;
        5) 
            return 
            ;;
        *) 
            echo -e "${RED}输入错误${NC}" 
            ;;
    esac
}
