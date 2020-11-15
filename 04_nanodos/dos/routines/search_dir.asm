; ----------------------------------------------------------------------
; Поиск номера кластера директории по заданным DS:SI
; Текущая файловая система должна быть задана
;
; @return eax - номер кластера, либо CF=1, если не найдена директория

; Если CF=0, то в BX находится смещение в текущем секторе для блока DIRINFO
;      CF=1     не найдена директория
;               в SI указатель на последний символ на тот каталог или файл,
;               который был найден
;
; [cs: dos.param.current_dir] -- последняя найденная директория
; ----------------------------------------------------------------------

; Временные значения
dos.routines.sd_tmpsi   dw 0
dos.routines.sd_curdir  dd 0

; ----------------------------------------------------------------------
dos.routines.SearchDir:

.next_fragment:

        ; Получить следующий фрагмент до "/", либо до 0
        call    dos.routines.FetchDirPart

        ; Если указан C:/ D:/ и т.д., то сменить текущий диск
        mov     ax, [cs: dos.filename + 1]
        cmp     ax, word ': '
        jne     .enter_dir_file

        ; ------------------------
        ; Смена диска
        ; ------------------------

        ; bx = (DiskLetter - 'C')
        mov     bl, [cs: dos.filename]
        sub     bl, 'C'
        mov     bh, 0
        cmp     bx, [cs: dos.param.num_fs_detected]
        jnbe    .err_disk_none

        ; Установить новый диск
        shl     bx, 5
        mov     ax, [fs: dos.param.fs_block + bx + fs.dw.device_id]
        mov     [cs: dos.param.drive_letter], al
        call    dos.routines.SetRootCluster

        ; Это последний фрагмент?
        cmp     [si - 1], byte 0
        je      .done
        jmp     .next_fragment

; ----------------------------
; Это директория или файл
; ----------------------------

.enter_dir_file:

        ; Сохранить значение DS:SI
        mov     eax, [cs: dos.param.current_dir]
        mov     [cs: dos.routines.sd_tmpsi], si
        mov     [cs: dos.routines.sd_curdir], eax

        ; Информация о текущей ФС
        mov     bx, [cs: dos.param.current_fsblock]

        ; Выбор метода получения директории FAT16/32
.cont:  mov     eax, [cs: dos.param.current_dir]
        cmp     eax, 1
        jne     .clust

        ; FAT16 Задан не кластер, а указатель на root_dir
        ; Начало RootDir будет стартовым сектором
        
        movzx   eax, word [fs: bx + fs.dd.fat_root]
        mov     bp, [fs: bx + fs.dw.root_ent_sectors]
        jmp     .load

        ; FAT16/32
        ; Количество секторов, которые необходимо просмотреть
        ; start = (cluster - 2)*cluster_size + start_data
        
.clust: mov     bp,  [fs: bx + fs.dw.cluster_size]
        sub     eax, 2
        movzx   ecx, word [fs: bx + fs.dw.cluster_size]
        mul     ecx
        add     eax, [fs: bx + fs.dd.start_data]

        ; Загрузить первый сектор каталога
.load:  mov     [cs: dev.DiskRead.DAP + 8], eax

        ; Загрузка следующего сектора
.sect:  mov     dl, [cs: dos.param.drive_letter]
        call    dev.DiskRead

        ; Просмотреть сектор (16 записей) и сравнить с dos.filename
        mov     ch, 16
        mov     si, dos.param.tmp_sector

.item:  mov     di, dos.filename
        mov     cl, 11
        mov     al, [fs: si]        ; Поиск закончился если первый символ = 0
        and     al, al
        je      .err_disk_none

        push    si                  ; Сравнить запрошенное имя файла и файл из директории
; ----------------------------
.loop:  mov     al, [fs: si]        ; Файл на диске
        mov     ah, [cs: di]        ; Запрошенная строка
        cmp     ah, '?'
        je      @f
        cmp     al, ah
        jne     .skip
@@:     inc     si
        inc     di
        dec     cl
        jne     .loop
; ----------------------------
.skip:  pop     si                  ; Тест, найден ли файл?
        and     cl, cl
        je      .found

        ; К следующей записи
        add     si, 20h

        ; Проверить остальные в секторе
        dec     ch
        jne     .item

        ; Просмотреть следующие секторы кластера
        inc     dword [cs: dev.DiskRead.DAP + 8]
        dec     bp
        jne     .sect

        ; Просмотр корневой директории закончен для FAT16
        mov     eax, [cs: dos.param.current_dir]
        cmp     eax, 1
        je      .err_disk_none

        ; Секция расчета следующего кластера - если он есть
        ; В случае, если есть - то он записывается в [current_dir] (временно)
        ; dx - номер элемента, ax - сектор fat

        mov     ecx, 128    ; 128 - FAT32        
        cmp     [fs: bx + fs.dw.filetype], byte 20h
        je      @f
        mov     cx, 256     ; 256 - FAT16
@@:     cdq
        div     ecx
        xchg    di, dx

        ; Установка начала FAT для сканирования
        add     eax, [fs: bx + fs.dd.start_fat]
        mov     [cs: dev.DiskRead.DAP + 8], eax

        ; Читать секцию FAT
        mov     dl, [cs: dos.param.drive_letter]
        call    dev.DiskRead

        ; 2=FAT32 (4 байта), 1=FAT16 (2 байта
        cmp     [fs: bx + fs.dw.filetype], byte 20h
        je      @f
        
        ; Поиск следующего кластера FAT16
        shl     di, 1
        movzx   eax, word [fs: dos.param.tmp_sector + di]
        mov     [cs: dos.param.current_dir], eax        
        cmp     ax, 0xFFF0
        jb      .cont
        jmp     .no_next_clust

        ; Поиск следующего кластера FAT32
@@:     shl     di, 2    
        mov     eax, [fs: dos.param.tmp_sector + di]
        mov     [cs: dos.param.current_dir], eax        
        cmp     eax, 0x0FFFFFF0     ; Продолжать загрузку? FAT32
        jb      .cont

.no_next_clust:

        ; Иначе - ничего не найдено: остановка поиска
        ; Восстановить предыдущее значение текущей директории
        mov     eax, [cs: dos.routines.sd_curdir]
        mov     [cs: dos.param.current_dir], eax
        jmp     .err_disk_none

        ; Сделать найденый каталог (файл) текущим [current_dir]
.found: mov     ax, [fs: si + 14h]
        shl     eax, 16
        mov     ax, [fs: si + 1Ah]
        mov     [cs: dos.param.current_dir], eax

        ; Установить старый адрес DS:SI
        ; и если это был конец - выйти из поиска каталогов
        mov     bx, si
        mov     si, [cs: dos.routines.sd_tmpsi]
        cmp     [si - 1], byte 0x00
        je      .done

        ; Запись нового значения кластера и поиск дальше
        jmp     dos.routines.SearchDir

; Ошибка диска
.err_disk_none:

        mov     si, [cs: dos.routines.sd_tmpsi]
        stc
        ret

; Успешно получилось войти в директорию и найти файл
; 0000:BX - файловый описатель

.done:  clc
        ret
