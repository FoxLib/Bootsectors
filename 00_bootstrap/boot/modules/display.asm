; ----------------------------------------------------------------------
; Просто очистка экрана от всего лишнего
; ax - данные для очистки 

display_clear:

    push    ax
    mov     ax, $0003
    int     $10
    
    ; Очистка в цвет
    mov     bx, $B800
    mov     es, bx
    pop     ax
    xor     di, di
    mov     cx, 2000
    rep     stosw    
    
    ; Убрать курсор за экран
    mov     ah, 02h
    mov     bh, 0
    mov     dx, 0x2000
    int     0x10    
    
    ret

; ----------------------------------------------------------------------
; di = 2*(80*ah + al)

ax2di:

    push    bx cx
    movzx   bx, ah
    movzx   ax, al
    imul    di, bx, 80
    add     di, ax
    add     di, di
    pop     cx bx
    ret    

; ----------------------------------------------------------------------
; Рисовать "рамку" (ah,al)-(bh,bl)

display_paintfm: 

    mov     [.x1y1], ax
    mov     [.x2y2], bx
    
    ; di = (80*ah + al)<<1
    call    ax2di

    ; Сохранить этот адрес   
    push    di
    
    ; cl = x2 - x1
    mov     cl, byte [.x2y2]
    sub     cl, byte [.x1y1]
    sub     cl, 1
    movzx   cx, cl
    mov     [.w], cx
    
    ; Рисовать верхнюю часть
    mov     al, [.sym + 0]
    stosb
    inc     di
    mov     al, [.sym + 1]
@@: stosb
    inc     di
    loop    @b
    mov     al, [.sym + 2]
    stosb

    ; Расчет количества повторений по вертикали
    mov     cl, byte [.x2y2 + 1]
    sub     cl, byte [.x1y1 + 1]
    sub     cl, 2
    mov     [.h], cx

    ; Используем для циклического повтора
    pop     di

    ; Вертикальные полосы
@@: add     di, 160
    push    cx di
    mov     al, [.sym + 3]
    stosb
    inc     di
    mov     cx, [.w]
    add     cx, cx
    add     di, cx    
    stosb
    pop     di cx
    loop    @b
    
    ; Нижняя линия
    add     di, 160
    mov     cx, [.w]
    mov     al, [.sym + 4]
    stosb
    inc     di
    mov     al, [.sym + 1]
@@: stosb
    inc     di
    loop    @b
    mov     al, [.sym + 5]
    stosb
    ret

; Данные дя рисования рамок
.x1y1 dw 0 ; x1, y1
.x2y2 dw 0 ; x2, y2
.w    dw 0 ; width
.h    dw 0 ; height

; Псевдографика для рисования
.sym  db $C9, $CD, $BB
      db $BA, $C8, $BC

; ----------------------------------------------------------------------
; ax - (y,x)
; ds:si - строка sz

display_printsz:

    ; di = ah*160 + al*2
    call    ax2di
    
@@: lodsb
    and     al, al
    je      .quit
    
    stosb
    inc     di
    jmp     @b
    
.quit:

    ret

; ----------------------------------------------------------------------
; ax = (y,x), cx = lines

display_hline:

    call    ax2di
    sub     cl, 2
    mov     al, [.sym + 0]
    stosb
    add     di, 159
    mov     al, [.sym + 1]
@@: push    di
    stosb
    pop     di
    add     di, 160
    loop    @b
    mov     al, [.sym + 2]
    stosb
    ret
    
.sym db $D1, $B3, $CF
