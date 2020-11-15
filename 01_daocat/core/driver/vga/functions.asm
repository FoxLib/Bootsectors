    use32

; -----------------------------
; Нарисовать прямоугольник [3 параметра dword]
; w:X1 | w:Y1
; w:X2 | w:Y2
; b:Color
; -----------------------------

VGA_rectangle:

    mov ax, SEGMENT_VGA_A
    mov es, ax
    
    ; w:Y1 w:X1
    mov eax, [esp + 0x14] 
    mov [arg0], eax
    
    ; w:Y2 w:X2
    mov ebx, [esp + 0x10] 
    mov [arg1], ebx

    ; b:Color
    mov ecx, [esp + 0x0C] 
    mov [arg2], ecx

    mov edx, [VGA_width]
    shr edx, 3
    mov [arg3], edx

    ; edx = Y1 * Screen_Width / 8
    movzx eax, word [arg0 + 2]
    mul   edx    
    mov   edx, eax   

    mov ax, bx
    mov cx, word [arg0]
    shr cx, 3
    shr bx, 3

    ; Если начало и окончание рисования по X совпадают,
    ; то нарисовать только одну линию

    sub cx, bx
    jne @vgarect_1

        ; A. Здесь получился случай, когда в одной байте идет линия
        mov cx, word [arg0 + 0]

        ; Смещение по X (слева)
        and al, 0x07 ; x2
        and cl, 0x07 ; x1
        xor cl, 0x07
        inc cl ; x1 = 8 - x1
        mov bl, 0x01
        shl bl, cl
        dec bl ; bl = 2^(8 - x1) - 1

        ; Смещение по X (справа)
        mov ah, 0x80
        mov cl, al
        sar ah, cl

        ; Получаем маску
        and ah, bl 
        mov al, ah
        call @vga_vert_line
        call vga_bit_clear
        xor  eax, eax
        ret

; Горизонтальная линия разнесена минимум на 2 байта
@vgarect_1:

    neg cx
    mov bx, cx 
    
    ; Аналогичная процедура (смещение слева)
    mov cx, word [arg0 + 0]
    and cl, 0x07
    xor cl, 0x07
    inc cl
    mov al, 0x01
    shl al, cl
    dec al

    ; Рисование левого края блока
    call @vga_vert_line
    
@vgarect_lpv: ; Цикл рисования горизонтальных блоков по 8 бит

    dec bx
    je @vgarect_end

        mov al, 0xFF
        inc edx
        call @vga_vert_line
        jmp  @vgarect_lpv

@vgarect_end:

    inc edx
    mov al, 0x80
    mov cx, word [arg1 + 0]
    and cl, 0x07
    sar al, cl
    call @vga_vert_line
    call vga_bit_clear

    xor eax, eax
    ret

; Установка битовой маски 0x0F
vga_bit_clear:

    mov  dx, 3CEh
    mov  ax, 0205h 
    out  dx, ax 
    mov  ah, 0x0F
    mov  al, 8
    out  dx, ax  
    ret

; ------------------------------------------
; Рисование вертикальной закрашенной линии
; todo (битовая маска)
; -----------------------------------------

@vga_vert_line:    

    push edx

    push dx

        mov  dx, 3CEh

        push ax
        mov  ax, 0205h 
        out  dx, ax    ; Выбор регистра Режим и одновременная установка режима 2
        pop  ax

        mov  ah, al    ; Устанавливаем битовую маску
        mov  al, 8
        out  dx, ax    ; выбор регистра "Битовая Маска" и одновременная запись маски разрешенных пикселей.
        
    pop dx

    mov al, byte [arg2]     ; Загрузим цвет
    mov cx, word [arg1 + 2]
    sub cx, word [arg0 + 2] ; Y2 - Y1
        
@vgarect_2:

    mov ah, [es:edx]
    mov [es:edx], al
    add edx, [arg3]
    dec cx
    jns @vgarect_2

    pop edx
    ret

; ------------------
; Рисуется текст
; d: string, b: color, w: X, w: Y
; ------------------
VGA_out_text:

    ; Установка видеорегистра
    mov  dx, 3CEh
    mov  ax, 0205h 
    out  dx, ax 
    
    mov eax, [esp + 0x16] 
    mov [arg0], eax ; string

    mov eax, [esp + 0x10] 
    mov [arg2], eax ; color

    mov eax, [esp + 0x12] 
    mov [arg1], eax ; x, y

    ; Теневая копия X
    mov word [arg2 + 2], ax

    ; Ширина экрана
    mov esi, [VGA_width]

    ; Пересчет смещения в знакоместе

@vgaout_recalc_char:

    mov  cl, al
    and  cl, 0x07 ; Внутренее смещение

    mov  bx, ax
    shr  bx, 3    ; Знакоместо на экране
    
    mov  ax,  word [arg1 + 2]
    mov  edx, esi
    shr  dx,  3
    mov  [arg3], edx ; edx = 80

    mul  dx
    add  bx,  ax ; bx = Y*80 + (x >> 3)

    ; Внутренние смещения по Y (начальная позиция)
    movzx edi, bx

@vgaot_symbol_next:

    mov eax,   [arg0] ; Позиция символа
    inc dword  [arg0]
    movzx eax, byte [eax]   ; Сам символ

    ; Вывод символа закончен
    and eax, eax
    je @vgaot_end

    ; Расчет позиции символа в шрифте
    lea ebx, [8*eax + eax] 
    lea eax, [2*eax]
    add ebx, eax ; eax = 11*eax 

    mov ch, 11

@vgaot_symbol8:

    ; Читаем символ
    movzx ax, byte [font6_11 + ebx]

    ; Смещение относительно 2-х байтов
    ror ax, cl
    mov dx, 3CEh

    push ax
    mov  ah, al
    mov  al, 8
    out  dx, ax  
    mov  al, byte [arg2] ; цвет (первый)
    mov  ah, [es:edi]
    mov  [es:edi], al
    pop  ax

    mov  al, 8
    out  dx, ax
    mov  al, byte [arg2] ; цвет (второй)
    mov  ah, [es:edi + 1]
    mov  [es:edi + 1], al

    inc ebx
    add edi, [arg3]
    dec ch
    jne @vgaot_symbol8

        ; Следующий символ (+6 пикселей)
        movzx eax, word [arg1] ; x
        add   eax, 6
        sub   esi, 6 ; Упреждающая проверка (чтобы символ не выходил за пределы)

        cmp eax, esi
        jb @vgaot_nonl

        ; Переход на новую линию
        mov bx, word [arg1 + 2]
        add bx, 11
        mov word [arg1 + 2], bx
        mov ax, word [arg2 + 2]

        ; Проверка по высоте во избежание переполнения
        ; Одна строка остается в запасе
        cmp bx, word [VGA_height]
        jge @vgaot_end

    @vgaot_nonl:

        add esi, 6
        mov word [arg1 + 0], ax
        jmp @vgaout_recalc_char

@vgaot_end:

    ; Код возврата 0
    xor eax, eax
    ret