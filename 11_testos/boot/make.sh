if (fasm boot.asm)
then

    # скопировать 446 байт в первый сектор на диске (виртуальный)
    dd conv=notrunc if=boot.bin of=../disk.img bs=446 count=1
    
    # удалить временный файл
    rm boot.bin
    
    # запуск bochs
    cd .. && bochs -f c.bxrc -q

fi
