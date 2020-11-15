#!/bin/sh

if (fasm boot.asm >> /dev/null) 
then

    dd conv=notrunc if=boot.bin of=../../floppy.img bs=512 count=1
    rm boot.bin

fi

