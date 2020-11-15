;
; Чтение файла из дескриптора файла

; AH    = 3FH
; BX    = дескриптор файла
; DS:DX = адрес буфера для чтения данных
; CX    = число считываемых байт
;
; AX = 05h,06h если CF=1

dos.int21h.bytes_send    dw 0       ; Кол-во переданных байтов 
dos.int21h.sector_pos    dw 0       ; Положение сектора в кластере
dos.int21h.cluster_size  dw 0       ; Кол-во секторов в кластере

; @TODO перепроверка перед чтением - файл может быть удален!
; @TODO чтение из CON
; ----------------------------------------------------------------------

dos.int21h.ReadFile:

        ; Инициализация
        mov     [cs: dos.int21h.bytes_send], 0
                
        ; Количество байт для чтения (до FFFFh)
        mov     bp, word [cs: dos.int21h.ecx]

        ; Файловые описатели
        mov     bx, word [cs: dos.int21h.ebx]
        cmp     bx, 55
        jnb     .desc_not_open
        
        ; Стартовый адрес DS:DX
        mov     di, word [cs: dos.int21h.edx]

        push    ds          ; Сохранить для восстановления
        shl     bx, 5       ; Расчет адреса блока с данными о файле  
        
        ; Обращение к неоткрытому дескриптору
        test    byte [fs: bx + dos.param.files + fsitem.db.attr], 1
        jz      .desc_not_open
        
.load_next_sector:

        mov     eax, [fs: bx + dos.param.files + fsitem.dd.current]
        
        ; Расчет позиции сектора для кластера
        call    dos.routines.CalcCluster        
        mov     [cs: dos.int21h.cluster_size], cx
        mov     esi, eax
          
        ; cluster_size = sector_in_cluster * 512
        shl     ecx, 9
        mov     eax, [fs: bx + dos.param.files + fsitem.dd.cursor]
        cdq
        idiv    ecx
        
        ; dx - текущее положение в текущем кластере
        ; di - начать считывать с определенного байта
        
        mov     cx, dx
        and     cx, 01FFh
        
        ; Рассчитать номер сектора в кластере
        shr     dx, 9
        mov     [cs: dos.int21h.sector_pos], dx
        and     edx, 0FFFFh
        add     esi, edx

        ; Прочитать сектор из кластера
        mov     eax, esi
        call    dev.DiskReadA

        ; Начать передавать данные (учесть смещение в секторе)
        mov     si, word [fs: bx + dos.param.files + fsitem.dd.cursor]
        and     si, 1FFh
        add     si, dos.param.tmp_sector
                
        ; Необходимо перейти к следующему сектору (даже если закончились байты)
.tx:    cmp     cx, 200h
        je      .request_next_sector

        ; Если закончилась читаемые байты...
        and     bp, bp
        je      .transmit_end
        
        ; Превышение файлового размера (EOF)
        mov     eax, [fs: bx + dos.param.files + fsitem.dd.size]
        cmp     eax, [fs: bx + dos.param.files + fsitem.dd.cursor]
        jbe     .transmit_end    
        
        ; Передача данных
        mov     al, [fs: si]
        mov     [ds: di], al
        
        ; +1 перемещение курсоров
        inc     si
        inc     di

        ; Если di = 0, перекинуть сегмент ds + 1000h, di = 0
        and     di, di
        jne     @f
        
        mov     ax, ds
        add     ax, 1000h
        mov     ds, ax
        
        ; +1 положение курсора в файле
@@:     inc     dword [fs: bx + dos.param.files + fsitem.dd.cursor]
        inc     word [cs: dos.int21h.bytes_send]    ; +1 кол-во байтов
        inc     cx      ; +1 позиция в сектора    
        dec     bp      ; -1 оставшихся байт
        jmp     .tx

        ; ------------------
        ; Запрос сектора
        ; ------------------

.request_next_sector:

        ; Проверка на выход за пределы кластера
        mov     ax, [cs: dos.int21h.sector_pos]
        inc     ax
        cmp     ax, [cs: dos.int21h.cluster_size]
        jb      .load_next_sector
        
        ; Найти следующий кластер
        mov     eax, [fs: bx + dos.param.files + fsitem.dd.current]
        call    dos.routines.GetNextCluster
        and     eax, eax
        je      .transmit_end
        
        ; Сохранить новый кластер для загрузки и перейти к нему
        mov     [fs: bx + dos.param.files + fsitem.dd.current], eax        
        jmp     .load_next_sector        

.transmit_end:

        mov     ax, [cs: dos.int21h.bytes_send]
        mov     word [cs: dos.int21h.eax], ax
        and     byte [cs: dos.int21h.flags], 0FEh

        ; Передача завершена
        pop     ds
        ret

; ----------------------------------------------------------------------

; Неверный Handle
.desc_not_open:
        
        mov     word [cs: dos.int21h.eax], 0006h
        or      byte [cs: dos.int21h.flags], 1
        ret
        
