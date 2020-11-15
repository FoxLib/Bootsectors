; Функции для быстрого доступа к портам и вводу-выводу
; ----------------------------------------------------

; out (dx), al
; outb(dx, al)
outb:

    push ebp
    mov  ebp, esp
    push edx eax
    mov  dx, [ebp + 4 + 4]
    mov  al, [ebp + 8 + 4]
    out  dx, al
    pop  eax edx
    pop  ebp
    ret

; outb(dx, al)
; result - eax
inb:

    push ebp
    mov  ebp, esp
    push edx
    mov  dx, [ebp + 4 + 4]
    xor  eax, eax
    in   al,  dx
    pop  edx
    pop  ebp
    ret    

; Я думаю, что это вообще не нужно, ибо C делает очень
; много инструкции, пока входит в процедуру
io_wait:

    jcxz      $+2
    jcxz      $+2
    ret

; Функции доступа к памяти
; ---------------------------------------------

; Прочитать из памяти (fs:ptr) значение -> eax
; read(uint32 ptr)
read:

    push ebp
    mov  ebp, esp
    mov  eax, [ebp + 8]
    mov  eax, [fs:eax]
    pop  ebp
    ret

; Чтение байта
readb:

    push  ebp
    mov   ebp, esp
    mov   eax, [ebp + 8]
    movzx eax, byte [fs:eax]
    pop   ebp
    ret

read_gs: 

    push ebp
    mov  ebp, esp
    mov  eax, [ebp + 8]
    mov  eax, [gs:eax]
    pop  ebp
    ret

; Записать в память dword
; write(uint32 ptr, uint8 value) FS
write:    

    push ebp    
    mov  ebp, esp
    push edx
    mov  eax, [ebp + 12] ; ptr
    mov  edx, [ebp + 8] ; value 32
    mov  [fs:edx], eax
    pop  edx
    pop  ebp
    ret

; ptr, al
; [gs:edx], al
writeb_gs:

    push ebp    
    mov  ebp, esp
    push edx
    mov  eax, [ebp + 12] ; ptr
    mov  edx, [ebp + 8] ; value 8
    mov  [gs:edx], al
    pop  edx
    pop  ebp
    ret

; write_gs(uint32_t ptr, uint32_t value)
write_gs:

    push ebp    
    mov  ebp, esp
    push edx
    mov  eax, [ebp + 12] ; ptr
    mov  edx, [ebp + 8]  ; value 32
    mov  [gs:edx], eax
    pop  edx
    pop  ebp
    ret

; -------------------------------------------------------------------------------------------------------

; Записать байт
; @param fs:KPTR, 
; @param byte
writeb:

    push ebp    
    mov  ebp, esp
    push edx
    mov  al,  [ebp + 12] 
    mov  edx, [ebp + 8]  
    mov  [fs:edx], al
    pop  edx
    pop  ebp
    ret

; Очистка памяти (addr, count, dword value) 
repstosd:

    push ebp
    mov  ebp, esp
    
    push es 
    mov  ax, fs
    mov  es, ax

    mov  edi, [ebp + 0x8]  ; ptr
    mov  ecx, [ebp + 0x0c] ; count
    mov  eax, [ebp + 0x10] ; value       
    rep  stosd

    pop es
    pop ebp
    ret

; Инициализация CR3
; ---------------------------------------------
cr3_load:

    push ebp
    mov  ebp, esp
    push eax

    mov  eax, [ebp + 8] ; 
    mov  cr3, eax    

    ; Включить Paging
    mov  eax, cr0
    or   eax, 0x80000000
    mov  cr0, eax

    jmp @f
@@: pop eax
    pop ebp
    ret
