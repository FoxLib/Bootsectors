#!/bin/sh

# Для main.c
if (nasm -felf32 -o startup.o ../startup.asm)
then

# Компиляция ядра
if (clang -Os -ffreestanding -m32 -mno-sse -c -o main.o main.c)
then

# Выгрузка бинарного файла
if (ld -m elf_i386 -nostdlib -nodefaultlibs --oformat binary -Ttext=0x400000 -Tdata=0x800000 startup.o main.o -o main.raw)
then

    mv main.raw ../../disk/app/desktop.raw
    rm *.o
    
    cd ../../ && sh make.sh
    echo "OK"

fi
fi
fi

