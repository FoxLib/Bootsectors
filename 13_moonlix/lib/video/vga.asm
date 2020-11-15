; Прикладное использование
; int 32 bit
; ---
; VGA_rectangle        (x1,x2,y1,y2,color)
; VGA_palette          EBX CI:R:G:B
; VGA_bit_clear        Установка битовой маски 0x0F
; VGA_12
; VGA_13
; VGA_write_regs
; --------------------------------------------------
; vga_rectangle(int x1, int y1, int x2, int y2, int color)
; vga_print_mono(int x, int y, char* sz, char color) печать моноширинной строки на экране
; --------------------------------------------------

include 'vgamodes.asm'

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

; Видеорежим
; --------------------------------------------------------------------------------

; Видеорежим 640x480x16
; ----------------------------
vga_12:

    ; Установка видеорежима
    mov esi, VGA_MODE_640x480
    call VGA_write_regs

    ; Сброс битовой карты
    call VGA_bit_clear

    ; Очистка экрана от "мусора" в 0x00
    mov edi, 0x000A0000
    mov ecx, 80*480   
    mov al,  0x00

@@:   
    mov ah, [es:edi]
    mov [es:edi], al
    inc edi
    loop @b
    ret

; Видеорежим 320 x 200 x 256
; ----------------------------
vga_13:

    mov esi, VGA_MODE_320x200
    call VGA_write_regs

    xor eax, eax
    mov edi, 0xA0000
    mov ecx, 65536 / 4
    rep stosd

    ret

; Записать регистры
; --------------------------------------------------------------------------------
VGA_write_regs:

    mov edi, esi

    mov dx, VGA_MISC_WRITE
    lodsb
    out dx, al

    ; --- write SEQUENCER regs ----
    xor ebx, ebx
    mov ecx, VGA_NUM_SEQ_REGS ; кол-во регистров SEQUENCER
@@: outb VGA_SEQ_INDEX, bl
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
@@: outb VGA_CRTC_INDEX, bl
    lodsb
    outb VGA_CRTC_DATA, al
    inc ebx
    loop @b

    ; -- write GRAPHICS CONTROLLER regs --
    mov ecx, VGA_NUM_GC_REGS
    xor ebx, ebx
@@: outb VGA_GC_INDEX, bl
    lodsb
    outb VGA_GC_DATA, al
    inc ebx
    loop @b

    ; --- Записать ATTRIBUTE CONTROLLER регистры ---
    mov ecx, VGA_NUM_AC_REGS

    xor ebx, ebx
@@: inb VGA_INSTAT_READ
    outb VGA_AC_INDEX, bl
    lodsb
    outb VGA_AC_WRITE, al
    inc ebx
    loop @b

    ; --- Заблокировать 16-color палитру и разблокировать дисплей ---
    inb  VGA_INSTAT_READ
    outb VGA_AC_INDEX, 0x20
    ret

; Палитра EBX CI:R:G:B
; ------------------------------------------------------------------------------------------------
VGA_palette:

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
    call VGA_bit_clear

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
    call VGA_bit_clear

    xor eax, eax
    leave
    ret

; ------------------------------------------
; Рисование вертикальной закрашенной линии
; al  = битовая маска
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
 
@@: mov ah, [es:edx + 0xA0000] ; Прочитать для того, чтобы сработала "Защелка"
    mov [es:edx+ 0xA0000], al  ; Записать новый байт
    add edx, 80
    dec cx
    jns @b

    pop edx
    ret

; Установка битовой маски 0x0F
; -------------------------------------------
VGA_bit_clear:

    mov  dx, 3CEh
    mov  ax, 0x0205 ; 05h = Регистр режима, 2
    out  dx, ax 

    mov  ax, 0xFF08 ; 08h = Битовая маска 0xFF
    out  dx, ax  
    ret

; Печать строки 
; vga_print_mono(int x, int y, char* sz, int color)
; ----------------------------------------------------------------------
vga_print_mono:

    create_frame 4

    ; подготовить к процедуре
    call VGA_bit_clear

    ; edi = 0xa0000 + y*80 + x
    mov  edi, 0xA0000
    imul di, [par2], 80
    add  di, [par1]

    mov  esi, [par3] ; esi - строка

.loopk:

    xor eax, eax
    lodsb
    and al, al
    je .fin

    shl eax, 3
    add eax, VGA_FONT_8x8_FIXED

    ; Нарисовать символ
    push esi edi

    mov  esi, eax
    mov  ecx, 8

@@:
    ; Выбор регистра Режим и одновременная установка режима 2
    mov  ax, 0205h 
    out  dx, ax    
    
    ; Следующий символ
    lodsb

    ; Устанавливаем битовую маску
    ; Выбор регистра "Битовая Маска" и одновременная запись маски разрешенных пикселей.
    mov  ah, al    
    mov  al, 8
    out  dx, ax    

    ; запись цвета
    mov al, [par4]

    ; реализация "защелки"
    mov ah, [es:edi]
    mov [es:edi], al

    add di, 80
    loop @b

    pop edi esi
    inc edi
    jmp .loopk

.fin:

    leave
    ret

; DAC_set(char color, int rgb)
; ----------------------------------------------------------------------

DAC_set:

	enter 0, 0
		
	mov dx, 0x3C8
	mov al, [par1]
	out dx, al
	
	inc dx
	mov al, [par2 + 2] ; R
	shr al, 2
	out dx, al
	
	mov al, [par2 + 1] ; G
	shr al, 2
	out dx, al

	mov al, [par2 + 0] ; B
	shr al, 2
	out dx, al
	
	leave
	ret

; Очистить экран в синий цвет
; ----------------------------------------------------------------------
I80_clrscr:

	mov ax, 0x1720
	mov edi, 0xB8000
	mov ecx, 80*25
	rep stosw

	ret

; ----------------------------------------------------------------------
include 'font_8x8.asm'
; include 'font_6x11.asm'

