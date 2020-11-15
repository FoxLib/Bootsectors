    use32

; ЗАГЛУШКИ
; -----------------------------------------------------------------------------------

; Заглушка на шлюз прерываний
stub_interrupt:

    brk
    iret

; Заглушка на шлюз ловушки
stub_trap:

    brk
    iret

; Заглушка на IRQ с Master
stub_irq_master:

    brk
    
    mov  al, 0x20
    out  0x20, al

    iret

; Заглушка на IRQ с Slave
stub_irq_slave:

    brk
    
    mov al, 0x20
    out 0xA0, al
    out 0x20, al

    iret

; Заглушка на системное прерывание
stub_syscall:

    brk
    iret

; По умолчанию для всех остальных прерываний
user_interrupt:

    brk
    iret

; Полная остановка системы
system_fault:

    cli
    hlt
    jmp $+0    

; --------------------------------------------------------------------------------------------
; СИСТЕМНЫЕ ПРЕРЫВАНИЯ
; --------------------------------------------------------------------------------------------

int_00:

    mov ax, 0x00
    mov eax, ierr_DE
    call fatal_error    
    iret

int_01:

    mov ax, 0x01
    mov eax, ierr_DB
    call fatal_error    
    iret

int_02:

    mov ax, 0x02
    mov eax, ierr_NMI
    call fatal_error    
    iret

int_03:

    mov ax, 0x03
    mov eax, ierr_BP
    call fatal_error    
    iret

int_04:

    mov ax, 0x04
    mov eax, ierr_OF
    call fatal_error    
    iret

int_05:

    mov ax, 0x05
    mov eax, ierr_BR
    call fatal_error    
    iret

int_06:

    mov ax, 0x06
    mov eax, ierr_UD
    call fatal_error    
    iret

int_07:

    mov ax, 0x07
    mov eax, ierr_NM
    call fatal_error    
    iret

int_08:

    mov ax, 0x08
    mov eax, ierr_DF
    call fatal_error    
    iret

int_09:

    mov ax, 0x09
    mov eax, ierr_LIMC
    call fatal_error    
    iret

int_0A:

    mov ax, 0x0A
    mov eax, ierr_TSS
    call fatal_error    
    iret

int_0B:

    mov ax, 0x0B
    mov eax, ierr_NP
    call fatal_error    
    iret

int_0C:

    mov ax, 0x0C
    mov eax, ierr_SS
    call fatal_error    
    iret

int_0D:

    mov ax, 0x0D
    pop eax ; ErrorCode
    mov eax, ierr_GP
    call fatal_error    
    iret

int_0E:

    mov ax, 0x0E
    mov eax, ierr_PF
    call fatal_error    
    iret

int_0F:

    mov ax, 0x0F
    mov eax, ierr_RESV1
    call fatal_error    
    iret

int_10:

    mov ax, 0x10
    mov eax, ierr_MF
    call fatal_error    
    iret

int_11:

    mov ax, 0x11
    mov eax, ierr_AC
    call fatal_error    
    iret

int_12:

    mov ax, 0x12
    mov eax, ierr_MC
    call fatal_error    
    iret

int_13:

    mov ax, 0x13
    mov eax, ierr_XF
    call fatal_error    
    iret
