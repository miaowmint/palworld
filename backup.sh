#!/bin/bash

if [ $(docker ps -a -q -f name=steamcmd) ]; then
    mkdir -p /data/palworld/backup
    echo -e "${Green}开始压缩上次备份...${Font}"
    tar -zcvf /data/palworld/backup/Saved_$(date +'%Y-%m-%d_%H.%M.%S').tar.gz -C /data/palworld/ Saved
    echo -e "${Green}压缩备份完成${Font}"
    echo -e "${Green}开始导出幻兽帕鲁存档及配置...${Font}"
    docker cp steamcmd:/home/steam/Steam/steamapps/common/PalServer/Pal/Saved/ /data/palworld/
    echo -e "${Green}幻兽帕鲁存档及配置已成功导出${Font}"
    echo -e "${Green}检查备份压缩包数量${Font}"
    backup_files_quantity=$(ls -1 "/data/palworld/backup/" | wc -l)
    echo -e "${Green}检查到 $backup_files_quantity 个备份压缩包${Font}"
    max_backup_files=1008
    if [ "$backup_files_quantity" -gt "$max_backup_files" ]; then
        echo -e "${Green}压缩包数量超过 $max_backup_files 个，开始删除最旧的备份文件...${Font}"
        oldest_backup=$(ls -1t "/data/palworld/backup/" | tail -n 1)
        rm "/data/palworld/backup/$oldest_backup"
        echo "已删除最旧的备份文件: $oldest_backup"
    fi
else
    echo -e "${Red}幻兽帕鲁服务端不存在，导出失败！${Font}"
fi
