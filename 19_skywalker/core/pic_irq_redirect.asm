
; В данном модуле происходит перепрограммирование устаревшего PIC
; Вектора аппратных прерываний перенаправляются на $20-$2F

; Порты для инициализации PIC
; ----------------------------------------------------------------------

PIC1             EQU 0x20  ; IO базовый адрес для master PIC
PIC2             EQU 0xA0  ; IO базовый адрес для slave PIC

PIC1_COMMAND     EQU  PIC1
PIC1_DATA        EQU (PIC1+1)

PIC2_COMMAND     EQU  PIC2
PIC2_DATA        EQU (PIC2+1)

PIC_EOI          EQU 0x20  ; End-of-interrupt command code

ICW1_ICW4        EQU 0x01  ; ICW4 (not) needed
ICW1_SINGLE      EQU 0x02  ; Single (cascade) mode
ICW1_INTERVAL4   EQU 0x04  ; Call address interval 4 (8)
ICW1_LEVEL       EQU 0x08  ; Level triggered (edge) mode
ICW1_INIT        EQU 0x10  ; Initialization - required!
 
ICW4_8086        EQU 0x01  ; 8086/88 (MCS-80/85) mode
ICW4_AUTO        EQU 0x02  ; Auto (normal) EOI
ICW4_BUF_SLAVE   EQU 0x08  ; Buffered mode/slave
ICW4_BUF_MASTER  EQU 0x0C  ; Buffered mode/master
ICW4_SFNM        EQU 0x10  ; Special fully nested (not)

; ----------------------------------------------------------------------

; out(A, B)
macro outb_wait port, d {

        mov     al, d
        out     port, al
        jcxz    $+2
        jcxz    $+2
}

macro outb D, A {

        mov     dx, D
        mov     al, A
        out     dx, al
}

macro inb D {

        mov     dx, D
        in      al, dx
}

; Маскирование битовой маски
macro IRQ_mask channel, bitmask {

        in      al, channel
        and     al, bitmask
        out     channel, al
}

; ----------------------------------------------------------------------
; bx Битовая маска, которая запрещает или разрешает прерывания
; ----------------------------------------------------------------------

pic_irq_redirect:

        ; Отключение APIC:
        ; Сбрасываем 11-й бит в MSR 1Bh (APIC=0)

        mov         ecx, 0x1B
        rdmsr
        and         eax, 0xfffff7ff 
        wrmsr

        ; Запуск последовательности инициализации (в режиме каскада)
        outb_wait   PIC1_COMMAND, ICW1_INIT + ICW1_ICW4
        outb_wait   PIC2_COMMAND, ICW1_INIT + ICW1_ICW4

        outb_wait   PIC1_DATA, 0x20 ; ICW2: Master PIC vector offset 0x20 .. 0x27    
        outb_wait   PIC2_DATA, 0x28 ; ICW2: Slave PIC vector offset 0x28 .. 0x2F

        outb_wait   PIC1_DATA, 4 ; ICW3: послать сигнал на Master PIC, что существует slave PIC at IRQ2 (0000 0100)    
        outb_wait   PIC2_DATA, 2 ; ICW3: сигнал Slave PIC на идентификацию каскада (0000 0010)

        ; 8086/88 (MCS-80/85) режим (master/slave)
        outb_wait   PIC1_DATA, ICW4_8086
        outb_wait   PIC2_DATA, ICW4_8086

        ; Отключить все прерывания
        outb_wait   PIC1_DATA, 0xFF
        outb_wait   PIC2_DATA, 0xFF

        ; Размаскировать некоторые прерывания
        IRQ_mask    PIC1_DATA, bl
        IRQ_mask    PIC2_DATA, bh
        
        ret

; Инициализация RTC-таймера 100 Hz
; ------------------------------------------------------
pic_irq_set_timer:

        mov     al, 0x34
        out     0x43, al
        
        mov     al, 0x9B
        out     0x40, al ; lsb
        
        mov     al, 0x2E
        out     0x40, al ; msb    
        ret
