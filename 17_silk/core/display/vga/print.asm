; **********************************************************************
; Печать текста на экране в режиме teletype и других режимов
; **********************************************************************

; Текущая позиция текста на экране
VAR_DISPLAY_VGA_X      dd 0
VAR_DISPLAY_VGA_Y      dd 0

; ----------------------------------------------------------------------
; (char* text, int color, int bgcolor)

display_vga_print_sz:

    BEGIN   0    
    mov     esi, [arg_1]    ; Получить ссылку на строку и записать ее

.cycle_string:

    ; Получение UTF8 и конвертация в CP1251
    call    display_vga_get_utf8_symbol
    
    ; Если обнаружен конец сообщения
    and     al, al
    je      .eos
    
    ; Перевод строки
    cmp     al, 10
    je      .eol    

    ; Пропечатать символ AL
    invoke  iterm.putc, [arg_2], [arg_3]
    
    ; К рисованию строки далее
    jmp     .cycle_string
    
.eol:    

    inc     dword [VAR_DISPLAY_VGA_Y]
    mov     [VAR_DISPLAY_VGA_X], dword 0
    jmp     .cycle_string
   
.eos:

    leave
    ret
 
; ----------------------------------------------------------------------
; (int color, int bgcolor) al - char

display_vga_putc: 

    BEGIN   0
    
    pushad 
    and     eax, 0xff
    lea     ecx, [VGA_FONT_8x8_FIXED + 8*eax]
    
    ; Вычислить позицию курсора
    imul    edi, [VAR_DISPLAY_VGA_Y], dword 640 ; 80x8=640
    add     edi, [VAR_DISPLAY_VGA_X]
    add     edi, 0xA0000

    ; 05h = Регистр режима, 2
    ; http://www.osdever.net/FreeVGA/vga/graphreg.htm#05
    mov     dx, 3CEh
    mov     ax, 0x0205 
    out     dx, ax

    ; for (eax = 8; eax > 0; eax--)
    mov     eax, 8

.cycle_height:

    push    eax

    ; 08h (Режим), AH=Битовая маска 0xFF
    mov     ax, 0xFF08 
    out     dx, ax

    ; Рисование фонового цвета
    mov     bh, [edi]
    mov     bh, [arg_2]
    mov     [edi], bh
    
    ; Читать символ из BIOS-fonts, установка битовой маски
    mov     ah, [ecx]
    out     dx, ax

    ; Рисование строки символа на экрана
    mov     bh, [edi]
    mov     bh, [arg_1]
    mov     [edi], bh
    
    ; К следующей строке (из 16 строк символа) и маске для символа
    add     edi, 80             
    pop     eax
    
    inc     ecx
    dec     eax
    jne     .cycle_height
    
    ; X++ К следующему столбцу
    inc     [VAR_DISPLAY_VGA_X]
    cmp     [VAR_DISPLAY_VGA_X], dword 80
    jne     .fin
    
    ; Y++ К следующей строке
    inc     dword [VAR_DISPLAY_VGA_Y]    
    mov     dword [VAR_DISPLAY_VGA_X],  0
    
    ; .. обнаружение окончания строки
.fin:

    popad
    leave
    ret

; ----------------------------------------------------------------------
; Извлечение ds:esi и конвертация символа UTF8 в AL
; [ds:esi] -> al

display_vga_get_utf8_symbol:

    push    ebx

.retry:

    lodsb
    
    ; Если символ < 80h --> это ASCII
    test    al, 0x80
    je      .ok
    
    ; Если символ начинается на D0
    cmp     al, 0xD0 
    je      .d0
    
    ; Если символ начинается на D1
    cmp     al, 0xD1 
    je      .d1

    ; Остальные недействительны: искать первый правильный символ
@@: jmp     .retry      

    ; D0 (90-BF)
    ; ---------------
    
.d0:   
 
    lodsb
    
    mov     bl, al
    and     bl, 0xF0
    
    ; диапазон 9x-Ax
    cmp     bl, 0x90 
    je      .d0_90a0
    
    ; диапазон Ax-Bx
    cmp     bl, 0xA0 
    je      .d0_90a0
    
    ; диапазон Bx-XX
    cmp     bl, 0xB0 
    je      .d0_90a0
    
    ; Буква Ё
    cmp     bl, 0x80
    je      .d80
    jmp     .ok

.d0_90a0:

    ; Коррекция 90h..BFh -> C0h..EFh
    add     al, 0x30 
    jmp     .ok

.d80:   

    ; замена Ё на "Е"
    mov     al, 0xC5
    jmp     .ok
    
.d1: 

    ; D1 (80-8F)        
    lodsb
    
    ; буква ё?
    cmp     al, 0x91 
    jne     @f
    
    mov     al, 0xe5
    jmp     .ok

@@: 
    ; 80h -> E0h
    add     al, 0x70 
    
.ok:

    pop     ebx
    ret
