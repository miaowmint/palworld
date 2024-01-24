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
echo "感谢腾讯云提供的测试服务器"    

if ! command -v curl &> /dev/null; then
    echo "curl 未安装，正在使用 apt 安装..."
    sudo apt update
    sudo apt install -y curl
else
    echo "curl 已安装"
fi

mkdir -p /usr/local/sh && curl -o /usr/local/sh/palworld.sh https://mirror.ghproxy.com/https://raw.githubusercontent.com/miaowmint/palworld/main/palworld.sh

ln -s /usr/local/sh/palworld.sh /usr/local/bin/palworld && chmod +x /usr/local/bin/palworld

palworld