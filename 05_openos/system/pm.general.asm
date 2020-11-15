
; bx Битовая маска, которая запрещает или разрешает прерывания
; ------------------------------------------------------------------------------
irq_redirect:

        ; Отключение APIC
        mov ecx, 0x1B
        rdmsr
        and eax, 0xfffff7ff ; Сбрасываем 11-й бит в MSR 1Bh (APIC=0)
        wrmsr

        ; Запуск последовательности инициализации (в режиме каскада)
        outb_wait PIC1_COMMAND, ICW1_INIT + ICW1_ICW4
        outb_wait PIC2_COMMAND, ICW1_INIT + ICW1_ICW4

        outb_wait PIC1_DATA, 0x20 ; ICW2: Master PIC vector offset 0x20 .. 0x27    
        outb_wait PIC2_DATA, 0x28 ; ICW2: Slave PIC vector offset 0x28 .. 0x2F

        outb_wait PIC1_DATA, 4 ; ICW3: послать сигнал на Master PIC, что существует slave PIC at IRQ2 (0000 0100)    
        outb_wait PIC2_DATA, 2 ; ICW3: сигнал Slave PIC на идентификацию каскада (0000 0010)

        ; 8086/88 (MCS-80/85) режим (master/slave)
        outb_wait PIC1_DATA, ICW4_8086
        outb_wait PIC2_DATA, ICW4_8086

        ; Отключить все прерывания
        outb_wait PIC1_DATA, 0xFF
        outb_wait PIC2_DATA, 0xFF

        ; Размаскировать некоторые прерывания
        IRQ_mask PIC1_DATA, bl
        IRQ_mask PIC2_DATA, bh
        
        ret

; Инициализация RTC-таймера
; ------------------------------------------------------
timer_set:

        mov al, 0x34
        out 0x43, al
        mov al, 0x9B
        out 0x40, al ; lsb
        mov al, 0x2E
        out 0x40, al ; msb    
        ret
