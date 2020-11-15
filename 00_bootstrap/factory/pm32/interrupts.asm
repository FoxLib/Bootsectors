; **********************************************************************
; Инициализация важных системных прерываний, в том числе IRQ, а также
; обработчиков Exceptions
; **********************************************************************

core_interrupts:

    ; Шаг 1. Установка заглушек
    ; ----------------------------------
    
    xor     edi, edi
    mov     eax, INTERRUPT_NULL
    mov     bx,  0x0008
    mov     ecx, 256
@@: call    make_int_descriptor
    loop    @b
    
    ; Шаг 2. Назначить Exceptions
    ; ----------------------------------
    xor     edi, edi
    mov     cx,  0x21
    mov     esi, interrupts_list
@@: lodsd
    call    make_int_descriptor
    loop    @b

    ; Шаг 3. Назначить IRQ-обработчики
    ; ----------------------------------
    mov     edi, 0x20 * 8
    mov     cx,  16
    mov     esi, irq_list
@@: lodsd
    call    make_int_descriptor
    loop    @b

    jmp     core_interrupts_exit

; ----------------------------------------------------------------------    
; Создание дескриптора (адрес eax), bx - селектор, edi - куда
; ----------------------------------------------------------------------

make_int_descriptor:

    push    eax ecx
    stosw               ; addr0..15   
    xchg    ax, bx    
    stosw               ; selector        
    xchg    ax, bx
    mov     ax, 0x8E00  ; => Present, 0x0E0 System | gate interrupt         
    stosw               ; configs
    shr     eax, 16
    stosw               ; addr16..31
    pop     ecx eax
    ret

; Листинг прерываний процессора (Exceptions)
; ----------------------------------------------------------------------

interrupts_list:

    dd EXCEPTION_00_DE
    dd EXCEPTION_01_DB
    dd EXCEPTION_02_NMI
    dd EXCEPTION_03_BP
    dd EXCEPTION_04_OF
    dd EXCEPTION_05_BR
    dd EXCEPTION_06_UD
    dd EXCEPTION_07_NM
    dd EXCEPTION_08_DF
    dd EXCEPTION_09_FPU
    dd EXCEPTION_0A_TS
    dd EXCEPTION_0B_NP
    dd EXCEPTION_0C_SS
    dd EXCEPTION_0D_GP
    dd EXCEPTION_0E_PF
    dd EXCEPTION_0F
    dd EXCEPTION_10_MF
    dd EXCEPTION_11_AC
    dd EXCEPTION_12_MC
    dd EXCEPTION_13_XF
    dd EXCEPTION_14_VE

; Список IRQ
irq_list:

    ; Шина Master
    dd irq0
    dd irq1
    dd irq2
    dd irq3
    dd irq4
    dd irq5
    dd irq6
    dd irq7 
    
    ; Шина Slave          
    dd irq8
    dd irq9
    dd irqA
    dd irqB
    dd irqC
    dd irqD
    dd irqE
    dd irqF

; Обработчики по умолчанию
irq_defaults:

.irq0   dd interrupts_timer
.irq1   dd interrupts_keyboad

; --------------------------------------------------------------------
; СИСТЕМНЫЕ ПРЕРЫВАНИЯ
; --------------------------------------------------------------------

; Просто заглушка - в прерывании ничего не происходит
; ----
INTERRUPT_NULL:    

    iret
        
EXCEPTION_00_DE: 

    iret

EXCEPTION_01_DB:

    iret

EXCEPTION_02_NMI:

    iret

EXCEPTION_03_BP:

    iret

EXCEPTION_04_OF:

    iret

EXCEPTION_05_BR:

    iret

EXCEPTION_06_UD:

    iret

EXCEPTION_07_NM:

    iret

EXCEPTION_08_DF: ; Error_Code

    pop eax
    iret

EXCEPTION_09_FPU:

    iret    

EXCEPTION_0A_TS:

    iret

EXCEPTION_0B_NP:

    iret

EXCEPTION_0C_SS:

    iret

; --------------------
; General Protection Fault (требуется извлечение кода ошибки) [1]
; >> Креш программы. Если на уровне 0, то неисправимый.

EXCEPTION_0D_GP:

    pop eax
    brk
    jmp $
    iret

; Page fault
EXCEPTION_0E_PF: 

    pop eax
    iret

EXCEPTION_0F:

    iret

EXCEPTION_10_MF:

    iret

EXCEPTION_11_AC:

    iret

EXCEPTION_12_MC:

    iret

EXCEPTION_13_XF:        

    iret

EXCEPTION_14_VE: ; Virtualization INTERRUPT_exception | http://wiki.osdev.org/INTERRUPT_eptions#Virtualization_INTERRUPT_eption

    iret

; ----------------------------------------------------------------------
; IRQ
; ----------------------------------------------------------------------
; Системный таймер 100 Гц

irq0:   

    pushad
    call    [irq_defaults.irq0]
    mov     al, 0x20
    out     0x20, al
    popad
    iret

; ----------------------------------------------------------------------
; КЛАВИАТУРА

irq1:   

brk

    pushad
    call    [irq_defaults.irq1]
    mov     al, 0x20
    out     0x20, al
    popad
    iret

; ----------------------------------------------------------------------
irq2:   

    pushad     
    mov     al, 0x20
    out     0x20, al
    popad    
    iret

; ----------------------------------------------------------------------
irq3:   

    pushad     
    mov     al, 0x20
    out     0x20, al
    popad    
    iret

; ----------------------------------------------------------------------
irq4:   

    pushad     
    mov     al, 0x20
    out     0x20, al
    popad    
    iret

; ----------------------------------------------------------------------
irq5:       

    pushad     
    mov     al, 0x20
    out     0x20, al
    popad    
    iret

; ----------------------------------------------------------------------
irq6:   

    pushad     
    mov     al, 0x20
    out     0x20, al
    popad    
    iret

; ----------------------------------------------------------------------
irq7:       

    pushad     
    mov     al, 0x20
    out     0x20, al
    popad    
    iret

; ----------------------------------------------------------------------
irq8:   

    pushad     
    mov     al, 0x20
    out     0x20, al
    out     0xA0, al
    popad    
    iret

; ----------------------------------------------------------------------
irq9:   

    pushad     
    mov     al, 0x20
    out     0x20, al
    out     0xA0, al
    popad    
    iret

; ----------------------------------------------------------------------
irqA:   

    pushad     
    mov     al, 0x20
    out     0x20, al
    out     0xA0, al
    popad    
    iret

; ----------------------------------------------------------------------
irqB:   

    pushad     
    mov     al, 0x20
    out     0x20, al
    out     0xA0, al
    popad    
    iret

; ----------------------------------------------------------------------
; PS/2 мышь

irqC:   

    pushad     
    mov     al, 0x20
    out     0x20, al
    out     0xA0, al
    popad    
    iret

; ----------------------------------------------------------------------
irqD:  

    pushad     
    mov     al, 0x20
    out     0x20, al
    out     0xA0, al
    popad    
    iret

; ----------------------------------------------------------------------
irqE:  

    pushad     
    mov     al, 0x20
    out     0x20, al
    out     0xA0, al
    popad    
    iret
 
; ----------------------------------------------------------------------
irqF:  

    pushad     
    mov     al, 0x20
    out     0x20, al
    out     0xA0, al
    popad    
    iret


; Обработка системного таймера по умолчаю (100Гц)
interrupts_timer:

    ret

; Обработка данных с клавиатуры по умолчанию (просто читать их)
interrupts_keyboad:

    in      al, 0x60
    ret

; ----------------------------------------------------------------------
core_interrupts_exit:
