;
; ЗАГРУЗЧИК
; ----------------------------------------------------------------------
; Ядро загрузчика не может быть более 544 кб
; Но сам загрузчик загружает еще и initrd.img в память (любого размера)
; Поэтому возможно сделать ОС любого вида и сложности

; 000000h - 0007FFh  Вектора прерываний
; 001000h - 001FFFh  PDBR (главный каталог страниц)
; 002000h - 002FFFh  Каталог на разметку первых 4-х мегабайт
; 003000h            (dword) Объем памяти
; 004000h - 004FFFh  4k временная страница для разметки новой страницы
; 100000h - 1FFFFFh  Ядро
; 200000h - 3FFFFFh  Виртуальный диск (до 3-х мегабайт)
; 400000h - xxxxxxh  Область программ и данных к ним

        org     8000h
        macro   brk {  xchg    bx, bx }

        ; Загрузка регистра GDT/IDT
        mov     sp, 7C00h

        lgdt    [GDTR]
        lidt    [IDTR]

        ; Из FAT32 грузится прямо в XMS-память
        call    initrd

        ; Переход в текстовый режим
        mov     ax, 0003h
        int     10h

        xor     ax, ax
        mov     fs, ax
        mov     gs, ax

        ; Вход в Protected Mode
        cli
        mov     eax, cr0
        or      al, 1
        mov     cr0, eax
        jmp     10h : pm

        include "asm/initrd.asm"

; ----------------------------------------------------------------------
GDTR:   dw 8*8 - 1                      ; Лимит GDT (размер - 1)
        dq GDT                          ; Линейный адрес GDT
IDTR:   dw 256*8 - 1                    ; Лимит GDT (размер - 1)
        dq 0                            ; Линейный адрес GDT
GDT:    dw 0,      0,    0,     0       ; 00 NULL-дескриптор
        dw 0FFFFh, 0,    9200h, 00CFh   ; 08 32-bit данные
        dw 0FFFFh, 0,    9A00h, 00CFh   ; 10 32-bit код
        dw 103h,   800h, 8900h, 0040h   ; 18 32-bit главный TSS (0000:0800h)
        dw 0FFFFh, 0,    9200h, 008Fh   ; 20 16-bit данные
        dw 0FFFFh, 0,    9A00h, 008Fh   ; 28 16-bit код
        dw 0FFFFh, 0,   0F200h, 00CFh   ; 30 32-bit (3ring) данные 
        dw 0FFFFh, 0,   0FA00h, 00CFh   ; 38 32-bit (3ring) код 

; ----------------------------------------------------------------------
LZW_table       EQU 100000h
; ----------------------------------------------------------------------

        use32
pm:     mov     ax, 8
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     fs, ax
        mov     gs, ax
        mov     ax, 18h
        ltr     ax

        ; Распаковка LZW
        mov     ebx, 200003h     ; Данные для распаковки в 2mb
        mov     edi, [start_xms] ; Куда распаковать
        mov	    [LZW_bits], 0

LZW_clear:  ; Очистка словаря

        xor	    edx, edx

LZW_decompress_loop:

        ; В зависимости от размера словаря, будут использованы CH бит
        mov     eax, [initrd_size]
        add     eax, 200000h
        cmp     ebx, eax
        jnb     LZW_end

        ; 200h (-100h)
        mov	    ch, 9
        cmp	    edx, (0100h - 1)*8
        jbe	    LZW_read_bits

        ; 400h (-100h)
        mov	    ch, 10
        cmp	    edx, (0300h - 1)*8
        jbe	    LZW_read_bits

        ; 800h (-100h)
        mov	    ch, 11
        cmp	    edx, (0700h - 1)*8
        jbe	    LZW_read_bits

        ; 1000h (-100h)
        mov	    ch, 12
        cmp	    edx, (0F00h - 1)*8
        jbe	    LZW_read_bits

        ; 2000h (-100h)
        mov	    ch, 13
        cmp	    edx, (1F00h - 1)*8
        jbe	    LZW_read_bits

        ; 4000h (-100h)
        mov	    ch, 14
        cmp	    edx, (3F00h - 1)*8
        jbe	    LZW_read_bits

        ; 8000h (-100h)
        mov	    ch, 15
        cmp	    edx, (7F00h - 1)*8
        jbe	    LZW_read_bits

        mov	    ch, 16
        
LZW_read_bits:

        ; Сдвинуть на CL бит
        mov	    cl, [LZW_bits]
        mov	    eax, [ebx]
        shr	    eax, cl

        ; Срезать CH битов
        ; CL -> указатель на следующие биты

        xchg	cl, ch
        mov	    esi, 1
        shl	    esi, cl
        dec	    esi
        and	    eax, esi
        add	    cl, ch

LZW_read_bits_count:

        cmp	    cl, 8
        jbe	    LZW_read_bits_ok

        ; Обнаружено превышение байта, передвинуть указатель потока +8 бит
        ; до тех пор, пока CL не будет <= 8

        sub	    cl, 8
        inc	    ebx
        jmp	    LZW_read_bits_count

LZW_read_bits_ok:

        mov	    [LZW_bits], cl
        cmp	    eax, 100h
        jb	    LZW_single_byte         ; ax < 100h -- простой байт
        je	    LZW_cmd                 ; ax = 100h -- команда очистки словаря

        sub     eax, 101h               ; Использовать указатель на построенный словарь
        shl	    eax, 3
        cmp	    eax, edx
        ja	    LZW_error               ; eax - указатель на словарь если edx < eax, словарь превышен

        ; СЛОВАРЬ (8 байт на 1 эл-т)

        ; 4 | +0 | Количество символов
        ; 4 | +4 | Указатель на строку для повторения

        mov	    ecx, [LZW_table + eax]
        mov	    esi, [LZW_table + eax + 4]

        ; Записать в следующий элемент текущий указатель EDI (построение словаря)
        mov	    [LZW_table + edx + 4], edi
        rep	    movsb

        ; Скопировать кол-во символов из предыдущего элемента и +1 к длине
        mov	    eax, [LZW_table + eax]
        inc	    eax
        mov	    [LZW_table + edx], eax
        jmp	    LZW_decompress_next

        ; Строительство нового словаря

LZW_single_byte:

        mov	    [LZW_table + edx], dword 2  ; Добавить словарь: длина = 2, указатель
        mov	    [LZW_table + edx + 4], edi  ; текущий указатель на выходной поток
        stosb                               ; Скопировать один байт из входящего потока

        ; Добавляем +1 эл-т к словарю и переходим далее

LZW_decompress_next:

        add	    edx, 8
        jmp	    LZW_decompress_loop

; ----------------------------------------------------------------------
; Сброс словаря, но хитрый! Поток выравнивается до 16 байт

LZW_cmd:
        
        ; Сброс битов
        mov	    [LZW_bits], 0
        
        ; Установить указатель на выровненную область
        ; +10, 3 - это magic number (пропускаем его)
        sub     ebx, 3
        and     ebx, 0xFFFFFF0
        add     ebx, 13h  
        jmp     LZW_clear

; Ошибка декомпрессии
LZW_error:

        brk
        xchg    cx, cx
        jmp     $

; ----------------------------------------------------------------------
LZW_bits        db 0
; ----------------------------------------------------------------------
LZW_end:

        ; Сдвиг распакованных данных на правильное место
        mov     esi, [start_xms]
        sub     edi, esi
        dec     edi
        mov     ecx, edi
        mov     edi, 200000h
        rep     movsb

        ; Скопировать ядро в память (до 608 кб)
        mov     esi, os
        mov     edi, 100000h
        mov     ecx, len
        rep     movsb
        
        ; Включить SSE
        mov     eax, cr0
        and     ax, 0xFFFB		; clear coprocessor emulation CR0.EM
        or      ax, 0x2			; set coprocessor monitoring  CR0.MP
        mov     cr0, eax
        mov     eax, cr4
        or      ax, 3 shl 9		; set CR4.OSFXSR and CR4.OSXMMEXCPT at the same time
        mov     cr4, eax   
; ----        
        ; Определение объема установленной памяти (пока что 8 мб)
        mov     eax, 800000h
        mov     [003000h], eax 
; ----
        ; Разметка страничной организации памяти
        ; Заполнить PDBR только 1 каталогом на 4 Мб
        mov     edi, 1004h
        mov     [edi - 4], dword (1 + 2) + 2000h
        xor     eax, eax
        mov     ecx, 1023
        rep     stosd
        
        ; Заполнить первый каталог
        mov     ecx, 1024
        mov     eax, 3
@@:     stosd
        add     eax, 1000h
        cmp     edi, 3000h
        jne     @b

        ; Загрузка начального PDBR и включение режима страниц
        mov     eax, 1000h
        mov     cr3, eax
        mov     eax, cr0
        or      eax, 80000000h
        mov     cr0, eax
        jmp     100000h

os:     file    "kernel.c.bin"
len =   $ - os
