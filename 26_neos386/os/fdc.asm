
; ----------------------------------------------------------------------
; Инициализация каналов DMA для FDC
; ----------------------------------------------------------------------

fdc_init:

        ; Установка DMA
        mov     al, $06
        out     $0A, al ; Маскирование DMA channel 2 и 0

        ; Адрес
        mov     al, $FF
        out     $0C, al ; Сброс master flip-flop
        mov     al, $00
        out     $04, al ; [7:0]
        mov     al, $10
        out     $04, al ; [15:8]

        ; Размер
        mov     al, $FF
        out     $0C, al ; Сброс master flip-flop
        mov     al, $FF
        out     $05, al ; [7:0]
        mov     al, $3F
        out     $05, al ; [15:8]

        ; Адрес
        mov     al, $00
        out     $81, al ; [23:16]
        mov     al, $02
        out     $0A, al ; Размаскировать DMA channel 2

        ; Инициализация
        mov     [fdc.motor], 0
        mov     [fdc.ready], 0
        ret

; ----------------------------------------------------------------------
; Подготовить диск на чтение
; ----------------------------------------------------------------------

fdc_dma_read:

        mov     al, $06 ; mask DMA channel 2 and 0 (assuming 0 is already masked)
        out     $0A, al
        mov     al, $56
        out     $0B, al ; 01010110 single transfer, address increment, autoinit, read, channel2)
        mov     al, $02
        out     $0A, al ; unmask DMA channel 2
        ret

; Подготовить диск на запись
fdc_dma_write:

        mov     al, $06
        out     $0A, al
        mov     al, $5A
        out     $0B, al ; 01011010 single transfer, address increment, autoinit, write, channel2
        mov     al, $02
        out     $0A, al
        ret

; Ожидать завершения (проверочный параметр AH)
fdc_wait:

        push    eax
        mov     dx, MAIN_STATUS_REGISTER
@@:     in      al, dx
        and     al, ah
        cmp     al, ah
        jne     @b
        pop     eax
        ret

; Запись данных (al) в FIFO
fdc_write_reg:

        mov     ah, $80
        call    fdc_wait            ; Ожидать OK
        mov     dx, DATA_FIFO
        out     dx, al              ; Записать AL в FIFO
        ret

; Чтение данных (al) из FIFO
fdc_read_reg:

        mov     ah, $c0
        call    fdc_wait            ; Ожидать OK
        mov     dx, DATA_FIFO
        in      al, dx              ; Прочесть AL из FIFO
        ret

; Включить мотор
fdc_motor_on:

        cli
        mov     [fdc.motor], 1              ; Включение
        sti
        mov     eax, [irq_timer_counter]
        mov     [fdc.motor_time], eax       ; Запись таймера
        mov     dx, DIGITAL_OUTPUT_REGISTER ; Регистр DOR = $1C (On)
        mov     al, 0x1C
        out     dx, al
        ret

; Выключить мотор
fdc_motor_off:

        cli
        mov     [fdc.motor], 0
        sti
        xor     eax, eax
        mov     dx, DIGITAL_OUTPUT_REGISTER ; Отключить
        out     dx, al
        ret

; Проверить IRQ-статус после SEEK, CALIBRATE, etc.
fdc_sensei:

        mov     al, SENSE_INTERRUPT
        call    fdc_write_reg       ; Отправка запроса
        mov     ah, 0xd0
        call    fdc_wait
        mov     dx, DATA_FIFO       ; Получение результата
        in      al, dx
        mov     [fdc.st0], al
        mov     ah, 0xd0
        call    fdc_wait
        mov     dx, DATA_FIFO       ; Номер цилиндра
        in      al, dx
        mov     [fdc.cyl], al
        ret

; Конфигурирование
fdc_configure:

        mov     al, SPECIFY
        call    fdc_write_reg
        mov     al, 0
        call    fdc_write_reg       ; steprate_headunload
        call    fdc_write_reg       ; headload_ndma
        ret

; Калибрация драйва
fdc_calibrate:

        call    fdc_motor_on
        mov     [fdc.func],  FDC_STATUS_SENSEI
        mov     [fdc.ready], 0
        mov     al, RECALIBRATE
        call    fdc_write_reg       ; Команда, Drive = A:
        mov     al, 0
        call    fdc_write_reg       ; Команда, Drive = A:
@@:     cmp     [fdc.ready], 0      ; Ожидать ответа IRQ
        je      @b
        ret

; Сбросить контроллер перед работой с диском
fdc_reset:

        mov     [fdc.func],  FDC_STATUS_SENSEI
        mov     [fdc.ready], 0

        ; Отключить и включить контроллер
        mov     dx, DIGITAL_OUTPUT_REGISTER
        mov     al, $00
        out     dx, al
        mov     al, $0C
        out     dx, al
@@:     cmp     [fdc.ready], 0      ; Ожидать ответа IRQ
        je      @b

        ; Конфигурирование
        mov     dx, CONFIGURATION_CONTROL_REGISTER
        mov     al, 0
        out     dx, al
        call    fdc_configure
        call    fdc_calibrate
        ret

; Сбор результирующих данных: если > 0, то ошибка
fdc_get_result:

        call    fdc_read_reg
        mov     [fdc.st0], al
        call    fdc_read_reg
        mov     [fdc.st1], al
        call    fdc_read_reg
        mov     [fdc.st2], al
        call    fdc_read_reg
        mov     [fdc.cyl], al
        call    fdc_read_reg
        mov     [fdc.head_end], al
        call    fdc_read_reg
        mov     [fdc.head_start], al
        call    fdc_read_reg
        and     al, $c0
        ret

; Преобразовать ax=LBA -> CHS
fdc_lba2chs:

        xor     dx, dx
        mov     bx, 18
        div     bx
        inc     dl
        mov     [fdc.r_sec], dl
        mov     dl, al
        and     dl, 1
        mov     [fdc.r_hd], dl
        shr     ax, 1
        mov     [fdc.r_cyl], al
        ret

; ----------------------------------------------------------------------
; Чтение и запись в DMA => IRQ #6
; ----------------------------------------------------------------------

; bl = 0 READ; 1 WRITE
; ax = lba
; (byte write, byte head, byte cyl, byte sector)

fdc_rw:

        mov     [fdc.ready], 0
        mov     [fdc.func],  FDC_STATUS_RW
        mov     ax, $4546
        and     bl, bl
        je      @f
        mov     al, ah
@@:     call    fdc_write_reg       ; 0 MFM_bit = 0x40 | (W=0x45 | R=0x46)
        mov     al, [fdc.r_hd]
        shl     al, 2
        call    fdc_write_reg       ; 1

        mov     al, [fdc.r_cyl]
        call    fdc_write_reg
        mov     al, [fdc.r_hd]
        call    fdc_write_reg
        mov     al, [fdc.r_sec]
        call    fdc_write_reg
        mov     al, 2
        call    fdc_write_reg       ; 5 Размер сектора (2 ~> 512 bytes)
        mov     al, 18
        call    fdc_write_reg       ; 6 Последний сектор в цилиндре
        mov     al, $1B
        call    fdc_write_reg       ; 7 Длина GAP3
        mov     al, $FF
        call    fdc_write_reg       ; 8 Длина данных, игнорируется
        ret

; Поиск дорожки => IRQ #6
fdc_seek:

        mov     [fdc.ready], 0
        mov     [fdc.func],  FDC_STATUS_SEEK
        mov     al, SEEK
        call    fdc_write_reg           ; Команда
        mov     al, [fdc.r_hd]
        shl     al, 2
        call    fdc_write_reg           ; head<<2
        mov     al, [fdc.r_cyl]
        call    fdc_write_reg           ; Цилиндр
        ret

; Подготовить диск для чтения/записи (AX = LBA)
fdc_prepare:

        call    fdc_lba2chs             ; Вычислить LBA
        mov     [fdc.error], 0          ; Отметить, что ошибок пока нет
        mov     eax, [irq_timer_counter]
        mov     [fdc.motor_time], eax
        cmp     [fdc.motor], 0          ; Включить мотор, если нужно
        jne     @f
        call    fdc_reset
@@:     call    fdc_seek
@@:     cmp     [fdc.ready], 0      ; Ожидать ответа IRQ
        je      @b
        ret

; ----------------------------------------------------------------------

; Чтение сектора (AX) в $1000 -> IRQ #6
fdc_read:

        mov     [fdc.lba], ax           ; Запрошенный LBA
@@:     call    fdc_prepare
        call    fdc_dma_read
        mov     bl, 0
        call    fdc_rw
        ret

; Запись сектора (AX) из $1000 -> IRQ #6
fdc_write:

        mov     [fdc.lba], ax
        call    fdc_prepare
        call    fdc_dma_write
        mov     bl, 1
        call    fdc_rw
        ret

; Обработчик прерываний
; ----------------------------------------------------------------------

fdc_irq:

        pusha
        cmp     [fdc.func], byte FDC_STATUS_RW
        je      .rw
        call    fdc_sensei              ; Выполнить считывание рез-та
        jmp     .exit
.rw:    call    fdc_get_result          ; Забрать результат при R/W
        and     al, al
        jne     .exit
        mov     [fdc.error], byte 1     ; Ошибка чтения при al > 0
.exit:  mov     [fdc.ready], byte 1     ; Завершено

        ; EOI
        mov     al, $20
        out     $20, al
        popa
        iretd

; Вычисление таймаута и выключение FDC из прерывания IRQ #0
; ----------------------------------------------------------------------

fdc_timeout:

        cmp     [fdc.motor], 0           ; Мотор включен?
        je      @f
        mov     eax, [irq_timer_counter] ; Если > 5с крутится, выключить
        sub     eax, [fdc.motor_time]
        cmp     eax, 500
        jb      @f
        call    fdc_motor_off
@@:     ret
