; Просто заглушка
INTERRUPT_NULL:    
    brk
    iret

; http://wiki.osdev.org/Exceptions
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

    pop eax
    iret

INTERRUPT_09_FPU_seg:

    iret    

INTERRUPT_0A_TS:

    iret

INTERRUPT_0B_NP:

    iret

INTERRUPT_0C_SS:

    iret

; --------------------
; General INTERRUPT-eption (требуется извлечение кода ошибки) [1]
; >> Креш программы. Если на уровне 0, то неисправимый.
; --------------------
INTERRUPT_0D_GP:

    pop eax

    mov ax, 0x1700
    mov cx, 80 * 25
    mov edi, 0xb8000
    rep stosw

    jmp $
    ;iret

; Page fault
INTERRUPT_0E_PF: 

    pop eax
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

INTERRUPT_14_VE: ; Virtualization INTERRUPT_eption | http://wiki.osdev.org/INTERRUPT_eptions#Virtualization_INTERRUPT_eption

    iret

INTERRUPT_1E_SX: ; Security INTERRUPT_eption | http://wiki.osdev.org/INTERRUPT_eptions#Security_INTERRUPT_eption

    iret    

; ----------------------------------------------------------------------------------
INT_30: 

    iret     