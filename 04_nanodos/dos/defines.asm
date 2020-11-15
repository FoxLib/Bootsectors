macro brk { xchg bx, bx }

macro pm_enter {

    ; JMPF  10h : pm_entry
    db      66h, 0EAh
    dd      pm_entry + 100000h - 10h
    dw      10h

}

; 
dos.param.tmp_sector            equ 0x0600   ; Указатель 0:0x600 временного сектора
dos.param.fs_block              equ 0x0800   ; Указатель 0:0x800 на описатели FileSystem (FAT/Ext)
dos.param.files                 equ 0x0900   ; Открытые файловые Handlers (900h-FFFh) x 32 byte размер
dos.param.files_top             equ 0x1000   ; Максимальный адрес файловых дескрипторов
dos.param.segment_start         equ 0x0100   ; Откуда начинается свободная память

; Поля BIOS Parameter Block (BPB)
disk.fat.bsBytesPerSec          equ 00Bh
disk.fat.bsSecPerClust          equ 00Dh    ; Секторов в кластере
disk.fat.bsResSectors           equ 00Eh    ; Резервированных секторов перед FAT
disk.fat.bsFATs                 equ 010h    ; Количество FAT 
disk.fat.bsRootDirEnts          equ 011h    ; Количество записей в root (только fat12/16)
disk.fat.bsSectors              equ 013h    ; Количество секторов в целом (fat12/16)
disk.fat.bsFATsecs              equ 016h    ; Размер FAT(16) в секторах
disk.fat.bsHugeSectors          equ 020h    ; Количество секторов в целом (fat16/32)

disk.fat32.bsBigFatSize         equ 024h    ; Размер FAT(32) в секторах
disk.fat32.bsRootCluster        equ 02Ch    ; Номер кластера с Root Entries

; Типы файловых систем
disk.fat.unknown                equ 0x00
disk.fat.12                     equ 0x0C
disk.fat.16                     equ 0x10
disk.fat.32                     equ 0x20

; Описатели файловых систем / FAT16 / FAT32
; 32 БАЙТА РАЗМЕР ЭЛЕМЕНТА
; ----------------------------------------------------------------------

fs.dd.start_partition           equ 0x00    ; Начало раздела
fs.dd.start_data                equ 0x04    ; Начало данных
fs.dd.start_fat                 equ 0x08    ; Начало FAT
fs.dd.size                      equ 0x0C    ; Размер диска (в секторах)
fs.dd.fat_root                  equ 0x10    ; Сектор/Кластер с Root Dir 
fs.dw.filetype                  equ 0x14    ; Тип файловой системы
fs.dw.device_id                 equ 0x16    ; Устройство 80h-FFh BIOS
fs.dw.cluster_size              equ 0x18    ; Количество секторов на кластер
fs.dw.root_ent_sectors          equ 0x1A    ; Количество Root Entries (FAT16)

; Дескриптор файла 
; 32 БАЙТ РАЗМЕР ЭЛЕМЕНТА
; ----------------------------------------------------------------------

fsitem.dd.cluster               equ 0x00    ; 4 Стартовый кластер файла
fsitem.dd.size                  equ 0x04    ; 4 Размер файла
fsitem.db.mode                  equ 0x08    ; 1 Режим 0-Read 1-Write 2-R/W
fsitem.db.seek_mode             equ 0x09    ; 1 Режим 0-Start, 1-End, 2-Append
fsitem.dd.cursor                equ 0x0A    ; 4 Положение курсора в файле
fsitem.db.attr                  equ 0x0E    ; 1 Атрибуты:
                                            ;   Бит 0 - дескриптор свободен (=0)
                                            ;   Бит 1 - это CONSOLE
fsitem.db.alias_of              equ 0x0F    ; 1 Алиас другого дескриптора
                                            ;   (остальные поля игнорируются)
fsitem.dd.current               equ 0x10    ; 4 Текущий кластер
fsitem.dd.file_sector           equ 0x14    ; 4 Сектор с файлом
fsitem.dw.file_id               equ 0x18    ; 2 Указатель в секторе на DIR_ENTRY (+dos.param.tmp_sector)

