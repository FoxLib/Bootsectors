;
; Инициализация дисков
; ----------------------------------------------------------------------

dev.disk.Init:

        ; Просмотр устройств [80h..FFh]
        mov     dl, 80h
        mov     di, dos.param.drives
        mov     cx, 7

.device_loop:

        call    dev.DiskRead
        jc      .drive_not_found

        ; Запись, что это устройство готово
        dec     cx
        je      .enum_complete
        mov     al, dl
        stosb

.drive_not_found:

        inc     dl
        jne     .device_loop

.enum_complete:

        ret

; ----------------------------------------------------------------------
; Поиск FAT-разделов на текущем диске
; ----------------------------------------------------------------------

dev.disk.SearchFat:

        ; Сюда складываются данные обо всех FS
        mov     si, dos.param.drives

.device_loop:

        lodsb
        and     al, al
        je      .scan_completed

        ; Сначала, прочитать полную таблицу разделов
        push    si

        mov     dl, al
        mov     [dev.DiskRead.DAP + 8], dword 0
        call    dev.DiskRead
        jc      dos.io.Panic

        ; Скопировать область Partitions Table во временную область DTA
        mov     si, dos.param.tmp_sector + 0x1BE
        mov     di, dta
        mov     cx, 32
@@:     mov     ax, [fs: si]
        add     si, 2
        stosw
        loop    @b

        ; Всего может быть 4 главных раздела
        mov     cx, 4
        mov     si, dta

.loop_parts:

        mov     al, [si + 4]
        cmp     al, 0Bh
        je      .isfat                  ; fat32
        cmp     al, 0Ch
        je      .isfat                  ; fat32 (lba)
        cmp     al, 06h
        je      .isfat                  ; fat16
        jmp     .none

.isfat: call    dev.disk.DetectFat      ; fat32
.none:  add     si, 10h
        loop    .loop_parts

        pop     si
        jmp     .device_loop

.scan_completed:

        ret

; Определить параметры файловой системы / данные о Partition в [fs:si]
; ----------------------------------------------------------------------

dev.disk.DetectFat:

        pusha

        ; Запись адреса начала partition
        mov     ebx, [si + 8]
        mov     [dev.DiskRead.DAP + 8], ebx
        call    dev.DiskRead
        jc      dos.io.Panic

        ; Указатель на описатель ФС bp = fs_block + 32*num
        mov     si, dos.param.tmp_sector
        mov     bp, [dos.param.num_fs_detected]
        shl     bp, 5
        add     bp, dos.param.fs_block

        ; Где начинается Partition
        mov     [fs: bp + fs.dd.start_partition], ebx

        ; Записать начальный тип ФС и номер используемого диска
        mov     dh, 0
        mov     [fs: bp + fs.dw.filetype], word disk.fat.unknown
        mov     [fs: bp + fs.dw.device_id], dx

        ; 1. Резервированных секторов
        movzx   edi, word [fs: si + disk.fat.bsResSectors]
   
        ; 2. Старт FAT-таблиц
        mov     eax, [fs: bp + fs.dd.start_partition]
        add     eax, edi
        mov     [fs: bp + fs.dd.start_fat], eax

        ; 3. FAT size
        movzx   eax, word [fs: si + disk.fat.bsFATsecs]
        test    ax, ax
        jne     @f
        mov     eax, [fs: si + disk.fat32.bsBigFatSize]
@@:     movzx   ebx, byte [fs: si + disk.fat.bsFATs]
        mul     ebx
        add     edi, eax

        ; 4. СЕКТОР начала RootDir для FAT16
        mov     eax, [fs: bp + fs.dd.start_partition]
        add     eax, edi
        mov     [fs: bp + fs.dd.fat_root], eax

        ; 5. Root Entries (для FAT32 = 0)
        ; BPB_RootEntCnt * 32 / 512 = BPB_RootEntCnt >> 4
        movzx   eax, word [fs: si + disk.fat.bsRootDirEnts]        
        shr     ax, 4
        add     edi, eax        
        mov     [fs: bp + fs.dw.root_ent_sectors], ax

        ; 6. Где находятся сектора с данными
        mov     eax, [fs: bp + fs.dd.start_partition]
        add     eax, edi
        mov     [fs: bp + fs.dd.start_data], eax

        ; 7. Определить, сколько секторов на диске
        movzx   eax, word [fs: si + disk.fat.bsSectors]
        test    ax, ax
        jne     @f
        mov     eax, [fs: si + disk.fat.bsHugeSectors]

        ; 8. Определить, сколько кластеров в Data секции
@@:     mov     [fs: bp + fs.dd.size], eax
        movzx   ebx, byte [fs: si + disk.fat.bsSecPerClust]
        mov     [fs: bp + fs.dw.cluster_size], bx
        xor     edx, edx
        sub     eax, edi
        div     ebx

        ; 9. Определить тип ФС (12/16/32)
        cmp     eax, 4085           ; < 4085 - FAT12
        jnb     @f
        mov     [fs: bp + fs.dw.filetype], word disk.fat.12
        jmp     .done
@@:     cmp     eax, 65525
        jnb     @f                  ; <= 65524 - FAT16
        mov     [fs: bp + fs.dw.filetype], word disk.fat.16
        jmp     .done

@@:     ; Записать указатель на кластер RootEntries
        ; Кластер 2 - начальный (старт с Data-секции)
        ; > 65524 - FAT32

        mov     eax, [fs: si + disk.fat32.bsRootCluster]
        mov     [fs: bp + fs.dd.fat_root], eax
        mov     [fs: bp + fs.dw.filetype], word disk.fat.32

        ; Добавить счетчик количества обнаруженных FS
.done:  inc     word [dos.param.num_fs_detected]
        popa
        ret
