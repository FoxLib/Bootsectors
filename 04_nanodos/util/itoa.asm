
; ----------------------------------------------------------------------
; Преобразование EAX к десятичному виду
; ds:si - Указатель на полученную строку
; ----------------------------------------------------------------------

util.itoa:

        push    eax ebx cx edx
        mov     cx, 10
        mov     si, util.itoa.buffer + 9
        mov     [si + 1], byte 0
        mov     [si], byte '0'            
        mov     ebx, 10
@@:     and     eax, eax
        je      .zerotail        
        cdq
        idiv    ebx
        add     dl, '0'
        mov     [si], dl
        dec     si
        jmp     @b
        
.zerotail:

        ; Случай, если в буфере =0, оставить так
        cmp     si, util.itoa.buffer + 9
        je      .stayzero
        inc     si

.stayzero:

        pop    edx cx ebx eax
        ret    
