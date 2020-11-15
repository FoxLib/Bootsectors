# Дебаг
# objdump -M intel -S kernel.o

# Компиляция ядра на C
nasm -felf -o startup.o core/startup.asm
if (gcc -Os -ffreestanding -m32 -c -o kernel.o kernel.c)
then

    # Компилировать c-файл с системой
    ld -m elf_i386 -nostdlib -nodefaultlibs --oformat binary -Ttext=0x100000 startup.o kernel.o -o kernel.bin 
    
    # Упаковка kernel.bin в RLE-подобный формат
    php pack.php

    # Компиляция основного файла
    if (fasm core.asm)
    then

        # Перемещение на диск / FAT32
        cp core.bin /mnt/disk/core.bin

        # Очистка
        rm *.o
        rm *.rle kernel.bin
        # rm core.bin

        # Запуск bochs
        bochs -f bochs.bxrc -q

    fi

fi
