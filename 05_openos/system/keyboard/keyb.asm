; Если значение > 0, то данные о нажатых клавишах будут записываться в специальный клавиатурный буфер
; откуда будут извлекаться через специальную функцию

keyb_query      db 0
keyb_buffer_ptr db 0
; ---   
shift_press     db 0
ctrl_press      db 0
alt_press       db 0

; Статусы KEY-CODES и их трансляция
; https://ru.wikipedia.org/wiki/%D0%A1%D0%BA%D0%B0%D0%BD-%D0%BA%D0%BE%D0%B4

keycodes_lo:

        ;  1 NUM LOCK
        ;  8 BACKSPACE
        ;  9 TAB
        ; 27 ESCAPE
        
        ;  00  01   02  03   04   05   06   07   08   09   0a   0b   0c   0d   0e 0f 10   11   12   13   14   15   16   17   18   19   1a   1b   1c  1d 1e   1f   20   21   22   23   24   25    26  27   28    29   2a 2b    2c   2d   2e   2f   30   31   32   33   34   35   36 37   38 39   3a 3b 3c 3d 3e 3f 40 41 42 43 44 45 46 47 48 49 4a   4b 4c 4d 4e   4f 50 51 52 53 54 55 56 57 58 59 5a 5b 5c 5d 5e 5f 60 61 62 63 64 65 66 67 68 69 6a 6b 6c
        db 0,  27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 8, 9, 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 10, 0, 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', 0x27, '`', 0, 0x5C, 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, '*', 0, ' ', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, '-', 0, 0, 0, '+', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

keycodes_hi:        

        ;  00  01   02  03   04   05   06   07   08   09   0a   0b   0c   0d   0e 0f 10   11   12   13   14   15   16   17   18   19   1a   1b   1c  1d 1e   1f   20   21   22   23   24   25    26  27   28    29   2a 2b    2c   2d   2e   2f   30   31   32   33   34   35   36 37   38 39   3a 3b 3c 3d 3e 3f 40 41 42 43 44 45 46 47 48 49 4a   4b 4c 4d 4e   4f 50 51 52 53 54 55 56 57 58 59 5a 5b 5c 5d 5e 5f 60 61 62 63 64 65 66 67 68 69 6a 6b 6c
        db 0, 255, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', 8, 9, 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', 10, 0, 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"',  '~', 0,  '|', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', 0, '*', 0, ' ', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, '-', 0, 0, 0, '+', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

key_press_interrupt:

        in   al, 0x60
        mov  ah, al
        and  ah, 0x7F

        ; ---- 
        cmp  al, 0xE0
        je .key_special

        ; ----
        movzx ebx, ah
        mov   [const_KEYB_STATUS + ebx], byte 0xFF
        test  al, 0x80
        je @f
        mov   [const_KEYB_STATUS + ebx], byte 0x00
@@:        
        ; SHIFT (левый или правый)
        ; --------- 
        cmp  al, 0x2a
        je .shift_pressed
        cmp  al, 0xaa
        je .shift_release
        cmp  al, 0x36
        je .shift_pressed
        cmp  al, 0xb6
        je .shift_release

        ; CTRL (левый)
        ; ---------
        cmp  al, 0x1d
        je .ctrl_pressed
        cmp  al, 0x9d
        je .ctrl_release

        ; ALT (левый)
        ; ---------
        cmp  al, 0x38
        je .alt_pressed
        cmp  al, 0xb8
        je .alt_release

        ; проверка на то, нужно ли писать данные куда-нибудь в буфер?
        ; ---------
        cmp [keyb_query], 0
        je  .exit
        test al, 0x80
        jne .exit        

        ; Получение кей-кода
        mov al, [keycodes_lo + ebx]    ; клавиша shift отпущена
        cmp [shift_press], byte 0xFF 
        jne @f
        mov al, [keycodes_hi + ebx]    ; клавиша shift зажата              

@@:             
        ; Инвалидировать неопределенные скан-коды 
        and al, al
        je .exit

        ; Вписывание в буфер новых данных
        movzx ebx, [keyb_buffer_ptr]
        mov [const_KEYB_BUFFER + ebx], al
        mov [const_KEYB_BUFFER + ebx + 1], byte 0
        inc bl
        cmp bl, 0xFE
        je .exit
        mov [keyb_buffer_ptr], bl

.exit:

        ret

; --------------------------------------
.key_special:        

        ret

; --------------------------------------
.shift_pressed:

        mov [shift_press], 0xFF
        ret

.shift_release:        

        mov [shift_press], 0x00
        ret

.ctrl_pressed:

        mov [ctrl_press], 0xFF
        ret

.ctrl_release:        

        mov [ctrl_press], 0x00
        ret


.alt_pressed:

        mov [alt_press], 0xFF
        ret

.alt_release:        

        mov [alt_press], 0x00
        ret

; Получение ASCII-кода клавиши (AL), ждать пока не нажмется
; -------------------------------------------------------------------------------
getch:

        push ecx esi edi
@@:     call pop_keyb_key
        and al, al
        je @b        
        pop  edi esi ecx
        ret

; -- извлечь клавишу из буфера --
pop_keyb_key:      

        mov al, [const_KEYB_BUFFER]
        and al, al
        je .exit

        mov ecx, 254
        mov edi, const_KEYB_BUFFER 
        mov esi, const_KEYB_BUFFER + 1
        rep movsb

        dec byte [keyb_buffer_ptr]
.exit:

        ret        