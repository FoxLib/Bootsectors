#!/bin/sh

if (fasm loader.asm >> /dev/null) 
then

    mv loader.bin disk/
    bochs -f a.bxrc -q

fi

