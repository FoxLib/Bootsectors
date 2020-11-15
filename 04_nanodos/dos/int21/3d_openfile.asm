;
; Открыть файл и создать блок описателя
; DS:DX - Имя файла
;
; Коды ошибок - AX = 02h, 03h, 04h
; ---------
; @todo Сделать тест на ReadOnly при открытии в режиме записи
;

dos.int21h.OpenFile:

        ; Записать главный текущий каталог во временный
        mov     eax, [cs: dos.param.dir]
        mov     [cs: dos.param.current_dir], eax

        ; Записать информацию о нем в новый блок dos.param.files
        mov     si, word [cs: dos.int21h.edx]
        call    dos.routines.SearchDir
        jb      .file_not_found

        ; Файл найден, создать новый дескриптор
        mov     cx, 1
        mov     si, dos.param.files + 20h
.loop:  test    [fs: si + fsitem.db.attr], byte 1
        jz      .make

        inc     cx
        add     si, 20h
        cmp     si, dos.param.files_top
        je      .no_free_descriptors
        jmp     .loop

.make:  ; Определение параметров дескриптора
        mov     [fs: si + fsitem.dd.cluster], eax
        mov     [fs: si + fsitem.dd.current], eax
        mov     eax, [fs: bx + 1Ch]
        mov     [fs: si + fsitem.dd.size], eax
        mov     al, byte [dos.int21h.eax]
        mov     [fs: si + fsitem.db.mode], al

        xor     eax, eax
        mov     [fs: si + fsitem.db.seek_mode], al
        mov     [fs: si + fsitem.dd.cursor], eax
        mov     [fs: si + fsitem.db.attr], byte 1       ; Отметка "Занято"
        mov     byte [fs: si + fsitem.db.alias_of], al  ; Это не дубликат
        
        ; Для поиска DIR_ENTRY        
        mov     eax, [cs: dev.DiskRead.DAP + 8]
        mov     [fs: si + fsitem.dd.file_sector], eax
        mov     [fs: si + fsitem.dw.file_id], bx

        ; Открытый Handler
        mov     word [cs: dos.int21h.eax], cx           ; Дать описатель
        and     byte [cs: dos.int21h.flags], 0xFE       ; Сбросить CF=0
        ret

; Ошибка. Файл не найден. Сформировать ответ для EXIT-code
.file_not_found:

        or      byte [cs: dos.int21h.flags], 1           ; Установка CF=1
        cmp     [si - 1], byte 0
        mov     ax, 2  ; Файл не найден
        je      @f
        mov     ax, 3  ; Директория
@@:     mov     word [cs: dos.int21h.eax], ax
        ret

; Нет свободных дескрипторов для открытых файлов (их может быть максимум 55)
.no_free_descriptors:

        or      byte [cs: dos.int21h.flags], 1           ; Установка CF=1
        mov     word [cs: dos.int21h.eax], 4
        ret
