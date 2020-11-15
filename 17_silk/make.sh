#!/bin/sh

# Подсчет количества строк
echo "total rows: "
find . | grep '.asm' | xargs cat | wc -l 

# Если компиляция прошла успешно, то записать результат, иначе ошибка
if (fasm main.asm > /dev/tty)
then

    # Скопировать в заранее подмонтированную VFAT (disk.img)
    cp main.bin /mnt/disk/sys.bin
    rm main.bin
    bochs -f start.bxrc -q
    
fi

