disk_bios         equ 0x7B00

; -------------------------------

macro ivk1 cmd, A 
{
        push A
        call cmd
}

macro ivk2 cmd, A, B
{
        push A
        push B
        call cmd
}

macro ivk3 cmd, A, B, C {

        push A
        push B
        push C
        call cmd

}

; Дисковые операции
; -------------------------------------------------

; ЧТЕНИЕ СЕКТОРОВ
ldap:   pusha
        mov ah, 0x42
        mov si, DAP
        mov dl, [disk_bios]
        int 0x13
        popa
        ret

; -------------------------------------------------
; Управление (вверх, вниз, влево, вправо и т.д.)
; -------------------------------------------------

key_interaction:

.key_loop:

        ; Ожидание нажатия клавиши
        mov ax, 0
        int 0x16

        ; <- клавиша влево
        cmp ax, 0x4b00
        je .key_left

        ; -> клавиша вправо
        cmp ax, 0x4d00
        je .key_right

        ; клавиша [ENTER]
        cmp al, 13
        je .enter

        jmp .key_loop

.key_left:

        cmp byte [si], 0
        je .key_left_overflow
        dec byte [si]       
        ret

.key_left_overflow:

        ; Простановка максимальной точки        
        mov  bl, [si + 2]
        mov  [si], bl
        ret

.key_right:

        mov bl, [si + 2]
        cmp byte [si], bl
        je .key_right_overflow
        inc byte [si]       
        ret

.key_right_overflow:
        
        mov [si], byte 0
        ret

; Выход из процеду при нажатой клавише ENTER
.enter:

        ret        

; *****************************************************
; ПРОЦЕДУРЫ РИСОВАНИЯ В 16-битном режиме
; У всех прав есть свои права! Поэтому бесправие есть 
; не хорошо, когда идет речь об авторах этого опуса.
; Защищено (sic!) лицензией LXTLSPGPLWPGL 
; *****************************************************

; paint_frame ((x1,y1), (x2,y2)) рисование фрейма
; paint_box   ((x1,y1), (x2,y2), (attr,sym)) рисование прямоугольника
; paint_text  ((x1,y1), char*) печать текста на экране

; si - указатель на стек
; di = 2*(80*[bp+si+1] + [bp+si])

paint_lib:

.at80:  push ax
        mov  al, [bp + si + 1]    ; al = y1 
        mov  ah, 80         
        mul  ah                   ; ax = y1 * 80
        add  al, [bp + si]   
        adc  ah, 0                ; ax = y1 * 80 + x1
        add  ax, ax               ; ax = 2*ax     
        mov  di, ax               ; di = 2*(80*y1 + x1
        pop  ax
        ret       

; -----------------------------------------------------
; Нарисовать няшную рамку
; a(x1,y1) b(x2,y2)
; ---
; bp + 4 = x2 | bp + 5 = y2 | bp + 6 = x1 | bp + 7 = y1
; ----------------------------
; http://www.computerhope.com/ascii.gif
; 
; c9 cd bb Коды рамки
; ba .. ba
; c8 cd bc
; -----------------------------------------------------

paint_frame:

        push bp
        mov  bp, sp

        ; Переключиться на текстовую видеопамять
        push es
        mov  ax, 0xb800
        mov  es, ax

        ; Расчет стартовой позиции (x1,y1)
        mov  si, 6
        call paint_lib.at80       ; расчитать di = 2*(80*y1 + x1)
        push di                   ; сохранить предыдущее значение для рисования вертикальной линии

        ; Горизонтальная верхняя линия
        mov al, 0xc9              ; символ левого верхнего уголка 
        stosb                     ; отобразить на экране
        inc di                    ; +1 пропустить байт атрибутов фона и символа
        mov cl, [bp + 4]          ; cl = x2
        sub cl, [bp + 6]          ; cl = x2 - x1
        dec cl                    ; cl = (x2 - x1) - 1
        mov ch, 0                 ; cx = 00CL
        mov dx, cx                
        shl dx, 1                 ; dx = 2*cl (для следующего этапа)

        mov al, 0xcd              ; символ "=" 
.hl0:   stosb                     ; рисовать символ
        inc di                    ; пропуск байта атрибута
        loop .hl0                 ; рисовать (x2-x1-1) раз символ "="

        mov al, 0xbb              ; символ "правый верхний уголок"
        stosb                     ; нарисовать

        pop di                    ; восстановить di = 2*(80*y1 + x1)
        mov cl, [bp + 5]          ; cx = y2
        sub cl, [bp + 7]          ; cx = y2 - y1       

        ; Вертикальная линия
.hl1:   add di, 160               ; сдвинуть линию рисования по вертикали вниз 
        push di                   ; сохранить это значение
        mov al, 0xba              ; символ "||"
        stosb                     ; рисование "||" символа
        inc di                    ; пропуск байта атрибута
        add di, dx                ; пропустить (x2-x1-1) символов
        stosb                     ; снова нарисовать "||"
        pop di                    ; восстановить строку: перейти к началу
        loop .hl1                 ; рисовать все y2-y1 строк
        add di, 160               ; перейти к следующей строке
        mov al, 0xc8              ; символ нижнего левого уголка
        stosb                     ; рисовать
        inc di                    ; пропуск атрибута
        
        ; Нижняя горизонтальная линия
        mov cx, dx                ; cx = 2*(x2-x1-1)
        shr cx, 1                 ; cx = x2-x1-1

        mov al, 0xcd              ; символ "="
.hl2:   stosb                     ; нарисовать
        inc di                    ; пропустить атрибуты
        loop .hl2                 ; рисовать все CX символов

        mov al, 0xbc              ; Нижний правый уголок
        stosb                     ; рисовать уголок

        pop  es bp                ; восстановить предыдущее значение ES, BP
        ret  4                    ; вернуться из процедуры и удалить 2 push

; -----------------------------------------------------
; Рисование прямоугольника
; a(x1,y1) b(x2,y2) c(color,symbol)
; bp+4,5 симба,калор
; bp+6,7 x2,y2
; bp+8,9 x1,y1
; -----------------------------------------------------

paint_box:

        push bp
        mov  bp, sp
        push es                   ; сохранить es и стек

        push 0xb800
        pop  es                   ; es указывает на текстовую видеопамять

        mov  si, 8
        call paint_lib.at80       ; расчитать di = 2*(80*y1 + x1)

        mov  cl, [bp + 7]
        sub  cl, [bp + 9]
        inc  cl                   
        mov  ch, 0                ; cx = y2 - y1 + 1
        mov  ax, [bp + 4]         ; ax = атрибут | символ заливки

.hl0:   push cx di
        mov  cl, [bp + 6]         
        sub  cl, [bp + 8]
        inc  cl                   ; cx = x2 - x1 + 1
        rep  stosw                ; нарисовать горизонтальную линию
        pop  di cx
        add  di, 160              ; перейти +1 к следующей строке
        loop .hl0                 ; нарисовать все строки

        pop  es bp
        ret  6                    ; восстановить 3 push

; Рисование только подложки
paint_substrate:

        push bp
        mov  bp, sp
        push es

        push 0xb800
        pop  es

        mov  si, 8
        call paint_lib.at80

        mov  cl, [bp + 7]
        sub  cl, [bp + 9]
        inc  cl
        mov  ch, 0
        mov  ax, [bp + 4]

.hl0:   push cx di
        mov  cl, [bp + 6]         
        sub  cl, [bp + 8]
        inc  cl                   ; cx = x2 - x1 + 1

.hl1:   ; нарисовать горизонтальную линию
        inc  di
        stosb
        loop .hl1        

        pop  di cx
        add  di, 160              ; перейти +1 к следующей строке
        loop .hl0                 ; нарисовать все строки

        pop  es bp
        ret  6                    ; восстановить 3 push

; -----------------------------------------------------
; Напечатать текст на текстовом экране
; a(x1,y1) t(offset text)
; bp+4   ds:text
; bp+6,7 x1,y1
; -----------------------------------------------------

paint_text:

        enter 0, 0        
        push si di es

        push 0xb800
        pop  es

        mov  si, 6
        call paint_lib.at80       ; расчет di = 160*y1 + 2*x1
        mov  si, [bp + 4]         ; получение ссылки на строку
.hl0:   lodsb                     ; загрузить в al символ
        and  al, al               ; проверить на 0 
        je .fin                   ; и выйти из цикла, если 0
        stosb                     ; печать
        inc di
        jmp .hl0
.fin:   
        pop  es di si
        leave     
        ret  4

; -----------------------------
; Строковые данные
; -----------------------------
strmain:

        .menu db "F2 Select hard disk   F3 Format   F4 INSTALL   F10 Exit", 0

        .welcome0 db "MY OS INSTALLER", 0
        .welcome1 db "================", 0
        .welcome2 db "This 'operation system' is created Just-For-Fun! Enjoy in playing this OS :)", 0
        .welcome3 db "ALL right is NOT reserved, github.com is great!", 0

        .frame1 db " Assign Install ", 0
        .frame2 db "Copy all data from flash to hard-disk", 0
        .frame3 db "[x]", 0        
        .frame4 db "[                                ]", 0  
        .frame5 db '00000000',0