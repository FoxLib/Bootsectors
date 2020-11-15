;
; СОЗДАНИЕ ТАБЛИЦЫ ПРЕРЫВАНИЙ
; http://wiki.osdev.org/Interrupt_Descriptor_Table#I386_Interrupt_Gate
; 

; ----------------------------------------------------------------------

IRQ_TIMER           EQU 0001h
IRQ_KEYBOARD        EQU 0002h
IRQ_CASCADE         EQU 0004h
IRQ_PS2MOUSE        EQU 1000h

; ----------------------------------------------------------------------
; Таблица прерываний Interrupt Service Routines (ISR)

core.ISRHandlers:

        ; Master
        dd      core.DefaultISRMaster        
        dd      dev.ISRKeyboard
        dd      core.DefaultISRMaster
        dd      core.DefaultISRMaster    
        dd      core.DefaultISRMaster
        dd      core.DefaultISRMaster
        dd      core.DefaultISRMaster
        dd      core.DefaultISRMaster

        ; Slave
        dd      core.DefaultISRSlave
        dd      core.DefaultISRSlave
        dd      core.DefaultISRSlave
        dd      core.DefaultISRSlave
        dd      core.DefaultISRSlave
        dd      core.DefaultISRSlave
        dd      core.DefaultISRSlave
        dd      core.DefaultISRSlave

; ----------------------------------------------------------------------
; Таблица исключений

core.ExceptionHandlers:

        ; ..

; ----------------------------------------------------------------------

; 20-27h ISR 0..7 Стандартный обработчик ISR Master
core.DefaultISRMaster:

        push    eax edx
        mov     al, PIC_EOI
        out     PIC1, al
        pop     edx
        pop     eax
        iret

; 28-2Fh ISR 8..F Стандартный обработчик ISR Slave
core.DefaultISRSlave:

        push    eax edx
        mov     al, PIC_EOI
        out     PIC1, al
        out     PIC2, al
        pop     edx
        pop     eax
        iret

; 00-1Fh
core.DefaultException:

        iret

; 30-FFh
core.DefaultInterrupt:

        iret

; ----------------------------------------------------------------------
; Создать вектор прерываний
; edi - указатель на функцию, ebx - номер прерывания
;    
;    uint16_t low_addr
;    uint16_t selector
;    uint16_t attr
;    uint16_t hi_addr

core.VectorMake:

        mov     eax, edi
        lea     edi, [ebx*8]
        mov     [edi], ax                   ; Адрес[15..7]
        mov     [edi + 2], word 0010h       ; Селектор 10h = CODE
        mov     [edi + 4], word 8E00h       ; Атрибуты (Interrupt Gate)
        shr     eax, 16
        mov     [edi + 6], ax               ; Адрес[31..16]
        ret
        
; ----------------------------------------------------------------------
; Создание дефолтной таблицы прерываний

core.ISRMake:

        xor     ebx, ebx
        mov     edi, core.DefaultException
        
        ; Таблица исключений
@@:     call    core.VectorMake
        inc     ebx
        cmp     bl, 20h
        jne     @b
        
        ; ISR Master/Slave
        mov     esi, core.ISRHandlers
@@:     lodsd
        xchg    eax, edi
        call    core.VectorMake
        inc     ebx
        cmp     bl, 30h
        jne     @b

        ; Дефолтные прерывания
        mov     edi, core.DefaultInterrupt
@@:     call    core.VectorMake
        inc     ebx
        cmp     bx, 100h
        jne     @b
        ret

