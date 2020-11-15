; ---------------------------------------------
; Разметка памяти
; ---------------------------------------------

const_INTERRUPTS        equ 0x00000 ; Таблица системных прерываний
const_IDE_VENDOR        equ 0x00800 ; Данные о 512ID дисках
const_KEYB_BUFFER       equ 0x01800 ; Клавиатурный буфер (кодировка CP1251)
const_KEYB_STATUS       equ 0x01900 ; Статусы нажатых кнопок
const_CMOS              equ 0x01A00 ; CMOS данные
const_LOMALLOC          equ 0x01B00 ; Malloc (до 1,25 мб)

const_PDBR              equ 0x02000 ; Глобальный каталог страниц
const_PAGE4MB           equ 0x03000 ; Первый каталог (4мб)

const_FS_LIST           equ 0x04000 ; Листинг файловых систем

const_SECTOR            equ 0x8FE00 ; Последний скачанный сектор
const_CLUSTER           equ 0x90000 ; Последний скачанный кластер

const_VGAHI             equ 0xA0000 ; Видеопамять 320x200, 640x480
const_VGATXT            equ 0xB8000 ; Видеопамять 80x25

const_BITMASK           equ 0x100000 ; 128 кб битовая маска в памяти
const_TASKS             equ 0x120000 ; 64кб листинг загруженных приложений

; ---------------------------------------------
; Функции входа и работы в защищенном режиме
; ------------------------------------------------------
; https://ru.wikipedia.org/wiki/Дескриптор_сегмента
; Работа в защищенном режиме 
; ------------------------------------------------------

par1 EQU ebp + 0x08
par2 EQU ebp + 0x0C
par3 EQU ebp + 0x10
par4 EQU ebp + 0x14
par5 EQU ebp + 0x18

; Локальные переменные 
a1 EQU ebp - 0x04 ; [ebp] = esp, поэтому локальная паременная начинается с - 0x04
a2 EQU ebp - 0x08
a3 EQU ebp - 0x0C
a4 EQU ebp - 0x10
a5 EQU ebp - 0x14
a6 EQU ebp - 0x18
a7 EQU ebp - 0x1C
a8 EQU ebp - 0x20
a9 EQU ebp - 0x24

; Порты для инициализации PIC
; ------------------------------------------------------------------------------
PIC1             EQU 0x20  ; IO базовый адрес для master PIC */
PIC2             EQU 0xA0  ; IO базовый адрес для slave PIC */

PIC1_COMMAND     EQU PIC1
PIC1_DATA        EQU (PIC1+1)

PIC2_COMMAND     EQU PIC2
PIC2_DATA        EQU (PIC2+1)

PIC_EOI          EQU 0x20  ; End-of-interrupt command code */

ICW1_ICW4        EQU 0x01  ; ICW4 (not) needed */
ICW1_SINGLE      EQU 0x02  ; Single (cascade) mode */
ICW1_INTERVAL4   EQU 0x04  ; Call address interval 4 (8) */
ICW1_LEVEL       EQU 0x08  ; Level triggered (edge) mode */
ICW1_INIT        EQU 0x10  ; Initialization - required! */
 
ICW4_8086        EQU 0x01  ; 8086/88 (MCS-80/85) mode */
ICW4_AUTO        EQU 0x02  ; Auto (normal) EOI */
ICW4_BUF_SLAVE   EQU 0x08  ; Buffered mode/slave */
ICW4_BUF_MASTER  EQU 0x0C  ; Buffered mode/master */
ICW4_SFNM        EQU 0x10  ; Special fully nested (not) */

; ----------------------------------------------------------------------------

; out(A, B)
macro outb_wait port, d {

        mov al, d
        out port, al
        jcxz $+2
        jcxz $+2
}

macro outb D, A {

        mov dx, D
        mov al, A
        out dx, al
}

macro inb D {

        mov dx, D
        in  al, dx
}

; Маскирование битовой маски
macro IRQ_mask channel, bitmask {

        in  al, channel
        and al, bitmask
        out channel, al
}

; Создать фрейм локальных переменных (dword)
macro create_frame count 
{
        push ebp
        mov  ebp, esp
        sub  esp, count * 4
}

; EOI: master, slave
macro eoi_master {

        mov al, 0x20
        out 0x20, al
}

macro eoi_slave {

        mov al, 0x20
        out 0xA0, al
        out 0x20, al
}

macro state_save {

        pusha
}

macro state_load {

        popa
}

; Вызов процедур в C-стиле
; -------------------------
macro call1 F,A { ; 1 параметр (x4)

        push dword A
        call F
}

macro call2 F,A,B { ; 2 параметра (x8)

        push dword B
        push dword A
        call F
}

macro call3 F,A,B,C { ; 3 параметра (xC)

        push dword C
        push dword B
        push dword A
        call F
}

macro call4 F,A,B,C,D { ; 4 параметра (x10)

        push dword D
        push dword C
        push dword B
        push dword A
        call F
}

macro call5 F,A,B,C,D,E { ; 4 параметра (x14)

        push dword E
        push dword D
        push dword C
        push dword B
        push dword A
        call F
}

; ----------------------------------------------------------------------------

pm_descriptor: ; Инициализация дескрипторов

.null:  ; Пустой селектор (NULL)
        dd 0, 0        

.code:  ; 08h 4Гб, вся память, сегмент кода

        dw 0xffff              ; limit[15..0]
        dw 0                   ; addr[15..0]
        db 0                   ; addr[23..16]        
        db 80h + (10h + 8)     ; тип=8 (код для чтения) + 10h (s=1) + 80h (p=1), dpl = 0
        db 80h + 0xF + 40h     ; limit[23..16]=0x0f, G=1, D=1
        db 0                   ; addr[31..24]

.data:  ; 10h 4Гб, вся память, данные

        dw 0xffff
        dw 0
        db 0    
        db 80h + (10h + 2)     ; тип=2 (данные для чтения и записи) + 10h (s=1) + 80h (p=1), dpl = 0
        db 80h + 0xF + 40h     ; G=1, D=1, limit=0
        db 0

.tss:   ; 18h Дескриптор TSS

        dw 103                 ; размер TSS (104 байта)
        dw generaltss          ; ссылка на TSS
        db 0
        db 80h + 9             ; 32-битный свободный TSS, P=1
        db 40h                 ; DPL=0, G=0, D=1 (32 битный)
        db 0 

.gdt:   dw 0,0,0               ; Указатель на GDT 
.idt:   dw 0,0,0               ; Указатель на IDT

; ------------------------------------------------------------

generaltss: ; Основной TSS

        dw 0, 0         ; 00 -- / LINK
        dd 0            ; 04 ESP0
        dw 0, 0         ; 08 -- / SS0
        dd 0            ; 0C ESP1
        dw 0, 0         ; 10 -- / SS1
        dd 0            ; 14 ESP2
        dw 0, 0         ; 18 -- / SS2
        dd 0            ; 1C CR3
        dd 0            ; 20 EIP
        dd 0            ; 24 EFLAGS
        dd 0            ; 28 EAX
        dd 0            ; 2C ECX
        dd 0            ; 30 EDX 
        dd 0            ; 34 EBX
        dd 0            ; 38 ESP
        dd 0            ; 3C EBP
        dd 0            ; 40 ESI
        dd 0            ; 44 EDI
        dw 0, 0         ; 48 -- / ES
        dw 0, 0         ; 4C -- / CS
        dw 0, 0         ; 50 -- / SS
        dw 0, 0         ; 54 -- / DS
        dw 0, 0         ; 58 -- / FS
        dw 0, 0         ; 5C -- / GS
        dw 0, 0         ; 60 -- / LDTR
        dw 104, 0       ; 64 IOPB offset / --
