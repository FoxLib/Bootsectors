; http://wiki.osdev.org/Exceptions

; Прерывание-заглушка (не TRAP)
; ---------------------------------
Interrupt_Stub:

    xchg bx, bx
    iret

; Системные исключения
; ---------------------------------
Exc00_DE: 

    push dword 0
    call gateException
    add  esp, 4
    iret

Exc01_DB:

    push dword 1
    call gateException
    add  esp, 4
    iret

Exc02_NMI:

    push dword 2
    call gateException
    add  esp, 4
    iret

Exc03_BP:

    push dword 3
    call gateException
    add  esp, 4
    iret

Exc04_OF:

    push dword 4
    call gateException
    add  esp, 4
    iret

Exc05_BR:

    push dword 5
    call gateException
    add  esp, 4
    iret

Exc06_UD:

    push dword 6
    call gateException
    add  esp, 4
    iret

Exc07_NM:

    push dword 7
    call gateException
    add  esp, 4
    iret

Exc08_DF: ; Error_Code

    push dword 8
    call gateException_Code
    add  esp, 8
    iret

Exc09_FPU_seg:

    push dword 9
    call gateException
    add  esp, 4
    iret

Exc0A_TS:

    push dword 0xa
    call gateException_Code    
    add  esp, 8
    iret

Exc0B_NP:

    push dword 0xb
    call gateException_Code    
    add  esp, 8
    iret

Exc0C_SS:

    push dword 0xc
    call gateException_Code    
    add  esp, 8
    iret

; --------------------
; General Exception (требуется извлечение кода ошибки) [1]
; >> Креш программы. Если на уровне 0, то неисправимый.
; --------------------
Exc0D_GP:

    pusha    
    push dword [esp + 0x20]
    push dword 0xd
    call gateException_Code
    add  esp, 12
    popa
    add  esp, 4
    iret

; Page fault
Exc0E_PF: 

    pusha
    ; Запись кода ошибки и номера
    push dword [esp + 0x10]
    push dword 0xe
    call gateException_Code    
    add  esp, 8 ; Извлечь стек c
    popa
    add  esp, 4 ; Извлечь код ошибки
    iret

Exc0F:

    push dword 0xf
    call gateException    
    iret

Exc10_MF:
    push dword 0x10
    call gateException        
    iret

Exc11_AC:
    push dword 0x11
    call gateException_Code
    add  esp, 8
    iret

Exc12_MC:
    push dword 0x12
    call gateException   
    add  esp, 4     
    iret

Exc13_XF:        
    push dword 0x13
    call gateException  
    add  esp, 4  
    iret

Exc14_VE: ; Virtualization Exception | http://wiki.osdev.org/Exceptions#Virtualization_Exception
    push dword 0x14
    call gateException 
    add  esp, 4
    iret

Exc1E_SX: ; Security Exception | http://wiki.osdev.org/Exceptions#Security_Exception
    push dword 0x14
    call gateException 
    add  esp, 4
    iret

;; ----------------------
IRQ_Master:

    push eax
    in al, 0x20
    out 0x20, al     
    pop eax
    ret

IRQ_Slave:

    push eax
    mov  al, 0x20
    out  0x20, al
    out  0xA0, al
    pop eax    
    ret

; ------------------------------------------------------------------------------------------------------------------------------------
; IRQ 0..7
; ---------------

IRQ_0: iret ; По сути это редирект

IRQ_1:

    pusha
    push fs
    mov  ax, 0x20
    mov  fs, ax ; data segment
    call keyboard_handler
    pop  fs
    popa
    iret

IRQ_2: ; Каскад

    call IRQ_Master
    iret

IRQ_3:

    call IRQ_Master
    iret

IRQ_4:

    call IRQ_Master
    iret

IRQ_5:

    call IRQ_Master
    iret

IRQ_6:

    call IRQ_Master
    iret

IRQ_7:

    call IRQ_Master
    iret

; ---------------------------------
; IRQ 8..F
; ---------------------------------

IRQ_8:
    call IRQ_Slave
    iret

IRQ_9:

    call IRQ_Slave
    iret

IRQ_A:
    call IRQ_Slave
    iret

IRQ_B:
    call IRQ_Slave
    iret

; MOUSE IRQ
; -----------------
IRQ_C:

    pusha
    call mouse_handler
    popa
    iret

IRQ_D:
    call IRQ_Slave
    iret

IRQ_E:
    call IRQ_Slave
    iret

; Проверить вызов данного прерывания (в данном случае прерывание должно быть запрещено!)
IRQ_F:
    call IRQ_Slave    
    iret

; Задача Timer
; ------------------------------------------------------
timer_interrupt:

    cli    
    call timer_interrupt_handler ; Вызвать c-функцию обработки прерывания    

.r: jmp far 0x30:0      ; Возврат в основную задачу (0x30)   
    jmp timer_interrupt ; Продолжить цикл
