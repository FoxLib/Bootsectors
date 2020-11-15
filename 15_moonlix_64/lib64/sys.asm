; Очистка регистров и памяти
; ---------------------------------
xored:

    xor rax, rax
    xor rdx, rdx

    mov rdi, HEAP_INDEX

    ; Вычисляется количество памяти для очистки
    mov ecx, dword [MEMORY_SIZE]
    sub ecx, HEAP_INDEX
    shr ecx, 3

    rep stosq

    xor rbx, rbx
    xor rsi, rsi
    xor rdi, rdi
    xor rbp, rbp
    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r11, r11
    xor r12, r12
    xor r13, r13
    xor r14, r14
    xor r15, r15
    ret        

; Включение поддержки SSE
; ---------------------------------
enable_sse:

    mov eax, 1
    cpuid
    and edx, 1 shl 26
    je .sse_not_support

    ; https://en.wikipedia.org/wiki/Control_register
    mov rax, cr4
    or  ax,  1 shl 9
    mov cr4, rax
    ret

; Выдать ошибку, что SSE не поддерживается
.sse_not_support:
    jmp $    


; Инициализация RTC-таймера (задача ядра)
timer_clock_1000hz:

    mov al, 0x34
    out 0x43, al

    mov al, 0xA9
    out 0x40, al ; lsb
    mov al, 0x04
    out 0x40, al ; msb    

    ret