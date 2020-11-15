# ----------------------------------------------------------------------
# Писать на диск (флешку)
# dd conv=notrunc if=boot.bin of=/dev/sdX bs=446 count=1     
# dd conv=notrunc if=manager.bin of=/dev/sdX seek=1 bs=512 count=128
# ----------------------------------------------------------------------

# Компиляция BOOT
if (fasm boot.asm)
then

    # Запись в MBR
    dd conv=notrunc if=boot.bin of=../disk.img bs=446 count=1    
        
    # Компиляция MANAGER
    if (fasm manager.asm)
    then

        # Запись в Hidden-Area (размер до 1 мб) до 64 кб кода
        dd conv=notrunc if=manager.bin of=../disk.img seek=1 bs=512 count=128

        # Запуск Bochs
        cd .. && bochs -f bochs.bxrc -q
    fi

fi



