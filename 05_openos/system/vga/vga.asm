; ФУНКЦИИ

; общие
;         vga_write_regs       записать данные в регистры VGA
;         get_utf8_symbol      получить следующий символ cp151 по utf-8 источнику
;         vga_set_font         переписать новый шрифт 8x16

; 640x480
;         vga_rectangle        рисование прямоугольника
;         vga_palette          установка палитры
;         vga_bit_clear        установка битовой маски

; 320x200
; --------
;         utf8_printlo         печать utf8-строки в 320x200 режиме

; text
; --------

;        cursor_set (bh,bl)

        ; Параметры видеорежимов и сами видеорежимы
        include 'vgamodes.asm'

        ; Системные шрифты
        ; include 'font_8x8.asm'
        include 'font_8x8_rus.asm'

; Контроллер атрибутов
VGA_AC_INDEX         EQU 0x3C0
VGA_AC_WRITE         EQU 0x3C0
VGA_AC_READ          EQU 0x3C1

VGA_MISC_WRITE       EQU 0x3C2
VGA_SEQ_INDEX        EQU 0x3C4
VGA_SEQ_DATA         EQU 0x3C5

VGA_DAC_READ_INDEX   EQU 0x3C7
VGA_DAC_WRITE_INDEX  EQU 0x3C8
VGA_DAC_DATA         EQU 0x3C9

VGA_MISC_READ        EQU 0x3CC
VGA_GC_INDEX         EQU 0x3CE
VGA_GC_DATA          EQU 0x3CF

;                    COLOR   MONO emulation
VGA_CRTC_INDEX       EQU 0x3D4 ; 0x3B4 
VGA_CRTC_DATA        EQU 0x3D5 ; 0x3B5 
VGA_INSTAT_READ      EQU 0x3DA

; Количество регистров
VGA_NUM_SEQ_REGS     EQU 5
VGA_NUM_CRTC_REGS    EQU 25
VGA_NUM_GC_REGS      EQU 9
VGA_NUM_AC_REGS      EQU 21
VGA_NUM_REGS         EQU (1 + VGA_NUM_SEQ_REGS + VGA_NUM_CRTC_REGS + VGA_NUM_GC_REGS + VGA_NUM_AC_REGS)

; Записать регистры
; --------------------------------------------------------------------------------
vga_write_regs:

        mov edi, esi

        mov dx, VGA_MISC_WRITE
        lodsb
        out dx, al

        ; --- write SEQUENCER regs ----
        xor ebx, ebx

        ; кол-во регистров SEQUENCER
        mov ecx, VGA_NUM_SEQ_REGS 
@@:     outb VGA_SEQ_INDEX, bl
        lodsb
        outb VGA_SEQ_DATA, al
        inc ebx
        loop @b

        ; Разблокируем CRTC регистры
        outb VGA_CRTC_INDEX, 0x03
        inb VGA_CRTC_DATA
        or  al, 0x80
        out dx, al

        ; --
        outb VGA_CRTC_INDEX, 0x11
        inb VGA_CRTC_DATA
        and al, 0x7F
        out dx, al

        ; Оставим их разблокированными
        or  [edi + 0x03], byte 0x80
        and [edi + 0x11], byte 0x7F

        ; --- write CRTC regs ---
        xor ebx, ebx
        mov ecx, VGA_NUM_CRTC_REGS
@@:     outb VGA_CRTC_INDEX, bl
        lodsb
        outb VGA_CRTC_DATA, al
        inc ebx
        loop @b

        ; -- write GRAPHICS CONTROLLER regs --
        mov ecx, VGA_NUM_GC_REGS
        xor ebx, ebx
@@:     outb VGA_GC_INDEX, bl
        lodsb
        outb VGA_GC_DATA, al
        inc ebx
        loop @b

        ; --- Записать ATTRIBUTE CONTROLLER регистры ---
        mov ecx, VGA_NUM_AC_REGS

        xor ebx, ebx
@@:     inb VGA_INSTAT_READ
        outb VGA_AC_INDEX, bl
        lodsb
        outb VGA_AC_WRITE, al
        inc ebx
        loop @b

        ; --- Заблокировать 16-color палитру и разблокировать дисплей ---
        inb  VGA_INSTAT_READ
        outb VGA_AC_INDEX, 0x20
        ret

; Перезаписать шрифт в текстовом режиме (esi-источник)
; ------------------------------------------------------------------------------------------------
vga_set_font:

        ; @TODO ...

        ret

; Палитра EBX CI:R:G:B
; ------------------------------------------------------------------------------------------------
vga_palette:

        push eax ebx edx
        mov eax, ebx
        mov dx, 0x3C8
        rol eax, 8
        out dx, al
        inc dx

        rol eax, 8
        out dx, al ; R
        rol eax, 8
        out dx, al ; G   
        rol eax, 8
        out dx, al ; B

        pop edx ebx eax
        ret

; ------------------------------------------------------------------------------------------------
; Нарисовать прямоугольник [3 параметра dword]
; par1 X1
; par2 Y1
; par3 X2
; par4 Y2
; par5 Color
; ----

vga_rectangle:

        create_frame 4

        ; EDX = Y1 * Screen_Width / 8
        mov eax, 80
        mul dword [par2]
        mov edx, eax

        ; EDX += X1 / 8
        mov eax, [par1]
        shr eax, 3
        add edx, eax 

        mov ebx, [par1] ; X1
        mov ecx, [par3] ; X2
        shr cx, 3
        shr bx, 3

        ; Если начало и окончание рисования по X совпадают,
        ; то нарисовать только одну линию

        sub bx, cx ; X1 - X2 = 0 ?
        jne .vgarect

        ; A. Здесь получился случай, когда в одной байте идет линия
        mov ecx, [par1] ; X1
        mov eax, [par3] ; X2

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
        call .vga_vert_line
        call vga_bit_clear

        xor  eax, eax
        leave
        ret

; Горизонтальная линия разнесена минимум на 2 байта
.vgarect:

        ; bx = x2 - x1
        neg bx

        ; Аналогичная процедура (смещение слева)
        mov cx, word [par1]
        and cl, 0x07
        xor cl, 0x07
        inc cl
        mov al, 0x01
        shl al, cl
        dec al

        ; Рисование левого края блока
        call .vga_vert_line

.vgarect_lpv: ; Цикл рисования горизонтальных блоков по 8 бит

        dec bx
        je .vgarect_end

        mov al, 0xFF
        inc edx
        call .vga_vert_line
        jmp  .vgarect_lpv

.vgarect_end:

        inc edx
        mov al, 0x80
        mov cx, word [par3]
        and cl, 0x07
        sar al, cl
        call .vga_vert_line
        call vga_bit_clear

        xor eax, eax
        leave
        ret

; ------------------------------------------
; Рисование вертикальной закрашенной линии
; al = битовая маска)
; edx = 0..n байты
; -----------------------------------------

.vga_vert_line:    

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

        mov al, byte [par5] ; AL = цвет
        mov cx, word [par4]
        sub cx, word [par2] ; Y2 - Y1
       
; Рисование линии
; ---------------
 
@@:     mov ah, [es:edx + 0xA0000] ; Прочитать для того, чтобы сработала "Защелка"
        mov [es:edx+ 0xA0000], al  ; Записать новый байт
        add edx, 80
        dec cx
        jns @b

        pop edx
        ret

; Установка битовой маски 0x0F
; -------------------------------------------
vga_bit_clear:

        mov  dx, 3CEh
        mov  ax, 0x0205 ; 05h = Регистр режима, 2
        out  dx, ax 

        mov  ax, 0xFF08 ; 08h = Битовая маска 0xFF
        out  dx, ax  
        ret

; Видеорежим низкого разрешения
; ================================================================================

; Параметры (char* source, uint x, uint y, uint color)
; --------------------------------------------------------------------------------
utf8_printlo:

        enter 0, 0
        pusha

        xor  eax, eax
        mov  esi, [par1]

        mov  bl, [par2] ; X
        mov  bh, [par3] ; Y
        mov  ah, [par4] ; C

.loop:  ; Чтение символа
        call get_utf8_symbol
        and  al, al
        je   .break

        call put_char_low
        jmp .loop

.break: popa
        leave
        ret 0x10

; Печать символа в Teletype-режиме
; AH(цвет) AL(char) BH(Y) BL(X)
; -------------------------------------------------------------------------------
put_char_low:

        push  eax ebx ecx edx esi edi

        movzx edi, bh
        imul  edi, 320 * 8
        and   ebx, 0x00FF
        shl   bx, 3
        add   edi, ebx
        add   edi, 0xA0000

        ; Расчет позиции следующего символа
        push  eax
        and   eax, 0x00FF
        lea   esi, [VGA_FONT_8x8_FIXED + 8*eax]
        pop   eax

        mov   ch, 8    ; 8 строк
        
.symbolh: ; Получение битовой маски

        lodsb
        mov   cl, 8      
.symbolw: ; Печать битовой маски

        test  al, 0x80
        je    @f        
        mov   [es:edi], ah
@@:     inc   edi
        shl   al, 1
        dec   cl
        jne .symbolw

        ; К следующей строке
        sub   di, 8
        add   di, 320      
        dec   ch
        jne   .symbolh        

        ; Восстановление значений
        pop   edi esi edx ecx ebx eax 

        ; X++, если превысит - то Y++, X=0
        inc   bl
        cmp   bl, 40
        jne @f
        mov   bl, 0
        inc   bh
@@:        
        ret

; Установка курсоа в (BH, BL)
; -------------------------------------------------------------------------------
cursor_set:

        mov al, bh
        mov ah, 80
        mul ah             ; ax = bh * 80
        add al, bl
        adc ah, 0          ; ax = 80*bh + bl
        mov bx, ax

        mov al, 0x0f
        mov dx, 0x3d4
        out dx, al

        mov al, bl
        inc dx
        out dx, al         ; Установить LO байт

        dec dx
        mov al, 0x0e
        out dx, al

        mov al, bh
        inc dx
        out dx, al         ; Установить HI байт

        ret

; Получить [ds:esi] символ utf8 -> cp1251
; -------------------------------------------------------------------------------
get_utf8_symbol:

        push bx

.retry:
        lodsb
        test al, 0x80
        je .ok
        
        cmp al, 0xD0 ; Если символ начинается на D0
        je .d0
        cmp al, 0xD1 ; Если символ начинается на D1
        je .d1

        ; Остальные недействительны: искать первый правильный символ
@@:     jmp .retry      

        ; -----------------------------------
.d0:    ; D0 (90-BF)
        lodsb
        mov  bl, al
        and  bl, 0xF0
        cmp  bl, 0x90 ; диапазон 9x-Ax
        je .d0_90a0
        cmp  bl, 0xA0 
        je .d0_90a0
        cmp  bl, 0xB0 ; диапазон Bx
        je .d0_90a0
        cmp  bl, 0x80 ; Ё
        je .d80
        jmp .ok

.d0_90a0:

        add al, 0x30 ; Коррекция 90h..BFh -> C0h..EFh
        jmp .ok

        ; замена Ё на "Е"
.d80:   mov al, 0xC5
        jmp .ok

        ; -----------------------------------
.d1:    ; D1 (80-8F)    
        lodsb
        cmp al, 0x91 ; буква ё?
        jne @f
        mov al, 0xe5
        jmp .ok

@@:     add al, 0x70 ; 80h -> E0h
.ok:    pop bx
        ret