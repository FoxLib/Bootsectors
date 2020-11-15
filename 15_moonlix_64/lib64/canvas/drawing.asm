include 'font/lucida12.asm'

; Прототипы функции
;
; canvas_cls(color=rax)
; canvas_pixel(x=rax,y=rbx,color=rcx)
; canvas_monotext(x,y,c,char*)
; print_10num(number,char*)
; canvas_block(x,y,w,h,color)
; ----------------------------------------------------------

; [vesa_ptr] -- lib64/vesa.asm

; rdi = 3*rdi или 4*rdi в зависимости от видеорежима
adjust_rdi:

    cmp  [vesa_bit], 24
    je .br24
    lea  rdi, [4*rdi]
    ret

.br24:
    lea  rdi, [2*rdi + rdi]
    ret

; ----------------------------------------------------------
; На вход eax - RGB0 (цвет). Цвета расположены так
; AL(Blue), AH(Green), A16..23(Red)
; Полностью очищается область экрана
; ----------------------------------------------------------

canvas_cls:

    ; Вычисляем размер экрана
    mov  rdi, [vesa_ptr]
    mov  rcx, [vesa_w]
    imul rcx, [vesa_h]

    ; Для 24-х битного режима другое
    cmp [vesa_bit], 24
    je .bit24

    rep stosd
    ret

.bit24:

    stosw
    ror eax, 16
    stosb
    ror eax, 16
    loop .bit24

    ret    

; rax(x), rbx(y), rcx(color)
; -----------------------------------------------------------------------------------------------------------------------------

canvas_pixel:

    mov  rdx, [vesa_w]
    imul rdx, rbx
    add  rax, rdx ; rdx = vesa_w*y + x

    cmp [vesa_bit], 24
    je .bit24

    mov rdi, [4*rax]
    add rdi, [vesa_ptr]
    mov eax, ecx
    stosd
    ret

.bit24:

    lea rdi, [rax + 2*rax] ; rax = 3*rax
    add rdi, [vesa_ptr] 
    mov eax, ecx
    stosw
    ror eax, 16
    stosb
    ret    

; rax(x), rbx(y), rcx(color), rsi(текст)
; -----------------------------------------------------------------------------------------------------------------------------

canvas_monotext:

    enter 8, 0
    saveall

    mov  rax, [par1]
    mov  rbx, [par2]
    mov  rcx, [par3]
    mov  rsi, [par4]

.loop:

    ; rdi = [3|4] * (vesa_w*y + x)
    mov  rdi, [vesa_w]
    imul rdi, rbx
    add  rdi, rax
    call adjust_rdi

    ; x,y сохраняем
    push rax rbx
    
    ; utf-8
    xor rax, rax
    lodsb

    test al, 0x80
    je .ascii_char

    ; Определение русского шрифта в UTF8
    cmp al, 0xD0
    je .rus_char_D0
    cmp al, 0xD1
    je .rus_char_D1
    jmp .invalid_char

; Догружаем еще букву для определения русского шрифта
.rus_char_D0:
    
    lodsb 
    sub al, 0x10
    jmp .ascii_char

.rus_char_D1:

    lodsb
    cmp al, 0xA0
    jnb @f
    add al, 0x20
@@: add al, 0x10
    jmp .ascii_char

    ; ... русский символ

; Неправильный символ = "пробел"    
.invalid_char:

    mov al, 0x20   

.ascii_char:

    ; Сохраним RSI позицию
    push rsi

    and al, al
    je .exit

    sub  al, 0x20 ; начинается с 32-го символа
    imul rax, 11  ; 11 байт на каждый символ
    mov  rsi, lucida12
    add  rsi, rax ; rsi = lucida12 + 11*(char - 32)

    ; Рисование символа
    call .put_symbol

    ; К следующему символу
    pop rsi rbx rax
    add rax, 7

    jmp .loop

.exit:

    pop rsi rbx rax
    loadall
    leave
    ret

; -- нарисовать символ --
.put_symbol:

    push rdi rsi rax rbx rdx

    ; Параметры: RSI - источник, RDI - видеопамять, RCX - цвет    
    xor rdx, rdx
    add rdi, [vesa_ptr]
    mov dh, 11

.loop_y:

    mov dl, 8
    lodsb

    push rdi

.loop_x:

    push rdi

    bt  ax, 7
    jnb .no_pixel

    ; Рисование пикселя цвета RCX (24/32)
    ; -----------------------------
    push rax
    mov  rax, rcx
    stosw
    ror eax, 16
    stosb
    cmp [vesa_bit], 24
    je @f
    xor eax, eax
    stosb
@@: pop rax
    ; -----------------------------

.no_pixel:

    pop rdi

    ; +3/4 байта
    cmp [vesa_bit], 24
    je @f
    inc rdi
@@: add rdi, 3

    ; Сканируем следующий бит
    shl al, 1
    dec dl
    jne .loop_x
    pop  rdi

    ; К следующей строке
    push rdx    
    mov  rdx, [vesa_w]

    cmp [vesa_bit], 24
    jne .bit24
    lea rdx, [2*rdx + rdx]
    jmp .nline
.bit24:
    lea rdx, [4*rdx]
.nline:

    add rdi, rdx
    pop rdx
    
    dec dh
    jne .loop_y

    pop rdx rbx rax rsi rdi
    ret    


; Печать числа rax в rdi (учитывается и знак)
; число(par1) указатель(par2)
; -----------------------------
print_10num:

    enter 0x32, 0
    saveall

    mov  rax, [par1]
    mov  rdi, [par2]

    and  rax, rax
    jne @f
    mov  ax, '0'
    stosw

    jmp .exit_pn
    

@@: push rdi
    mov  rdi, rbp
    sub  rdi, 32

    mov  rcx, 20 ; 20 символов
    mov  rbx, 10

@@: xor  rdx, rdx
    div  rbx
    push rax
    mov  al, dl
    or   al, 0x30
    stosb
    pop  rax
    loop @b

    mov  rsi, rdi
    pop  rdi
    dec  rsi

    xor  rdx, rdx
    mov  rcx, 20

    ; Выдаем результат и срезаем лидирующие нули dl=0/1

.loop:

    std
    lodsb
    cld

    cmp dl, 1
    je @f
    cmp al, '0'
    je .zeros
    mov dl, 1    
@@: stosb
.zeros:
    loop .loop

    ; Пишется EOL
    mov al, 0
    stosb

.exit_pn:

    loadall
    leave
    ret

; Рисование блока
; -----------------------------------------------------------------------------------------------------------------------------
; x(par1), y(par2), w(par3), h(par4), color(par5)

canvas_block:

    enter 8, 0
    saveall

.loop_y:

    mov  rdi, [vesa_w]
    imul rdi, qword [par2]
    add  rdi, [par1]
    call adjust_rdi
    add  rdi, [vesa_ptr]
   
    mov  rcx, [par3]    

.loop_x:

    mov  rax, [par5]
    stosw
    ror eax, 16
    stosb
    cmp [vesa_bit], 24
    je @f
    mov al, 0
    stosb
@@: loop .loop_x

    inc qword [par2]
    dec qword [par4]
    jne .loop_y

    loadall
    leave
    ret

; Нарисовать иконку
; x(par1) y(par2) char*(par3)
; -----------------------------------------------------------------------------------------------------------------------------
canvas_ico:

    enter 0,0
    saveall

    ; mov rdi, [vesa_ptr]
    mov  rdi, [vesa_w]
    imul rdi, qword [par2]
    add  rdi, qword [par1]
    call adjust_rdi
    add  rdi, [vesa_ptr]  ; rdi = vesa_ptr + (3|4)*(vesa_w*y + x)

    mov  rsi, [par3]

    ; 6  - заголовок
    ; 12 -Указывает абсолютное смещение растра в файле.
    
    mov  dx,  [rsi + 6] ; dl=width, dh=height
    mov  bx,  dx

    ; Так как изображение перевернутое в ICO, то добавляем +height пикселей
    push rdx
    mov  dl, dh
    and  rdx, 0xFF
    imul rdx, [vesa_w]
    cmp  [vesa_bit], 24
    je  @f
    lea rdx, [rdx*4]
    jmp .bit24
@@: lea rdx, [rdx*2 + rdx]     
.bit24:
    add  rdi, rdx
    pop  rdx

    mov  rax, [rsi + 6 + 12]
    and  rax, 0x7fffffff
    lea  rsi, [rsi + rax + 40] ; +40 неизвестно зачем    

.loop_y:

    mov  dl, bl
    push rdi

.loop_x:

    call .alpha

    cmp [vesa_bit], 24
    je @f
    inc edi
@@: dec dl
    jne .loop_x

    ; на следующую строку
    mov rdi, qword [vesa_w]
    call adjust_rdi
    mov rax, rdi

    pop rdi
    sub rdi, rax

    dec dh
    jne .loop_y

    loadall
    leave
    ret

; -- [esi] - входящий, [edi] - символ до этого ---
.alpha:

    push rbx rcx rdx
;brk
    xor  rax, rax
    xor  rbx, rbx
    xor  rcx, rcx    

    mov  dl, 3
    mov  cl, [rsi + 3]   

.loop_rgb:

    mov   al, [rsi]
    movzx ax, al

    mov   bl, [rdi]
    
    push  dx
    mul   cx
    push  ax
    movzx ax, bl
    xor   cl, 0xff
    mul   cx
    pop   bx
    add   ax, bx

    mov [rdi], ah ; результат 
    inc rsi
    inc rdi
    pop dx

    xor   cl, 0xff
    dec dl
    jne .loop_rgb

    inc  rsi
    pop  rdx rcx rbx

    ret    

; Копирование области экрана в блок
; x(par1), y(par2), w(par3), h(par4), char*(par5)
; -----------------------------------------------------------------------------------------------------------------------------
copy_to_block:

    enter 0, 0
    saveall   

    cld
    mov  rdi, [par5]

 .loop_y:

    push rdi
    mov  rdi, [par2]
    imul rdi, [vesa_w]
    add  rdi, [par1]
    call adjust_rdi  ; rdi=(vesa_w*y + x)*factor(3|4)
    mov  rsi, rdi
    add  rsi, [vesa_ptr]

    ; Копирование скан-лайна
    mov  rcx, [par3]
    cmp [vesa_bit], 24
    je .bit24
    lea rcx, [rcx*4]
    jmp @f
.bit24:    
    lea rcx, [rcx*2 + rcx]
@@: pop rdi
    rep movsb    

    inc qword [par2]
    dec qword [par4]
    jne .loop_y

    loadall
    leave
    ret    

; Копирование из блока в область экрана
; x(par1), y(par2), w(par3), h(par4), char*(par5)
; -----------------------------------------------------------------------------------------------------------------------------

copy_from_block:

    enter 0, 0
    saveall

    cld
    mov  rsi, [par5]

 .loop_y:

    push rsi
    mov  rdi, [par2]
    imul rdi, [vesa_w]
    add  rdi, [par1]
    call adjust_rdi  ; rdi=(vesa_w*y + x)*factor(3|4)
    add  rdi, [vesa_ptr]

    ; Копирование скан-лайна
    mov  rcx, [par3]
    cmp [vesa_bit], 24
    je .bit24
    lea rcx, [rcx*4]
    jmp @f
.bit24:    
    lea rcx, [rcx*2 + rcx]
@@: pop rsi
    rep movsb    

    inc qword [par2]
    dec qword [par4]
    jne .loop_y

    loadall
    leave
    ret    

; Отправить данные из bk-буфера в vesa_real память PCI
; --------------------------------------------------------------------------------------------------------------------

bk2front:

    push rsi rdi
    mov  rsi, [vesa_ptr]
    mov  rdi, [vesa_real]
    mov  rcx, 0x300000 shr 3
    rep  movsq
    pop  rdi rsi
    ret

; --------------------------------------------------------------------------------------------------------------------
; VGA
; --------------------------------------------------------------------------------------------------------------------

vga13_cls:

    ; Очистка экрана
    mov rdi, 0xA0000
    mov rcx, 320*200
    rep stosb

    ; Установка разрешения экрана
    mov word [vesa_w], 320 
    mov word [vesa_h], 200
    mov byte [vesa_bit], 8 ; 1 байт!
    ret    