#!/bin/sh

# -- SUDO --
# dd if=/dev/zero of=floppy.img count=2880
# losetup -o 0 /dev/loop1 floppy.img
# mkfs.fat -F12 /dev/loop1
# losetup -d /dev/loop1
# sudo mount floppy.img -t vfat -o loop,rw,uid="---username---",sync,offset=$[0] disk

if (fasm bootsector.asm >> /dev/null) 
then

    dd conv=notrunc if=bootsector.bin of=../floppy.img bs=512 count=1
    rm bootsector.bin
    cd .. && bochs -f a.bxrc -q

fi

