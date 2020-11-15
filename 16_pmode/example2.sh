#!/bin/sh

if (fasm example2.asm) 
then
    dd conv=notrunc if=example2.bin of=disk.img bs=446 count=1
    rm example2.bin
    bochs -f c.bxrc -q
fi

