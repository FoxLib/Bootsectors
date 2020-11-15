# Установка

## Подготовка диска
```
mkdir disk
dd if=/dev/zero of=disk.img bs=1024 count=262144
fdisk disk.img
n p 1 2048 524287 t 0B w
sudo losetup -o 1048576 /dev/loop1 disk.img
sudo mkfs.fat -F32 /dev/loop1
sudo losetup -d /dev/loop1
```

## Сборка бутсектора
```
cd boot/disk
make
```

## Монтирование диска
```
sudo mount floppy.img -t vfat -o loop,rw,uid="`whoami`",sync,offset=$[0] floppy
sudo mount disk.img   -t vfat -o loop,rw,uid="`whoami`",sync,offset=$[1048576] disk
```
