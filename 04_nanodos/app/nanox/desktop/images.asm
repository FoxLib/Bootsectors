
; Загрузка изображений иконок
; ----------------------------------------------------------------------

desktop.Images:

        ; Загрузка изображения рабочего стола
        mov     dx, desktop.images.wallpaper
        call    gdi.LoadBMP
        mov     [desktop.images.hnd_wallpaper], eax
        
        ; Для кнопки "Пуск"
        mov     dx, desktop.images.winlogo
        call    gdi.LoadBMP
        mov     [desktop.images.hnd_winlogo], eax        

        ret

; Загрузка desktop.ini в память
; ----------------------------------------------------------------------
; dword +0  Адрес имени иконки
; dword +4  Запускной файл
; dword +8  Дескриптор файла иконки
;  word +12 Отступ слева
;  word +14 Отступ сверху

desktop.LoadIcons:

        mov     ax, 3D00h
        mov     dx, desktop.filename
        int     21h
        jb      .finparse
        mov     [desktop.filename.id], ax

        ; --- переделать потом через поиск размера файла DOS Fn 42H
        mov     ecx, 4096 + 1024 ; 4к для файла, 1к для описателей
        call    XMS.Alloc
        mov     [desktop.filename.handler], eax

        mov     ecx, 4096 + 1024
        xor     ax, ax
        push    edi
        call    XMS.RepStosb
        pop     edi
        push    edi
        
        mov     bx, [desktop.filename.id]
        mov     bp, 4096
        call    XMS.LoadFile
        
        ; Закрыть файл
        mov     ah, 3Eh
        int     21h
        
        ; Разбор иконок
        inc     edi
        mov     [desktop.images.icons_list], edi
        pop     esi      
        
.repeat:; Построчно разобрать строгий формат иконок
        call    XMS.Lodsb
        and     al, al
        je      .finparse
        dec     esi
        
        ; .... # Комментарии потом добавить бы

        ; Считывание
        call    .flow_name      ; Имя иконки
        call    .flow_name      ; Путь к программе
        call    .flow_name      ; Иконка программы
        
        push    esi
        push    edi

        ; Получение имени файла
        sub     [FreeBlock], 128
        movzx   edi, [FreeBlock]
        add     edi, BASEADDR
        mov     esi, ebp
        call    XMS.Copy

        ; Загрузить BMP и получить его Handler, который записать в EDI
        mov     dx, [FreeBlock]
        call    gdi.LoadBMP
        
        ; +8 Писать дескриптор
        pop     edi
        sub     edi, 4
        call    XMS.Write32
        
        ; +1 Новая иконка
        inc     [desktop.images.icons_count]
        pop     esi

        ; Парсер X (WORD)
        inc     esi
        call    XMS.Read32
        call    .hex2bin3
        call    XMS.Write32
        sub     edi, 2

        ; Парсер Y (WORD)
        inc     esi
        call    XMS.Read32
        call    .hex2bin3
        call    XMS.Write32
        sub     edi, 2
        
        ; Иконка загружена, восстановить
        add     [FreeBlock], 128

        ; Следующая иконка
        jmp     .repeat

.finparse:

        ret

; ----------------------------------------
; Парсер HEX ASCII $xxx в BIN (0..4095)
; ----------------------------------------

.hex2bin3:

        mov     ebx, eax
        xor     eax, eax        
        mov     ch, 3
        shl     ebx, 8
.rep:   rol     ebx, 8
        mov     cl, bl
        sub     cl, 30h
        cmp     cl, 10
        jb      @f
        sub     cl, 7
@@:     or      al, cl
        ror     ax, 4        
        dec     ch
        jne     .rep
        shr     ax, 4
        ret

; Определение имени, запись указателя и установка Zero-Term        
; 1. Ищем окончание имени (,)
; 2. Пишем адрес иконки
; 3. Вписываем Zero-Terminated
; --> ebp указатель на имя
; --> ecx длина строки

.flow_name:

        mov     ebp, esi
        xor     edx, edx
@@:     call    XMS.Lodsb
        inc     edx
        cmp     al, ','             
        je      @f
        jmp     @b        

@@:     mov     eax, ebp
        call    XMS.Write32        

        push    edi
        mov     edi, esi
        dec     edi
        mov     al, 0
        call    XMS.Stosb
        pop     edi
        mov     ecx, edx
        ret
      

; Пути и описатели
; ----------------------------------------------------------------------
desktop.images.wallpaper        db 'wall/main.bmp', 0
desktop.images.winlogo          db 'icon/winlogo.bmp', 0
desktop.filename                db 'desktop.ini', 0

; Указатель на изображение фона
desktop.images.hnd_wallpaper    dd 0
desktop.images.hnd_winlogo      dd 0
desktop.images.icons_count      dw 0    ; Количество объявленных иконок
desktop.images.icons_list       dd 0    ; Листинг иконок
desktop.filename.id             dw 0 
desktop.filename.handler        dd 0    ; Указатель на содержимое desktop.ini

