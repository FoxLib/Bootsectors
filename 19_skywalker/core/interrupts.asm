
; IVT Offset | INT #     | Description
; -----------+-----------+-----------------------------------
; 0x0000     | 0x00      | Divide by 0
; 0x0004     | 0x01      | Trace
; 0x0008     | 0x02      | NMI Interrupt
; 0x000C     | 0x03      | Breakpoint (INT3)
; 0x0010     | 0x04      | Overflow (INTO)
; 0x0014     | 0x05      | Bounds range exceeded (BOUND)
; 0x0018     | 0x06      | Invalid opcode (UD2)
; 0x001C     | 0x07      | Device not available (WAIT/FWAIT)
; -----------------------------------------------------------
; 0x0020     | 0x08      | Double fault
; 0x0024     | 0x09      | Coprocessor segment overrun
; 0x0028     | 0x0A      | Invalid TSS
; 0x002C     | 0x0B      | Segment not present
; 0x0030     | 0x0C      | Stack-segment fault
; 0x0034     | 0x0D      | General protection fault
; 0x0038     | 0x0E      | Page fault
; 0x003C     | 0x0F      | ---
; 0x0040     | 0x10      | x87 FPU error
; 0x0044     | 0x11      | Alignment check
; 0x0048     | 0x12      | Machine check
; 0x004C     | 0x13      | SIMD Floating-Point Exception
; 0x00xx     | 0x14-0x1F | ---
; 0x0xxx     | 0x20-0xFF | User definable
; -----------------------------------------------------------

; EOI: master, slave
macro eoi_master {

        mov     al, 0x20
        out     0x20, al
}

macro eoi_slave {

        mov     al, 0x20
        out     0xA0, al
        out     0x20, al
}


; ----------------------------------------------------------------------
; Создание списка прерываний
; ----------------------------------------------------------------------

make_interrupt_list:

        ; Проставить заглушки на все прерывания
        xor     edi, edi
        mov     eax, INTERRUPT_NULL
        mov     bx,  0x0008
        mov     ecx, 256
@@:     call    make_interrupt
        loop    @b

        ; Проставить Exceptions
        xor     edi, edi
        mov     cx,  0x21
        mov     esi, interrupts_list
@@:     lodsd
        call    make_interrupt
        loop    @b

        ; Проставить IRQ
        mov     edi, 0x20 * 8
        mov     cx,  16
        mov     esi, irq_list
@@:     lodsd
        call    make_interrupt
        loop    @b
        ret

; ----------------------------------------------------------------------
; Создание дескриптора (адрес eax), bx - селектор, edi - куда
; ----------------------------------------------------------------------

make_interrupt:

        push    eax ecx
        stosw   ; addr0..15

        xchg    ax, bx
        stosw   ; selector
        xchg    ax, bx

        mov     ax, 0x8E00 ; => Present, 0x0E0 System | gate interrupt
        stosw   ; configs

        shr     eax, 16
        stosw   ; addr16..31
        pop     ecx eax
        ret

; ----------------------------------------------------------------------
; Список системных прерываний
; ----------------------------------------------------------------------

interrupts_list:

        dd INTERRUPT_00_DE      
        dd INTERRUPT_01_DB
        dd INTERRUPT_02_NMI
        dd INTERRUPT_03_BP
        dd INTERRUPT_04_OF
        dd INTERRUPT_05_BR
        dd INTERRUPT_06_UD
        dd INTERRUPT_07_NM
        dd INTERRUPT_08_DF
        dd INTERRUPT_09_FPU
        dd INTERRUPT_0A_TS
        dd INTERRUPT_0B_NP
        dd INTERRUPT_0C_SS
        dd INTERRUPT_0D_GP
        dd INTERRUPT_0E_PF
        dd INTERRUPT_0F
        dd INTERRUPT_10_MF
        dd INTERRUPT_11_AC
        dd INTERRUPT_12_MC
        dd INTERRUPT_13_XF
        dd INTERRUPT_14_VE

; ----------------------------------------------------------------------
; СПИСОК IRQ
; ----------------------------------------------------------------------

irq_list:

        dd irq0, irq1, irq2, irq3, irq4, irq5, irq6, irq7
        dd irq8, irq9, irqA, irqB, irqC, irqD, irqE, irqF

; --------------------------------------------------------------------
; СИСТЕМНЫЕ ПРЕРЫВАНИЯ
; --------------------------------------------------------------------

INTERRUPT_00_DE:

        iret

INTERRUPT_01_DB:

        iret

INTERRUPT_02_NMI:

        iret

INTERRUPT_03_BP:

        iret

INTERRUPT_04_OF:

        iret

INTERRUPT_05_BR:

        iret

INTERRUPT_06_UD:

        iret

INTERRUPT_07_NM:

        iret

INTERRUPT_08_DF: ; Error_Code

        pop     eax
        iret

INTERRUPT_09_FPU:

        iret

INTERRUPT_0A_TS:

        iret

INTERRUPT_0B_NP:

        iret

INTERRUPT_0C_SS:

        iret

; ----------------------------------------------------------------------
; General INTERRUPT-eption (требуется извлечение кода ошибки) [1]
; >> Креш программы. Если на уровне 0, то неисправимый.
; ----------------------------------------------------------------------

INTERRUPT_0D_GP:

        pop     eax
        jmp $

; Page fault
INTERRUPT_0E_PF:

        pop     eax
        iret

INTERRUPT_0F:

        iret

INTERRUPT_10_MF:

        iret

INTERRUPT_11_AC:

        iret

INTERRUPT_12_MC:

        iret

INTERRUPT_13_XF:

        iret

; Virtualization INTERRUPT_exception
INTERRUPT_14_VE:

        iret

; --------------------------------------------------------------------------------------

; Просто заглушка
INTERRUPT_NULL:

        brk
        iret

; ТАЙМЕР 100 Гц
; --------------------------------------------------------------------------------------
irq0:   pusha
        ; call timer_tick
        eoi_master
        popa
        iret

; КЛАВИАТУРА
; --------------------------------------------------------------------------------------
irq1:   pusha
        ; call key_press_interrupt
        eoi_master
        popa
        iret

; --------------------------------------------------------------------------------------
irq2:   pusha
        eoi_master
        popa
        iret

; --------------------------------------------------------------------------------------
irq3:   pusha
        eoi_master
        popa
        iret

; --------------------------------------------------------------------------------------
irq4:   pusha
        eoi_master
        popa
        iret

; --------------------------------------------------------------------------------------
irq5:   pusha
        eoi_master
        popa
        iret

; --------------------------------------------------------------------------------------
irq6:   pusha
        eoi_master
        popa
        iret

; --------------------------------------------------------------------------------------
irq7:   pusha
        eoi_master
        popa
        iret

; --------------------------------------------------------------------------------------
irq8:   pusha
        eoi_slave
        popa
        iret

; --------------------------------------------------------------------------------------
irq9:   pusha
        eoi_slave
        popa
        iret

; --------------------------------------------------------------------------------------
irqA:   pusha
        eoi_slave
        popa
        iret

; --------------------------------------------------------------------------------------
irqB:   pusha
        eoi_slave
        popa
        iret

; --------------------------------------------------------------------------------------
irqC:   pusha
        eoi_slave
        popa
        iret

; --------------------------------------------------------------------------------------
irqD:   pusha
        eoi_slave
        popa
        iret

; --------------------------------------------------------------------------------------
irqE:   pusha
        eoi_slave
        popa
        iret

; --------------------------------------------------------------------------------------
irqF:   pusha
        eoi_slave
        popa
        iret
