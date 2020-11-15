#!/bin/sh

# Пример для запуска. Отсюда не запускать.
sudo mount floppy.img -t vfat -o loop,rw,uid="`whoami`",sync,offset=$[0] floppy 
sudo mount disk.img   -t vfat -o loop,rw,uid="`whoami`",sync,offset=$[1048576] disk
