; ------------------------------------------------------
; Обработчик клавиш
; Данные сохраняются в ASCII в [keyb_buffer]
; ------------------------------------------------------

keyboard:

    saveall
brk

    in   al, 60h

    cbw
    and  rax, 0xff7f ; ah = 0 или FFh, al = скан-код    
    call .state_save ; Сохранение статуса кнопок
    call .ctrl_keys  ; Обнаружение и сохранение статуса кнопок

    ; Нажата обычная клавиша
    cmp ax, 0x0060
    jb .ordinary_char 

    ; Выход (клавиша не была опознана)
    jmp .exit

; Трансляция скан-кода в ASCII-код
.ordinary_char:

    call .movt
    
    mov rdi, [keyb_buffer]
    mov rcx, [keyb_last]
    mov [rdi + rcx], ax ; записать также 0 в конце
    inc rcx
    and rcx, 0x1FFF
    mov [keyb_last], rcx ; Циклические повторение

    ; ...
    ; 

.exit:

    in  al, 61h            ; отослать эхо
    out 61h, al            ; на клавиатуру...

    mov al, 20h
    out 20h, al            ; ...и PIC master
    loadall
    iretq    

; Процедуры клавиатуры
; -------------

; Процедура сохранения статуса
.state_save:

    push rax
    mov  rdi, [keyb_state]
    mov  bh, ah
    xor  bh, 0xFF
    xor  ah, ah    
    mov [rdi + rax], bh ; Сохранение статуса клавиш (по скан-кодам)
    pop  rax
    ret

; Определение особых не печатаемых кнопок (shift,ctrl,alt)
.ctrl_keys:

    push ax
    xor  ah, 0xFF

    ; Скан-код LSHIFT/RSHIFT
    cmp al, 0x2A
    je .shift
    cmp al, 0x36
    je .shift

    jmp .ctrl_keys_fin

.shift:

    mov [keyb_shift], ah ; ah = 0xFF нажата, ah = 0x00 не нажата

.ctrl_keys_fin:

    pop ax
    ret

; Определение по скан-коду символа в ASCII
; Трансляция [al -> al]
.movt:

    cmp [keyb_shift], 0xFF
    jne @f
    mov al, [keybsc_shift + eax]
    ret
@@: mov al, [keybsc + eax] ; ASCII-код клавиши
    ret

; Выделить память для клавиатурного буфера
; -----------------------------------------------------------------------------------
keyboard_init:

    mov  rax, 8192 ; 8 кб состоянии клавиш хватит для клавиатуры
    call memalloc
    mov  [keyb_buffer], rdi
    
    xor rax, rax
    mov rcx, 8192 shr 3
    rep stosq 

    ; ---
    mov  rax, 128
    call memalloc
    mov [keyb_state], rdi

    xor rax, rax
    mov rcx, 128 shr 3
    rep stosq 

    ret

; -----------------------------------------------------------------------------------
; Переменные    
; -----------------------------------------------------------------------------------

keyb_buffer  dq 0 ; Адрес невыгружаемой памяти для клавиатуры
keyb_state   dq 0 ; 128 клавиш текущего статуса скан-кода
keyb_current dq 0 ; Текущая позиция в FIFO [=0 в начале]
keyb_last    dq 0 ; Последняя позиция FIFO

keyb_shift   db 0 ; Зажат "shift"
keyb_ctrl    db 0 ; Зажат "ctrl"
keyb_caps    db 0 ; Зажат "caps lock"
keyb_en_ru   db 0 ; 0=en, 1=ru раскладка

; http://wiki.osdev.org/PS/2_Keyboard#Scan_Code_Sets.2C_Scan_Codes_and_Key_Codes
; Сканкоды от 0 до 127

;  "ESCAPE"      1
; LCTRL          2    0x1D
;  -             3
;  -             4
;  -             5
; LSHIFT         6    0x2A
; RSHIFT         7    0x36
;  "BACKSPACE"   8
;  "TAB"         9
; LEFT ALT       10   0x38
; -              11
;  "CAPSLOCK"    12
;  "ENTER"       13
;  "NUM_LOCK"    14
;  "SCROLL LOCK" 15
;  "F1 .. F12"   128 .. 139

keybsc:

    ; СЕКЦИЯ "НИЖНЕГО РЕГИСТРА"

    ;  0    1    2    3    4     5    6    7
    db 0,   1,   '1', '2', '3', '4', '5', '6' ; 0x00
    db '7', '8', '9', '0', '-', '=',  8,   9  ; 0x08
    db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i' ; 0x10
    db 'o', 'p', '[', ']', 13,   2,  'a', 's' ; 0x18
    db 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';' ; 0x20
    db "'", '`',  6,  '\', 'z', 'x', 'c', 'v' ; 0x28
    db 'b', 'n', 'm', ',', '.', '/', 7,   '*' ; 0x30
    db 10,  ' ', 12,  80h, 81h, 82h, 83h, 84h ; 0x38
    db 85h, 86h, 87h, 88h, 89h, 14,  15,  '7' ; 0x40 Keypad
    db '8', '9', '-', '4', '5', '6', '+', '1' ; 0x48 Keypad
    db '2', '3', '0', '.',  0,   0,   0,  8Ah ; 0x50
    db 8Bh,  0,   0,   0,   0,   0,   0,   0  ; 0x58

    ; СЕКЦИЯ "ВЕРХНИЙ РЕГИСТР"

keybsc_shift:

    ;  0    1     2    3    4    5    6    7
    db 0,   1,   '!', '@', '#', '$', '%', '^' ; 0x80
    db '&', '*', '(', ')', '_', '+',  8,   9  ; 0x88
    db 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I' ; 0x90
    db 'O', 'P', '{', '}', 13,   2,  'A', 'S' ; 0x98
    db 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':' ; 0xA0
    db '"', '~',  6,  '|', 'Z', 'X', 'C', 'V' ; 0xA8
    db 'B', 'N', 'M', '<', '>', '?', 10,  '*' ; 0xB0
    db 10,  ' ', 12,  80h, 81h, 82h, 83h, 84h ; 0xB8
    db 85h, 86h, 87h, 88h, 89h, 14,  15,  '7' ; 0xC0 Keypad
    db '8', '9', '-', '4', '5', '6', '+', '1' ; 0xC8 Keypad
    db '2', '3', '0', '.',  0,   0,   0,  8Ah ; 0xD0
    db 8Bh,  0,   0,   0,   0,   0,   0,   0  ; 0xD8
