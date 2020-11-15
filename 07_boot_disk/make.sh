#!/bin/sh

# Для kernel.c
if (nasm -felf32 -o startup.o nasm/startup.asm)
then

# Компиляция ядра
if (clang -Os -ffreestanding -m32 -msse -msse2 -c -o kernel.o kernel.c)
then

# Выгрузка бинарного файла
if (ld -m elf_i386 -nostdlib -nodefaultlibs --oformat binary -Ttext=0x100000 -Tdata=0x280000 startup.o kernel.o -o kernel.c.bin)
then

# Собрать Loader -- главный загрузчик
if (fasm loader.asm >> /dev/null) 
then

# Выгрузка на диск
if (mv loader.bin disk)
then

    rm *.o
    rm kernel.c.bin    
    bochs -f c.bxrc -q

fi
fi
fi
fi
fi

