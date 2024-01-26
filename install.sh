#!/bin/bash

# echo "           _                               _       _   "
# echo " _ __ ___ (_) __ _  _____      ___ __ ___ (_)_ __ | |_ "
# echo "| '_ ` _ \| |/ _` |/ _ \ \ /\ / / '_ ` _ \| | '_ \| __|"
# echo "| | | | | | | (_| | (_) \ V  V /| | | | | | | | | | |_ "
# echo "|_| |_| |_|_|\__,_|\___/ \_/\_/ |_| |_| |_|_|_| |_|\__|"
# echo "                                                       "
echo '           _                               _       _   '
echo ' _ __ ___ (_) __ _  _____      ___ __ ___ (_)_ __ | |_ '
echo '| '"'"'_ ` _ \| |/ _` |/ _ \ \ /\ / / '"'"'_ ` _ \| | '"'"'_ \| __|'
echo '| | | | | | | (_| | (_) \ V  V /| | | | | | | | | | |_ '
echo '|_| |_| |_|_|\__,_|\___/ \_/\_/ |_| |_| |_|_|_| |_|\__|'
echo '                                                       '

echo "此脚本在来自 https://www.xuehaiwu.com/palworld-server/ 的脚本的基础上进行修改"  
sleep 3s  
echo "感谢腾讯云提供的测试服务器"    


if [[ $EUID -ne 0 ]]; then
    echo -e "${Red}请使用root权限运行此脚本，具体命令为 sudo -i ${Font}"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo "curl 未安装，正在使用 apt 安装..."
    sudo apt update
    sudo apt install -y curl
fi

rm /usr/local/bin/palworld
rm /usr/local/sh/palworld.sh

mkdir -p /usr/local/sh && curl -o /usr/local/sh/palworld.sh https://raw.githubusercontent.com/miaowmint/palworld/main/palworld.sh

ln -s /usr/local/sh/palworld.sh /usr/local/bin/palworld && chmod +x /usr/local/bin/palworld

echo -e "后续管理幻兽帕鲁服务端，只需要在命令行输入\033[32m palworld \033[0m即可"

sleep 5s

palworld
