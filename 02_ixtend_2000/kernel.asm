
; Стартовый файл. После boot-загрузчика, именно он грузится из FAT16/32
; и запускается. Размер файла ограничен - до 600кб, т.к. 40 кб заняты BIOS

; ADDR   ЗНАЧЕНИЕ
; 0000h  8-байтное значение LINEAR FRAME ADDRESS (VESA)
; 0008h  CPUID Vendor

MAXIMAL_MEMORY  equ 128     ; 128 mb памяти

;       АДРЕС                 ОПИСАНИЕ                              ГРАНУЛЯРНОСТЬ
PLM4    equ 1000h           ; Главный каталог                       512 Gb
PDP     equ 2000h           ; Директория директорий                 1 Gb
PD      equ 3E0000h         ; Директория страниц (занимает 128kb)   2 Mb
PT      equ 400000h         ; Сами страницы (занимает 64 мб)        4 Kb

; IDT    4   kb
; MISC   28  kb
; CODE   600 kb
; STACK  8   kb
; PAGING 4mb...68mb

        org     8000h
        macro   brk { xchg bx, bx }

        cli
        cld    
        
        mov     ax, 0003h
        int     10h

        ; Запрос на получение адреса видеобуфера
        xor     ax, ax
        mov     es, ax
        mov     ax, 0x4F01
        mov     di, 0x0200
        mov     cx, 117h
        int     10h

        ; https://pdos.csail.mit.edu/6.828/2008/readings/hardware/vgadoc/VESA.TXT
        mov     ebp, [es : 0x200 + 0x28]
        mov     [es: 0000h], ebp
        xor		ebp, ebp
        mov		[es: 0004h], ebp

        xor     eax, eax
        cpuid
        mov     [es: 0008h], ebx
        mov     [es: 000Ch], edx
        mov     [es: 0010h], ecx

        ; Для отладки (включить, чтобы посмотреть VESA Linear Frame Address)
        ; call    DEBUG_print_vesa_addr

        ; Видеорежим 1024 x 768 x 64K
        ; Битовая карта R(5) : G(6) : B(5)
        ; Включить поддержку линейного видеобуфера (+4000h)

        mov     ax, 0x4F02
        mov     bx, 117h + 4000h
        int     0x10    
        mov     si, s_vesa_failed        
        test    ah, ah
        jne     .vesa_failed

        ; Загрузка регистра GDT/IDT
        lgdt    [cs:GDTR]      
        lidt    [cs:IDTR] 

        ; Переключаемся в 32-х бит защищенный режим
        mov     eax, cr0        
        or      al, 1
        mov     cr0, eax
        jmp     0010h : pm_start

.vesa_failed:

        lodsb
        test    al, al
        je      .stop
        mov     ah, 0Eh
        int     10h
        jmp     .vesa_failed

.stop:            
        sti
        jmp     $

; Дебаггер
DEBUG_print_vesa_addr:

        mov     cx, 8
.deb:   rol     ebp, 4
        mov     eax, ebp
        and     al, 0Fh
        cmp     al, 10
        jb      @f
        add     al, 7
@@:     add     al, '0'
        mov     ah, 0Eh
        int     10h
        loop    .deb    
        jmp     $

s_vesa_failed db "VESA not support 1024 x 768 x 64k videomode", 0

; ----------------------------------------------------------------------

pm_start:

        use32

        mov     ax, 0008h
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     fs, ax
        mov     gs, ax
        
        ; Стек прямо под видеопамятью VGA
        mov     esp, 0x000A0000

        ; Тест на наличие x86_64 режима
        mov     eax, 0x80000000
        cpuid
        cmp     eax, 0x80000001
        jb      start_failed

        ; Проверка на количество памяти
        call    test_allowed_memsize

        ; Нижние 32 кб очистить (начиная с PLM4)
        mov     edi, 1000h
        xor     eax, eax
        mov     ecx, 7000h shr 2
        rep     stosd

        ; Установка первых указателей (инициализация главного региона памяти)
        ; PML4 (1 эл-т = 512 Gb) Указатель на первую PDP table 
        mov     dword [PLM4], PDP + 111b 

        ; PDP указатель на первую PD (page directory), вторую, третью и четвертую таблицы страниц
        mov     ecx, 4 * 8 ; 32 Gb MAX памяти
        xor     edx, edx
        mov     ebx, PD + 111b

        ; PDP (1 эл-т = 1 Gb). Разметить блоки 32 эл-та
@@:     mov     dword [PDP + edx], ebx
        add     edx, 8
        add     ebx, 1000h
        loop    @b

        ; Заполнение PD ссылками на PT
        mov     edi, PD
        mov     eax, PT + 111b
        mov     ecx, 16384 ; 2 mb * 16384 = 32 Gb

@@:     stosd
        mov     [edi], dword 0
        add     edi, 4
        add     eax, 1000h
        loop    @b

        ; Заполнение таблиц PT
        mov     edi, PT        
        mov     ecx, MAXIMAL_MEMORY shl 8 ; количество страниц (конвертация из мегабайтов) 1 mb = 256 x 4k pages
        mov     eax, 0 + 111b             ; 111b -- права U/S=1, RW=1, PRESENT=1
        xor     edx, edx

        ; Выполнить общую разметку памяти        
@@:     stosd
        mov     [edi], edx
        add     edi, 4
        add     eax, 1000h
        adc     edx, 0
        loop    @b

        ; Разметить 180000h (1.5 мб) видеопамяти
        mov     edi, [0000h]    ; Адрес видеопамяти        
        mov     eax, edi
        or      eax, 111b       ; Базовый адрес        
        shr     edi, (12 - 3)   ; Откуда начинать запись PT
        add     edi, PT        
        mov     ecx, 180h       ; Сколько страниц (384 x 4096 страниц) = 1,5 мб
        xor     edx, edx
@@:     stosd
        mov     [edi], edx
        add     edi, 4
        add     eax, 1000h
        adc     edx, 0
        loop    @b

        ; Включение опции физического расширения адреса (PAE)
        mov     eax, cr4
        or      eax, (1 shl 5) or (1 shl 9) ; 5=PAE, 9=SSE
        mov     cr4, eax       

        ; Загрузка каталога (4 уровня)
        mov     eax, PLM4
        mov     cr3, eax         

        ; Переключение в "длинный" режим
        mov     ecx, 0C0000080h  ; EFER MSR
        rdmsr
        or      eax, 1 shl 8        
        wrmsr

        ; Включение страничной адресации
        mov     eax, cr0
        or      eax, 80000000h
        mov     cr0, eax     

        ; Прыжок в длинный режим
        jmp     0020h : long_start

; 1 Выдать сообщение, что Long Mode не поддерживается
; 2 Нехватка памяти
start_failed:

        jmp     $

; Проверить, есть ли 128 Мб памяти?
; 64 Мб будут сразу заняты разметкой страниц на 32 Гб

test_allowed_memsize: 
        
        mov     ebx, 5A5A5A5Ah
        mov     eax, [8000000h - 4]                 ; Что было?
        xor     [8000000h - 4], ebx                 ; Поменяем
        cmp     eax, [8000000h - 4]                 ; Проверим
        jne     @f                                  ; Изменения? ОК
        jmp     start_failed                        ; Иначе ошибка
@@:     xor     [8000000h - 4], ebx                 ; Вернуть как было
        ret

; Регистр глобальной дескрипторной таблицы
GDTR: 

        dw 5*8 - 1  ; Лимит GDT (размер - 1)
        dq GDT      ; Линейный адрес GDT 

IDTR: 

        dw 256*16 - 1 ; Лимит GDT (размер - 1)
        dq 0          ; Линейный адрес GDT 

; Дескрипторная таблица
GDT:    dw 0,      0,    0,     0   ; 00 NULL-дескриптор
        dw 0FFFFh, 0, 9200h, 00CFh  ; 08 32-битный дескриптор данных
        dw 0FFFFh, 0, 9A00h, 00CFh  ; 10 32-bit код
        dw 0FFFFh, 0, 9200h, 00AFh  ; 18 64-bit данные
        dw 0FFFFh, 0, 9A00h, 00AFh  ; 20 64-bit код

; ----------------------------------------------------------------------
long_start:

        use64

        mov     ax, 0018h
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     fs, ax
        mov     gs, ax

        ; Скопировать данные kernel.bin 
        mov     rdi, 100000h   
        mov     esi, kernel
        mov     ecx, kernel_eof
        rep     movsb
               
        ; ------------ test ------------
        
        ; Очистить экран
        mov		rax, [0000h]
        mov		ecx, 1024*768
@@:     mov		[rax], word 0
        add		rax, 2
        dec		ecx
        jne		@b

        ; Очистить регистры
        xor     rax, rax
        xor     rcx, rcx
        xor     rdx, rdx
        xor     rbx, rbx 
        xor     rsi, rsi
        xor     rbp, rbp
        xor     rdi, rdi
        xor     r8, r8
        xor     r9, r9
        xor     r10, r10
        xor     r11, r11
        xor     r12, r12
        xor     r13, r13
        xor     r14, r14
        xor     r15, r15

		; К ядру
        jmp     100000h

; Ядро на C
kernel: file    "kernel.c.bin"
kernel_eof = $ - kernel

