#!/bin/bash


#  _ __ ___ (_) __ _  _____      ___ __ ___ (_)_ __ | |_ 
# | '_ ` _ \| |/ _` |/ _ \ \ /\ / / '_ ` _ \| | '_ \| __|
# | | | | | | | (_| | (_) \ V  V /| | | | | | | | | | |_ 
# |_| |_| |_|_|\__,_|\___/ \_/\_/ |_| |_| |_|_|_| |_|\__|

Green="\033[32m"
Font="\033[0m"
Red="\033[31m" 

#root权限
root_need(){
    if [[ $EUID -ne 0 ]]; then
        echo -e "${Red}请使用root权限运行此脚本，具体指令为 sudo -i ${Font}"
        exit 1
    fi
}

#检测ovz
ovz_no(){
    if [[ -d "/proc/vz" ]]; then
        echo -e "${Red}不支持OpenVZ虚拟化VPS${Font}"
        exit 1
    fi
}

#检测并安装Docker
install_docker(){
    if command -v docker &> /dev/null; then
        echo -e "${Green}Docker 已安装，进行下一步.${Font}"
    else
        echo -e "${Green}Docker 未安装，正在为您安装...${Font}"
        curl -fsSL https://get.docker.com | bash -s docker
        echo -e "${Green}Docker 安装成功！${Font}"
    fi
}

#安装幻兽帕鲁服务端
install_pal_server(){
    if [ $(docker ps -a -q -f name=steamcmd) ]; then
        echo -e "${Red}幻兽帕鲁服务端已存在，安装失败！${Font}"
    else
        echo -e "${Green}开始安装幻兽帕鲁服务端...${Font}"
        docker run -dit --name steamcmd --net host miaowmint/palworld
        echo -e "${Green}幻兽帕鲁服务端已成功安装并启动！${Font}"
    fi
}

#启动幻兽帕鲁服务端
start_pal_server(){
    if [ $(docker ps -a -q -f name=steamcmd) ]; then
        echo -e "${Green}开始启动幻兽帕鲁服务端...${Font}"
        docker start steamcmd
        echo -e "${Green}幻兽帕鲁服务端已成功启动！${Font}"
    else
        echo -e "${Red}幻兽帕鲁服务端不存在，启动失败！${Font}"
    fi
}

#停止幻兽帕鲁服务端
stop_pal_server(){
    if [ $(docker ps -a -q -f name=steamcmd) ]; then
        echo -e "${Green}开始停止幻兽帕鲁服务端...${Font}"
        docker stop steamcmd
        echo -e "${Green}幻兽帕鲁服务端已成功停止！${Font}"
    else
        echo -e "${Red}幻兽帕鲁服务端不存在，停止失败！${Font}"
    fi
}
#查看幻兽帕鲁服务端状态
check_pal_server_status(){
    if [ $(docker ps -a -q -f name=steamcmd) ]; then
        echo -e "${Green}幻兽帕鲁服务端状态如下：${Font}"
        docker ps -a -f name=steamcmd
        echo -e "${Green}幻兽帕鲁服务端资源使用情况如下：${Font}"
        docker stats --no-stream steamcmd
        echo -e "${Green}服务器内存使用情况如下：${Font}"
        free -h
    else
        echo -e "${Red}幻兽帕鲁服务端不存在！${Font}"
    fi
}
#修改服务端配置
modify_config(){
    if [ $(docker ps -a -q -f name=steamcmd) ]; then
        echo -e "${Green}请前往 https://www.xuehaiwu.com/Pal/ （原脚本作者的网站）进行配置，并输入配置文件ID${Font}"
        read -p "例如配置文件URL为 https://www.xuehaiwu.com/Pal/configs/config_1706097640.txt ，则输入1706097640 " iniid
        if [ -n "$iniid" ]; then
            curl -o /data/palworld/PalWorldSettings.ini https://www.xuehaiwu.com/Pal/configs/config_${iniid}.txt
            chmod -R 777 /data/palworld/
        fi
        if [ -f /data/palworld/PalWorldSettings.ini ]; then
            echo -e "${Green}开始修改服务端配置...${Font}"
            docker cp /data/palworld/PalWorldSettings.ini steamcmd:/home/steam/Steam/steamapps/common/PalServer/Pal/Saved/Config/LinuxServer/
            echo -e "${Green}服务端配置已成功修改！服务端重启后生效！${Font}"
            restart_pal_server
        else
            echo -e "${Red}未找到服务端配置文件，请前往 https://www.xuehaiwu.com/Pal/ 进行配置。${Font}"
        fi
    else
        echo -e "${Red}幻兽帕鲁服务端不存在，修改配置失败！${Font}"
    fi
}

#增加swap内存
add_swap(){
echo -e "${Green}请输入需要添加的swap，单位为 G ，例如输入8则会添加8G的SWAP${Font}"
read -p "请输入swap数值:" swapsize
#检查是否存在swapfile
grep -q "swapfile" /etc/fstab
#如果不存在将为其创建swap
if [ $? -ne 0 ]; then
    echo -e "${Green}swapfile未发现，正在为其创建swapfile${Font}"
    fallocate -l ${swapsize}G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap defaults 0 0' >> /etc/fstab
         echo -e "${Green}swap创建成功，并查看信息：${Font}"
         cat /proc/swaps
         cat /proc/meminfo | grep Swap
else
    echo -e "${Red}swapfile已存在，swap设置失败${Font}"
fi
}

#增加定时重启
add_restart(){
    if [ $(docker ps -a -q -f name=steamcmd) ]; then
        echo -e "${Green}开始增加定时重启...${Font}"
        echo -e "${Green}1、每天凌晨5点${Font}"
        echo -e "${Green}2、每12小时（每天0点/12点）${Font}"
        echo -e "${Green}3、自定义${Font}"
        read -p "请输入数字 [1-3]:" num
        case "$num" in
            1)
            echo "0 5 * * * docker start steamcmd" >> /etc/crontab
            ;;
            2)
            echo "0 */12 * * * docker start steamcmd" >> /etc/crontab
            ;;
            3)
            read -p "请输入定时重启的cron表达式:" cron
            echo "$cron docker start steamcmd" >> /etc/crontab
            ;;
            *)
            echo -e "${Red}请输入正确数字 [1-3]${Font}"
            add_restart
            ;;
        esac
        echo -e "${Green}定时重启已成功增加！${Font}"
    else
        echo -e "${Red}幻兽帕鲁服务端不存在，增加定时重启失败！${Font}"
    fi
}

#重启幻兽帕鲁服务端
restart_pal_server(){
    if [ $(docker ps -a -q -f name=steamcmd) ]; then
        echo -e "${Green}开始重启幻兽帕鲁服务端...${Font}"
        docker start steamcmd
        echo -e "${Green}幻兽帕鲁服务端已成功重启！${Font}"
    else
        echo -e "${Red}幻兽帕鲁服务端不存在，重启失败！${Font}"
    fi
}

#删除幻兽帕鲁服务端
delete_pal_server(){
    if [ $(docker ps -a -q -f name=steamcmd) ]; then
        echo -e "${Green}开始删除幻兽帕鲁服务端...${Font}"
        docker stop steamcmd
        docker rm steamcmd
        echo -e "${Green}幻兽帕鲁服务端已成功删除！${Font}"
    else
        echo -e "${Red}幻兽帕鲁服务端不存在，删除失败！${Font}"
    fi
}

#导入幻兽帕鲁存档及配置
import_pal_server(){
    if [ $(docker ps -a -q -f name=steamcmd) ]; then
        read -p "请将幻兽帕鲁存档及配置(Saved)文件夹放入 /data/palworld 目录，然后回车继续" import
        echo -e "${Green}开始导入幻兽帕鲁存档及配置...${Font}"
        docker cp /data/palworld/Saved/ steamcmd:/home/steam/Steam/steamapps/common/PalServer/Pal/
        restart_pal_server
        echo -e "${Green}幻兽帕鲁存档及配置已成功导入！${Font}"
    else
        echo -e "${Red}幻兽帕鲁服务端不存在，导入失败！${Font}"
    fi
}

#导出幻兽帕鲁存档及配置
export_pal_server(){
    if [ $(docker ps -a -q -f name=steamcmd) ]; then
        echo -e "${Green}此操作会导出容器内 /home/steam/Steam/steamapps/common/PalServer/Pal/Saved 文件夹下所有的文件${Font}"
        echo -e "${Green}导出的幻兽帕鲁存档及配置将会存放在 /data/palworld 目录下！${Font}"
        echo -e "${Green}开始导出幻兽帕鲁存档及配置...${Font}"
        mkdir -p /data/palworld
        docker cp steamcmd:/home/steam/Steam/steamapps/common/PalServer/Pal/Saved/ /data/palworld/
        echo -e "${Green}幻兽帕鲁存档及配置已成功导出！${Font}"
    else
        echo -e "${Red}幻兽帕鲁服务端不存在，导出失败！${Font}"
    fi
}


#开始菜单
main(){
root_need
ovz_no
install_docker
clear
echo -e "———————————————————————————————————————"
echo -e "${Red}由于此脚本为赶工做出的，如发现脚本有任何bug或逻辑问题或改进方案，请发邮件到 cat@acat.email 联系我${Font}"
echo -e "———————————————————————————————————————"
echo -e "${Red}后续管理幻兽帕鲁服务端，只需要在命令行输入\033[32m palworld \033[0m即可${Font}"
echo -e "———————————————————————————————————————"
echo -e "${Green}1、安装幻兽帕鲁服务端${Font}"
echo -e "${Green}2、启动幻兽帕鲁服务端${Font}"
echo -e "${Green}3、停止幻兽帕鲁服务端${Font}"
echo -e "${Green}4、修改服务端配置${Font}"
echo -e "${Green}5、增加swap内存${Font}"
echo -e "${Green}6、增加定时重启${Font}"
echo -e "${Green}7、重启幻兽帕鲁服务端${Font}"
echo -e "${Green}8、导入幻兽帕鲁存档及配置${Font}"
echo -e "${Green}9、导出幻兽帕鲁存档及配置${Font}"
echo -e "${Green}10、查看幻兽帕鲁服务端状态${Font}"
echo -e "${Green}11、删除幻兽帕鲁服务端${Font}"
echo -e "———————————————————————————————————————"
read -p "请输入数字 [1-11]:" num
case "$num" in
    1)
    install_pal_server
    ;;
    2)
    start_pal_server
    ;;
    3)
    stop_pal_server
    ;;
    4)
    modify_config
    ;;
    5)
    add_swap
    ;;
    6)
    add_restart
    ;;
    7)
    restart_pal_server
    ;;
    8)
    import_pal_server
    ;;
    9)
    export_pal_server
    ;;
    10)
    check_pal_server_status
    ;;
    11)
    delete_pal_server
    ;;
    *)
    clear
    echo -e "${Green}请输入正确数字 [1-11]${Font}"
    sleep 2s
    main
    ;;
    esac
}
main
