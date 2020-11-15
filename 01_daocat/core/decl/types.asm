; Типы системных сегментов
; -----------------------------------------------
GATE_TYPE_NONE                       EQU 0x0
SYS_SEGMENT_AVAIL_286_TSS            EQU 0x1
SYS_SEGMENT_LDT                      EQU 0x2
SYS_SEGMENT_BUSY_286_TSS             EQU 0x3
SYS_286_CALL_GATE                    EQU 0x4
TASK_GATE                            EQU 0x5
SYS_286_INTERRUPT_GATE               EQU 0x6
SYS_286_TRAP_GATE                    EQU 0x7
;                                    /* 0x8 reserved */
SYS_SEGMENT_AVAIL_386_TSS            EQU 0x9
;                                    /* 0xa reserved */
SYS_SEGMENT_BUSY_386_TSS             EQU 0xb
SYS_386_CALL_GATE                    EQU 0xc
;                                    /* 0xd reserved */
SYS_386_INTERRUPT_GATE               EQU 0xe
SYS_386_TRAP_GATE                    EQU 0xf

; -----------------------------------------------

; Из исходников Bochs
; -----------------------------------------------
DATA_READ_ONLY                      EQU 0x0
DATA_READ_ONLY_ACCESSED             EQU 0x1
DATA_READ_WRITE                     EQU 0x2
DATA_READ_WRITE_ACCESSED            EQU 0x3
DATA_READ_ONLY_EXPAND_DOWN          EQU 0x4
DATA_READ_ONLY_EXPAND_DOWN_ACCESSED EQU 0x5
DATA_READ_WRITE_EXPAND_DOWN         EQU 0x6
DATA_READ_WRITE_EXPAND_DOWN_ACCESSED EQU 0x7
CODE_EXEC_ONLY                      EQU 0x8
CODE_EXEC_ONLY_ACCESSED             EQU 0x9
CODE_EXEC_READ                      EQU 0xA
CODE_EXEC_READ_ACCESSED             EQU 0xB
CODE_EXEC_ONLY_CONFORMING           EQU 0xC
CODE_EXEC_ONLY_CONFORMING_ACCESSED  EQU 0xD
CODE_EXEC_READ_CONFORMING           EQU 0xE
CODE_EXEC_READ_CONFORMING_ACCESSED  EQU 0xF

; Смещение +5 [Descriptor Privilege Level]
DPL_0               equ 0x00 ; Уровень привилегии 0 (высший ранг)
DPL_1               equ 0x20
DPL_2               equ 0x40
DPL_3               equ 0x60 ; Уровень привилегии 3 (низший ранг)

; Смещение +5
BIT_ACCESSED        equ 0x01 ; Бит доступа в сегмент. Этот бит показывает, был ли произведен доступ к сегменту, описываемому этим дескриптором, или нет.
BIT_SYSTEM          equ 0x10 ; Определяет системный объект. Если этот бит установлен, то дескриптор определяет сегмент кода или данных, а если сброшен,
                             ; то системный объект (например, сегмент состояния задачи, локальную дескрипторную таблицу, шлюз).

BIT_PRESENT         equ 0x80 ; Присутствие сегмента в памяти. Если этот бит установлен, то сегмент есть в памяти, если сброшен, то его нет.

; Смещение +6
BIT_USER            equ 0x1000 ; Бит пользователя. Этот бит процессор не использует и позволяет программе использовать его в своих целях.
BIT_X               equ 0x2000 ; Зарезервированный бит (возможно 64-х разрядность)
BIT_DEFAULT_SIZE_32 equ 0x4000 ; Размер операндов по умолчанию. Если бит сброшен, по процессор использует объект, описываемый данным дескриптором, как 16-разрядный, если бит установлен - то как 32-разрядный.
BIT_GRANULARITY     equ 0x8000 ; Гранулярность сегмента, т.е. единицы измерения его размера. Если бит G=0, то сегмент имеет байтную гранулярность, иначе - страничную (одна страница - это 4Кб).

; Системные объекты
TYPE_TSS            equ 0x0009 ; Описывает объект TSS (task segment state). Биты 00001001

; UserInterface Ids
; --------------------------------------------
UI_ELEMENTS_COUNT   equ 4 
; ---
UI_NIL              equ 0 ; Пустое значение
UI_BLOCK            equ 1 ; Блок монотонного цвета
UI_VGRADIENT        equ 2 ; Градиент
UI_ICON_4           equ 3 ; Иконка 4 цвета
UI_TEXT             equ 4 ; Моноширинный системный текст

; Структура полей элемента компонента 
; --------------------------------------------
COMSH_FLAG          equ 0x0 ; word
COMSH_TSS           equ 0x2 ; word задача, которая записала этот tss
COMSH_X             equ 0x4 ; word
COMSH_Y             equ 0x6 ; word
COMSH_W             equ 0x8 ; word
COMSH_H             equ 0xA ; word
COMSH_DATA          equ 0xC ; dword
; --
COMSH_SIZEOF        equ 16  ; Размер структуры компонета

; Базовая структура блока описания компонента
; --------------------------------------------
COM_BASIC_X         equ 0x0
COM_BASIC_Y         equ 0x2
COM_BASIC_W         equ 0x4
COM_BASIC_H         equ 0x6
COM_BASIC_ID        equ 0x8
COM_BASIC_DATA      equ 0xA

; Флаги компонента
; --------------------------------------------
COM_FLAG_AVAIL      equ 0x0001 ; Флаг присутствия
