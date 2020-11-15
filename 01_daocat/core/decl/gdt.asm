; ----------------------------------------------------------------------------------------------------------------------
; ОПИСАНИЯ ДЕСКРИПТОРОВ
; ----------------------------------------------------------------------------------------------------------------------

; КАРТА ПАМЯТИ ПЕРВОГО 1МБ
SEGMENT_NULL        EQU 0x00 ; 00
SEGMENT_CORE_CODE   EQU 0x08 ; 01 Код ядра
SGN_DATA            EQU 0x10 ; 02 Данные ядра 
SEGMENT_CORE_STACK  EQU 0x18 ; 03 Стек ядра
SEGMENT_GDT         EQU 0x20 ; 04 Таблица GDT
SEGMENT_IDT         EQU 0x28 ; 05 Таблица IDT
SEGMENT_PDBR        EQU 0x30 ; 06 Каталог PDBR
SEGMENT_TSS_RW      EQU 0x38 ; 07 Алиас для главных TSS 
SEGMENT_TSS0        EQU 0x40 ; 08 [TSS] Задача ядра 
SEGMENT_TIMER       EQU 0x48 ; 09 [TSS] Задача диспетчера 
SGN_VESA            EQU 0x50 ; 10 VESA LFB
SGN_ESTACK          EQU 0x58 ; 11 32 x 2048 регистрация событий
SEGMENT_WHOLE       EQU 0x60 ; 12 Описывает полную память в 4 Гб
SGN_KBD_DPL0        EQU 0x68 ; 13 Буфер мыши и клавиатуры
SGN_COMEVT          EQU 0x70 ; 14 Списки компонентов и событий

; Базовое количество сегментов
COUNT_SEGMENTS      EQU 14

; Устройство дескриптора
;
; 63           56  55  54  53  52  51         48   47 46 45  44 43  41  40  39       16  15           0
; +--------------+---+---+---+---+---------------+---+-----+---+------+---+-------------+--------------+
; | Адрес 24..31 | G | D | X | U | Предел 16..19 | P | DPL | S | TYPE | A | Адрес 0..23 | Предел 0..15 |
; +--------------+---+---+---+---+---------------+---+-----+---+------+---+-------------+--------------+
;               7                              6                         5             2              0

; --------------------------------------------------------------------------------------------------------------------------------------
; ДОСТУП К ЭТИМ ДАННЫМ ТОЛЬКО ИЗ РЕАЛЬНОГО РЕЖИМА
; --------------------------------------------------------------------------------------------------------------------------------------

descriptors:

; [#08] 32-х разрядный код. Размер кода указывается ассемблером 
DESCRIPTOR  0x00010000, END_OF_CODE, BIT_PRESENT + DPL_0 + BIT_SYSTEM + CODE_EXEC_ONLY + BIT_DEFAULT_SIZE_32

; [#10] Данные, которые указаны в коде
DESCRIPTOR (0x00010000 + END_OF_CODE), END_OF_DATA, BIT_PRESENT + DPL_0 + BIT_SYSTEM + DATA_READ_WRITE

; [#18] Базовый системный стек, от 0x90000 до 0x9FFFF (64 kb)
DESCRIPTOR 0x00090000, 0x10000, BIT_PRESENT + DPL_0 + BIT_SYSTEM + DATA_READ_WRITE

; [#20] Таблица GDT (64kb) Алиас
DESCRIPTOR (0x10 * RM_SEGMENT_GDT), 0x10000, BIT_PRESENT + DPL_0 + BIT_SYSTEM + DATA_READ_WRITE

; [#28] Таблица прерываний (2kb) Алиас
DESCRIPTOR (0x10 * RM_SEGMENT_IDT), 0x00800, BIT_PRESENT + DPL_0 + BIT_SYSTEM + DATA_READ_WRITE

; [#30] Каталоги страниц (алиасы)
DESCRIPTOR PDBR_ADDRESS32, 0x3000, BIT_PRESENT + DPL_0 + BIT_SYSTEM + DATA_READ_WRITE

; [#38] Primary/Slave задача (TSS) 48kb. Алиас для чтения и записи двух TSS
DESCRIPTOR TSS0_ADDRESS32, 0x8000, BIT_PRESENT + DPL_0 + BIT_SYSTEM + DATA_READ_WRITE

; [#40] СИСТЕМНЫЙ ОБЪЕКТ: TSS (32kb)
DESCRIPTOR TSS0_ADDRESS32, 0x4000, BIT_PRESENT + DPL_0 + TYPE_TSS

; [#48] Timer сегмент (16kb)
DESCRIPTOR TSS1_ADDRESS32, 0x4000, BIT_PRESENT + DPL_0 + TYPE_TSS

; [#50] LFB (адрес и размер варьируются)
descriptor_lfb: 
DESCRIPTOR 0xE0000000, 0, BIT_PRESENT + DPL_0 + BIT_SYSTEM + DATA_READ_WRITE + BIT_GRANULARITY

; [#58] Глобальный стек событий 
DESCRIPTOR 0x0, 0x10000, BIT_PRESENT + DPL_0 + BIT_SYSTEM + DATA_READ_WRITE

; [#60] Память полностью (4Гб). Здесь нулевой лимит означает 1Мб * 4096 гранула = 4Гб
DESCRIPTOR 0, 0, BIT_PRESENT + DPL_0 + BIT_SYSTEM + DATA_READ_WRITE + BIT_GRANULARITY

; [#68] Keyboard, Mouse
DESCRIPTOR BUFFER_KDBMOUSE, 2048, BIT_PRESENT + DPL_0 + BIT_SYSTEM + DATA_READ_WRITE ; Для записи с уровня ядра

; [#70] 64kb компоненты ПГШ / 64kb события
DESCRIPTOR 0x50000, 0x20000, BIT_PRESENT + DPL_0 + BIT_SYSTEM + DATA_READ_WRITE
