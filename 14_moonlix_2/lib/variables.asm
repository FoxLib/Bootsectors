; Системные области в памяти
; ---------------------------------------------------------------------

GDT_start    EQU 0x00004000 ; Таблица GDT 
IDT_start    EQU 0x00006000 ; Таблица IDT

TASK_main    EQU 0x28
TASK_timer   EQU 0x30
TASK_vm      EQU 0x38

PDBR_CR3     EQU 0x00140000 ; Перечислитель каталогов
PDBR_CAT_0   EQU 0x00141000 ; Каталог-0
PTMP         EQU 0x00142000 ; Temporary 3,5kb 

; 0x00004000 .. 0x00006000 GDT
; 0x00006000 .. 0x000067FF IDT
; 0x00006800 .. 0x00007BFF <tmp>
; 0x00000000 .. 0x000FFFFF первый мегабайт базовой памяти
; 0x00100000 .. 0x0013FFFF стек, RING=0
; 0x00140000 .. 0x00141000 PDBR
; 0x00141000 .. 0x00142000 PDBR-0 catalog
; ---------------------------------------------------------
; 0x00142000 >> TMP-Информация для программ (3584 байт)
; ...
; ---------------------------------------------------------
; 0x00150000 .. 0x00160000 Переменные ядра 64 kb
; 0x00160000 .. 0x00180000 128kb, 1260 штук TSS
; ---------------------------------------------------------
; 0x00180000 ...

base_add         EQU 0x00150000

; --- Базы для переменных ---
ps2_base         EQU base_add + 0
timer_ticks      EQU ps2_base + 0x18

; --- Конфигурация ATA-устройств
ata_info         EQU timer_ticks + 0x4      ; 4096 байт (8 ATA-устройств) 
ata_boot         EQU ata_info + 8*0x200     ; Бут-сектора на HDD-дисках [docs/ata.txt:Разделы]

; 0x0000 dword | [buf] Буфер состоянии
; 0x0004 dword | Указатель мыши по x
; 0x0008 dword | Указатель мыши по y
; 0x000C byte  | Состояние мыши

mouse_buf        EQU ps2_base
mouse_x          EQU ps2_base + 4
mouse_y          EQU ps2_base + 8
mouse_s          EQU ps2_base + 0xc
mouse_max_x      EQU ps2_base + 0x10 ; Максимальный предел для X
mouse_max_y      EQU ps2_base + 0x14 ; Предел для Y

; Откуда начинаются TSS
; --------------------------------------
base_TSS         EQU 0x00160000

TSS_general      EQU base_TSS
TSS_timer        EQU 104 + TSS_general 
TSS_VM           EQU 104 + TSS_timer 