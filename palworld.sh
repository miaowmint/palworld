#!/bin/bash

#  _ __ ___ (_) __ _  _____      ___ __ ___ (_)_ __ | |_ 
# | '_ ` _ \| |/ _` |/ _ \ \ /\ / / '_ ` _ \| | '_ \| __|
# | | | | | | | (_| | (_) \ V  V /| | | | | | | | | | |_ 
# |_| |_| |_|_|\__,_|\___/ \_/\_/ |_| |_| |_|_|_| |_|\__|

Green="\033[32m"
Font="\033[0m"
Red="\033[31m" 
version="v20230130_162530"

#root权限
root_need(){
    if [[ $EUID -ne 0 ]]; then
        echo -e "${Red}请使用root权限运行此脚本，具体指令为 sudo -i ${Font}"
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
            mkdir -p /data/palworld
            curl -o /data/palworld/PalWorldSettings.ini https://www.xuehaiwu.com/Pal/configs/config_${iniid}.txt
        fi
        if [ -f /data/palworld/PalWorldSettings.ini ]; then
            echo -e "${Green}开始停止幻兽帕鲁服务端...${Font}"
            docker stop steamcmd
            echo -e "${Green}幻兽帕鲁服务端已成功停止！${Font}"
            echo -e "${Green}开始修改服务端配置...${Font}"
            chmod -R 777 /data/palworld/
            docker cp /data/palworld/PalWorldSettings.ini steamcmd:/home/steam/Steam/steamapps/common/PalServer/Pal/Saved/Config/LinuxServer/
            echo -e "${Green}服务端配置已成功修改！服务端重启后生效！${Font}"
            echo -e "${Green}开始重启幻兽帕鲁服务端...${Font}"
            docker restart steamcmd
            echo -e "${Green}幻兽帕鲁服务端已成功重启！${Font}"
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
    echo -e "${Red}swapfile已存在，swap设置失败，请进行手动设置${Font}"
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
            echo "0 5 * * * root docker restart steamcmd" >> /etc/crontab
            ;;
            2)
            echo "0 */12 * * * root docker restart steamcmd" >> /etc/crontab
            ;;
            3)
            read -p "请输入定时重启的cron表达式:" cron
            echo "$cron root docker restart steamcmd" >> /etc/crontab
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

#增加定时备份
add_backup(){
    if [ $(docker ps -a -q -f name=steamcmd) ]; then
        echo -e "${Green}将会每10分钟进行一次备份，将上次备份打成压缩包，并导出新的备份，保留1008份备份即7天的备份${Font}"
        mkdir -p /data/palworld
        curl -o /data/palworld/backup.sh https://raw.githubusercontent.com/miaowmint/palworld/main/backup.sh
        chmod +x /data/palworld/backup.sh
        echo "*/10 * * * * /bin/bash /data/palworld/backup.sh" >> /etc/crontab
        echo -e "${Green}定时备份已成功增加！${Font}"
    else
        echo -e "${Red}幻兽帕鲁服务端不存在，增加定时备份失败！${Font}"
    fi
}

#重启幻兽帕鲁服务端
restart_pal_server(){
    if [ $(docker ps -a -q -f name=steamcmd) ]; then
        echo -e "${Green}开始重启幻兽帕鲁服务端...${Font}"
        docker restart steamcmd
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
        read -p "是否删除容器镜像，直接回车为不删除，输入任意内容为删除" rmi
        if [ -n "$rmi" ]; then
            docker rmi miaowmint/palworld
            echo -e "${Green}容器镜像已成功删除！${Font}"
        else
            echo -e "${Green}不删除容器镜像${Font}"
        fi      
    else
        echo -e "${Red}幻兽帕鲁服务端不存在，删除失败！${Font}"
    fi
}

#导入幻兽帕鲁存档及配置
import_pal_server(){
    if [ $(docker ps -a -q -f name=steamcmd) ]; then
        read -p "请将幻兽帕鲁存档及配置(Saved)文件夹放入 /data/palworld 目录，然后回车继续" import
        echo -e "${Green}开始停止幻兽帕鲁服务端...${Font}"
        docker stop steamcmd
        echo -e "${Green}幻兽帕鲁服务端已成功停止！${Font}"
        echo -e "${Green}开始导入幻兽帕鲁存档及配置...${Font}"
        chmod -R 777 /data/palworld/
        docker cp -a /data/palworld/Saved/ steamcmd:/home/steam/Steam/steamapps/common/PalServer/Pal/
        echo -e "${Green}开始重启幻兽帕鲁服务端...${Font}"
        docker restart steamcmd
        echo -e "${Green}幻兽帕鲁服务端已成功重启！${Font}"
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

#在容器内更新
update_in_container(){
    if [ $(docker ps -a -q -f name=steamcmd) ]; then
        read -p "请注意，此操作会自动进行存档备份，会覆盖之前导出的存档，按回车键继续，输入任何内容退出脚本: " continue_update
        if [ -n "$continue_update" ]; then
            echo "退出脚本"
            exit
        else       
            echo -e "${Green}开始备份${Font}"
            echo -e "${Green}备份的幻兽帕鲁存档及配置将会存放在 /data/palworld 目录下！${Font}"
            echo -e "${Green}开始导出幻兽帕鲁存档及配置...${Font}"
            mkdir -p /data/palworld
            docker cp steamcmd:/home/steam/Steam/steamapps/common/PalServer/Pal/Saved/ /data/palworld/
            echo -e "${Green}幻兽帕鲁存档及配置已成功导出！${Font}"
            echo -e "${Green}开始更新...${Font}"
            docker exec -it steamcmd bash -c "/home/steam/steamcmd/steamcmd.sh +login anonymous +app\_update 2394010 validate +quit"
            if [ $? -eq 0 ]; then
                echo -e "${Green}开始重启幻兽帕鲁服务端...${Font}"
                docker restart steamcmd
                echo -e "${Green}幻兽帕鲁服务端已成功重启！${Font}"
                echo "更新应该是成功了，如果有问题请到腾讯云社区的文章评论下反馈 https://cloud.tencent.com/developer/article/2383539 "
            else
                echo "更新可能失败了，如果是网络的原因（出现Timeout字样）就多重试几次，如果是其他问题请到腾讯云社区的文章评论下反馈 https://cloud.tencent.com/developer/article/2383539 "
            fi
        fi
    else
        echo -e "${Red}幻兽帕鲁服务端不存在，更新失败！${Font}"
    fi
}

#使用watchtower更新
update_with_watchtower(){
     if [ $(docker ps -a -q -f name=steamcmd) ]; then
        read -p "请注意，此操作会自动进行存档备份，会覆盖之前导出的存档，按回车键继续，输入任何内容退出脚本: " continue_update2
        if [ -n "$continue_update2" ]; then
            echo "退出脚本"
            exit
        else       
            echo -e "${Green}开始备份${Font}"
            echo -e "${Green}备份的幻兽帕鲁存档及配置将会存放在 /data/palworld 目录下！${Font}"
            echo -e "${Green}开始导出幻兽帕鲁存档及配置...${Font}"
            mkdir -p /data/palworld
            docker cp steamcmd:/home/steam/Steam/steamapps/common/PalServer/Pal/Saved/ /data/palworld/
            echo -e "${Green}幻兽帕鲁存档及配置已成功导出！${Font}"
            echo -e "${Green}开始更新...${Font}"
            docker run --rm -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --cleanup --run-once steamcmd
            sleep 2s
            echo -e "${Green}镜像更新完成，开始停止幻兽帕鲁服务端...${Font}"
            docker stop steamcmd
            echo -e "${Green}幻兽帕鲁服务端已成功停止！${Font}"
            echo -e "${Green}开始导入备份的存档${Font}"
            chmod -R 777 /data/palworld/
            docker cp -a /data/palworld/Saved/ steamcmd:/home/steam/Steam/steamapps/common/PalServer/Pal/
            echo -e "${Green}开始重启幻兽帕鲁服务端...${Font}"
            docker restart steamcmd
            echo -e "${Green}幻兽帕鲁服务端已成功重启！${Font}"
            echo -e "${Green}幻兽帕鲁存档及配置已成功导入！${Font}"
            echo -e "${Green}应该是更新成功了，快去试试能否登录吧，如果有问题请到腾讯云社区的文章评论下反馈 https://cloud.tencent.com/developer/article/2383539 ${Font}"
        fi
    else
        echo -e "${Red}幻兽帕鲁服务端不存在，导出失败！${Font}"
    fi   
}

#更新管理面板
update_sh(){
    curl -o palinstall.sh https://raw.githubusercontent.com/miaowmint/palworld/main/install.sh && chmod +x palinstall.sh && bash palinstall.sh
}

#自动更新管理面板
auto_update_sh(){   
    newversion=$(curl https://raw.githubusercontent.com/miaowmint/palworld/main/version.txt)
    if [ "$version" == "$newversion" ]; then
        echo -e "${Green}当前版本为 $version，最新版本为 $newversion，无需更新！${Font}"
    else
        echo -e "${Green}当前版本为 $version，最新版本为 $newversion，开始更新！${Font}"
        update_sh
    fi
}

#开始菜单
main(){
root_need
install_docker
auto_update_sh
clear
echo -e "———————————————————————————————————————v20230130_162530"
echo -e "${Red}如发现脚本有任何bug或逻辑问题或改进方案，请发邮件到 cat@acat.email 联系我${Font}"
echo -e "———————————————————————————————————————"
echo -e "${Red}后续管理幻兽帕鲁服务端，只需要在命令行输入\033[32m palworld \033[0m即可${Font}"
echo -e "———————————————————————————————————————"
echo -e "推荐使用腾讯云服务器搭建，通过专属活动购买 4核16G 服务器，首月仅需 32 元，链接: https://curl.qcloud.com/UhCol3eZ "
echo -e "———————————————————————————————————————"
echo -e "${Green}0、更新管理面板${Font}"
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
echo -e "${Green}12、更新幻兽帕鲁服务端${Font}"
echo -e "${Green}13、增加定时备份${Font}"
echo -e "———————————————————————————————————————"
read -p "请输入数字 [0-13]:" num
case "$num" in
    0)
    update_sh
    ;;
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
    12)
    update_in_container
    ;;
    13)
    add_backup
    ;;
    *)
    clear
    echo -e "${Green}请输入正确数字 [0-13]${Font}"
    sleep 2s
    main
    ;;
    esac
}
main
