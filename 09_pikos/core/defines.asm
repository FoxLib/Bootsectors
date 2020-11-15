; http://wiki.osdev.org/Memory_Map_(x86)#BIOS_Data_Area_.28BDA.29

define              NULL   0
macro               brk { xchg bx, bx }

; ----------------------------------------------------------------------
; CORE Переменные ядра
; ----------------------------------------------------------------------

; Real:
RM_IVT              equ 00000000h           ; 2048 Interrupt Vector Table
RM_BDA              equ 00000400h           ; 256  BIOS Data Area

VBE20_ICTRL         equ 00000800h           ; 256  RealMode блок Vesa Ctrl
VBE20_IVIDEO        equ 00000900h           ; 256  RealMode блок Vesa Info

; Protected:
DISK_SECTOR         equ 00000800h           ; 512  IDENTIFY Disk Temp
                                            ;      либо временный сектор                                            

TSS                 equ 00000A00h           ; 104  Адрес TSS-таблицы
KEYBOARD_STATE      equ 00000B00h           ; 256  Состояния нажатия клавиш на клавиатуре
KEYBOARD_BUFFER     equ 00000C00h           ; 256  Клавиатурный буфер
DISK_DRIVES         equ 00000D00h           ; 768  Информация обо всех разделах и дисках

PDBR                equ 00001000h           ; 4096 Основной PDBR
PGT                 equ 00400000h           ; 4 Мб Каталоги страниц для разметки 4 Гб памяти

DISK_CLUSTER        equ 00100000h           ; 64Кб Кластер (временный)

; ----------------------------------------------------------------------
; PIO | Port I/O Disk 
; ----------------------------------------------------------------------

PIO_DATA_PORT       equ 0
PIO_FEATURES        equ 1
PIO_SECTORS         equ 2
PIO_LBA_LO          equ 3
PIO_LBA_MID         equ 4
PIO_LBA_HI          equ 5
PIO_DEVSEL          equ 6
PIO_CMD             equ 7

ATADEV_UNKNOWN      equ 0
ATADEV_PATAPI       equ 1
ATADEV_SATAPI       equ 2
ATADEV_PATA         equ 3
ATADEV_SATA         equ 4
ATADEV_FAILED       equ 5
