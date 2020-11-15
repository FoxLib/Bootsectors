; Процедуры для текстового быстрого вывода
; 
; b8_put_char(x,y,char,attr)
; b8_put_block(x,y,w,h,char,attr)
; -----------------------------------------------------------------------------------------

; Записать символ в видеопамять
; uint32_t x (1), uint8_t y (2), uint8_t chr (3), uint8_t attr (4)
b8_put_char:
   
    push ebp
    mov  ebp, esp

    call b8_overlimit_test    
    jb .fin

    mov  eax, [ebp + par1]
    mov  ebx, [ebp + par2]
    call b8_calc_xy

    mov  bl,  [ebp + par3]
    mov  bh,  [ebp + par4]
    mov  [gs:edx], bx

.fin:
    leave
    ret

; Рисовать блок
; x (1), y (2), w (3), h(4), char(5), attr(6)
; -------------------
b8_put_block:

    push ebp
    mov  ebp, esp

    call b8_overlimit_test
    jb .fin
    
    mov  ebx,  [ebp + par2]

.loop_y:

    mov  eax,  [ebp + par1]    
    mov  ecx,  [ebp + par3]

.loop_x:

    ; Рассчитать координаты
    call b8_calc_xy

    push ebx
    mov  bl, [ebp + par5]
    mov  bh, [ebp + par6]
    mov  [gs:edx], bx
    pop  ebx

    inc  eax         ; x++
    cmp  ax, 80
    jnb .next_line 

    dec ecx
    jne .loop_x 

.next_line:

    ; Отрисовка окна вниз закончилась?
    dec dword [ebp + par4] ; y--
    je .fin

    ; Пока не будет предел 50 символов
    inc ebx
    cmp ebx, 50
    jb  .loop_y

.fin:
    leave
    ret    



; Вспомогательные функции
; -----------------------------------------------------------------------------------------

; cf=1 если границы превышены
b8_overlimit_test:

    ; Проверка на превышение границ
    cmp  [ebp + par1], dword 80
    jnb .stc
    cmp  [ebp + par2], dword 50
    jnb .stc
    clc 
    ret

.stc: 
    stc   
    ret

; edx = (eax[x] + ebx[y]*80) * 2
b8_calc_xy:

    push eax ebx    
    
    push eax
    mov  eax, 80
    mul  ebx
    pop  edx
    add  edx, eax ; edx = 80*y + x
    add  edx, edx 
    add  edx, 0x18000

    pop  ebx eax
    ret
