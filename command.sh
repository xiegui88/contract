#!/bin/bash

# 设置颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# 获取脚本文件路径的函数
get_script_path() {
    local script_name="$1"
    # 首先检查当前目录下的 scripts 文件夹
    if [ -f "scripts/$script_name" ]; then
        echo -e "${GREEN}找到脚本: scripts/$script_name${NC}" >&2
        echo "scripts/$script_name"
        return 0
    # 然后检查上层目录的 scripts 文件夹
    elif [ -f "../scripts/$script_name" ]; then
        echo -e "${YELLOW}在上层目录找到脚本: ../scripts/$script_name${NC}" >&2
        echo "../scripts/$script_name"
        return 0
    else
        echo -e "${RED}警告: 未找到脚本 $script_name${NC}" >&2
        echo "scripts/$script_name"  # 如果都找不到，返回默认路径
        return 1
    fi
}

# 定义脚本文件路径
SCRIPT_CHECK=$(get_script_path "check.js")
SCRIPT_DEPLOY=$(get_script_path "deploy.js")
SCRIPT_INTERACT=$(get_script_path "interact.js")

# 存储文件状态（0表示缺失，1表示存在）
CHECK_STATUS=0
DEPLOY_STATUS=0
INTERACT_STATUS=0

# 检查文件是否存在的函数
check_file() {
    if [ ! -f "$1" ]; then
        echo -e "${RED}错误: 找不到文件 $1${NC}"
        return 1
    fi
    return 0
}

# 检查所有必需文件
check_all_files() {
    if [ -f "$SCRIPT_CHECK" ]; then
        CHECK_STATUS=1
    else
        CHECK_STATUS=0
    fi

    if [ -f "$SCRIPT_DEPLOY" ]; then
        DEPLOY_STATUS=1
    else
        DEPLOY_STATUS=0
    fi

    if [ -f "$SCRIPT_INTERACT" ]; then
        INTERACT_STATUS=1
    else
        INTERACT_STATUS=0
    fi
}

# 格式化菜单项，如果需要文件但找不到则添加标记
format_menu_item() {
    local text="$1"
    local status="$2"

    if [ "$status" -eq 0 ]; then
        echo "$text ${GRAY}[文件未找到]${NC}"
    else
        echo "$text"
    fi
}

# 执行命令前检查文件
can_execute() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo -e "${RED}错误: 找不到必需的文件 $file${NC}"
        return 1
    fi
    return 0
}

# 执行命令的函数
execute_command() {
    echo -e "${BLUE}执行命令: $1${NC}"
    eval "$1"
    local status=$?
    if [ $status -eq 0 ]; then
        echo -e "${GREEN}命令执行成功${NC}"
    else
        echo -e "${RED}命令执行失败${NC}"
    fi
    echo
    return $status
}

# 清屏
clear

# 初始检查所有文件
check_all_files

# 主菜单循环
while true; do
    echo -e "${YELLOW}=== Hardhat DApp 开发助手 ===${NC}"
    echo "1. 初始化项目"
    echo -e "$(format_menu_item "2. 检查源码路径" "$CHECK_STATUS")"
    echo "3. 编译合约"
    echo "4. 运行测试"
    echo -e "$(format_menu_item "5. 本地部署" "$DEPLOY_STATUS")"
    echo -e "$(format_menu_item "6. 远程部署(Moonbase)" "$DEPLOY_STATUS")"
    echo -e "$(format_menu_item "7. 交互式调用(脚本)" "$INTERACT_STATUS")"
    echo "8. 交互式控制台"
    echo "0. 退出"
    echo -e "${YELLOW}===========================${NC}"

    read -p "请选择操作 [0-8]: " choice
    echo

    case $choice in
        1)
            execute_command "npx hardhat"
            check_all_files  # 重新检查文件状态
            ;;
        2)
            if can_execute "$SCRIPT_CHECK"; then
                execute_command "npx hardhat run $SCRIPT_CHECK"
            fi
            ;;
        3)
            execute_command "npx hardhat compile"
            ;;
        4)
            execute_command "npx hardhat test"
            ;;
        5)
            if can_execute "$SCRIPT_DEPLOY"; then
                execute_command "npx hardhat run $SCRIPT_DEPLOY --network localhost"
            fi
            ;;
        6)
            if can_execute "$SCRIPT_DEPLOY"; then
                execute_command "npx hardhat run $SCRIPT_DEPLOY --network moonbase"
            fi
            ;;
        7)
            if can_execute "$SCRIPT_INTERACT"; then
                execute_command "npx hardhat run $SCRIPT_INTERACT --network moonbase"
            fi
            ;;
        8)
            echo -e "${BLUE}启动交互式控制台...${NC}"
            echo -e "${GREEN}提示: 使用以下命令获取合约实例：${NC}"
            echo -e "${YELLOW}const address = \"你的合约地址\";${NC}"
            echo -e "${YELLOW}const contract = await ethers.getContractAt(\"合约名\", address);${NC}"
            echo -e "${YELLOW}使用 .exit 退出控制台${NC}"
            echo
            execute_command "npx hardhat console --network moonbase"
            ;;
        0)
            echo -e "${GREEN}感谢使用，再见！${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效的选择，请重试${NC}"
            ;;
    esac

    echo -e "${YELLOW}按回车键继续...${NC}"
    read -r
    clear
done
