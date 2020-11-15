#!/bin/sh

if (fasm dos.asm)
then
    if (mv dos.bin disk/dos.sys)
    then
        bochs -f c.bxrc -q
    fi
fi
