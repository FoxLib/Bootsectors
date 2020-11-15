ОПИСАНИЯ ФАЙЛОВ
===============

boot_fat32.asm      - коды с MBR (boot-сектор)
moon.asm            - коды с самой ОС
flash.img.zip.gz.gz - упакованный образ диска
boot.bxrc           - файл с bochs
update.c / update   - для записи на образ

КАК ЗАПИСАТЬ
============

./update moon.bin flash.img       - запись файла moon.bin на flash.img
./boot /dev/sdX boot_fat32.bin su - запись на диск sdX
./boot flash.img boot_fat32.bin   - запись на flash.img (без root-прав)

РЕАЛЬНАЯ ЗАПИСЬ
===============

1 Отформатировать флешку как FAT32
2 На флешку записать с помощью dd первые 446 байт в MBR
3 Скомпилировать и записать файл MOON.BIN

Система готова к запуску с Flash-носителя 
