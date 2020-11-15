    
    use16

; --------------------------------------------------------
; Создать дескриптор и записать его в память. Реальный режим.
; DS:BX  - Адрес, откуда брать данные о дескрипторе (8 байт)
; DI     - Номер дескриптора, куда писать
; --------------------------------------------------------

create_descriptor_real_mode:

    mov  eax, [ds:bx + 4]   ; ax = limit - 1
    test word [ds:bx + 8], BIT_GRANULARITY

    ; Вычисляется гранула? Если 0 - значит, нет
    je @rmc_no_granul

    ; В нижних 12-ти битах нули, просто смещение на 12 бит
    test eax, 0x000FFFFF
    je @granul_0

    ; Иначе добавляем еще +1
    shr eax, 12 
    inc eax
    jmp  @rmc_no_granul

@granul_0:
   
    shr eax, 12 

@rmc_no_granul:

    dec eax
    mov [es:di + 0], ax

    shr eax, 16
    and al, 0x0F
    mov [es:di + 6], al    ; верхние 4 бита предела

    mov eax, [ds:bx + 0]
    mov [es:edi + 2], eax  ; записываем 24 бита адреса

    shr eax, 24
    mov [es:di + 7], al    ; оставшиеся 8 бит адреса

    mov byte [es:di + 5], 0 ; обнуляем
    mov dx, [ds:bx + 8]
    or [es:di + 5], dx      ; нижний байт конфига и совмещаем старшие биты конфига с верхним пределом

    ret

; --------------------------------------------------------
; Установка системных дескрипторов. Реальный режим.
; --------------------------------------------------------

set_descriptors:    

    mov ax, RM_SEGMENT_GDT
    mov es, ax

    xor ax, ax
    mov cx, 0x8000
    rep stosw

    mov  di, SEGMENT_CORE_CODE
    mov  bx, descriptors
    mov  cx, COUNT_SEGMENTS

    ; Расстановка сегментов в GDT
    ; Важно, чтобы данные о сегментах шли в правильном порядке
    ; в исходных кодах

@rm_loop:

    call create_descriptor_real_mode
    
    add  di, 8
    add  bx, 10
    dec  cx
    jne  @rm_loop

    mov ax, GDTR_SEGMENT
    mov es, ax

    ; Размер таблицы 64kb
    ; Операционная система будет смотреть и устанавливать NULL

    mov word  [es:0], 0xFFFF 
    mov dword [es:2], RM_SEGMENT_GDT * 0x10
    lgdt [es:0]

    ; Загрузка IDT
    mov ax, IDTR_SEGMENT
    mov es, ax    

    mov word  [es:0], 256 * 8 - 1
    mov dword [es:2], (RM_SEGMENT_IDT * 0x10)
    lidt [es:0]

    ret

; PROTECTED MODE SECTION
; ************************************************************************************************
; Установка системных прерываний производится уже в защищенном режиме
; ************************************************************************************************

    use32

set_interrupts:

    ; Перепрограммирование IRQ
    call IRQ_redirect 

    mov ax,  SEGMENT_IDT
    mov es,  ax
    xor edi, edi
    mov cx,  256

    ; По умолчанию все прерывания - пользовательские 

@pmsetload_stub:

    mov esi, usr_interrupt
    movsd
    movsd
    loop @pmsetload_stub
    
    ; Копируем системные INT и IRQ
    mov esi, interrupt_list
    xor edi, edi
    mov ecx, (0x40 * 2)
    rep movsd

    ret

; ----------------------------------------------------
; Поиск свободного индекса GDT [TI=0, RPL=00]
; CX - свободный дескриптор. Если CX = 0, GDT полон
; ----------------------------------------------------

gdt_lookup:

    push ds
    mov ax,  SEGMENT_GDT
    mov ds,  ax
    mov ecx, 8

@gdt_lookup_loop:

    ; Не NULL?
    cmp dword [ds:ecx], 0
    jne @gdt_lookup_next
    cmp dword [ds:ecx + 3], 0

    ; Пустой дескриптор найден
    je @gdt_lookup_end

@gdt_lookup_next:

    add cx, 8
    jnc @gdt_lookup_loop

    ; Превышение размера GDT
    xor cx, cx

@gdt_lookup_end:
    pop ds

    ret

; ----------------------------------------------------
; Поиск свободного 4kb физической памяти
; ----------------------------------------------------

search_phys_4kb:

    ret

; ----------------------------------------------------
; Установка двух базовых TSS на нулевом уровне
; A. Master B. V86
; ----------------------------------------------------
set_tss:

    ; Очищаем два сегмента TSS
    mov ax, SEGMENT_TSS_RW
    mov es, ax

    ; Очистка TSS
    xor eax, eax
    xor edi, edi
    mov ecx, (0x80000 - TSS0_ADDRESS32) shr 2
    rep stosd

    ; TSS MASTER
    ; -----------------------------------------

    ; Стек на нулевом уровне защиты
    mov word  [es:TSS_SS0],  SEGMENT_CORE_STACK
    mov dword [es:TSS_ESP0], 0xF000

    ; Стек на первом уровне защиты
    mov word  [es:TSS_SS1],  SEGMENT_CORE_STACK
    mov dword [es:TSS_ESP1], 0xD000

    ; Стек на втором уровне защиты
    mov word  [es:TSS_SS2],  SEGMENT_CORE_STACK
    mov dword [es:TSS_ESP2], 0xC000

    ; Собственный сегмент стека указывает на самый низ
    mov word  [es:TSS_SS],   SEGMENT_CORE_STACK
    mov dword [es:TSS_ESP],  0xB000    

    ; Установка EFLAGS с разрешенными прерываниями
    mov dword [es:TSS_EFLAGS], 0x11202 

    ; Запись PBRD
    mov eax,  cr3
    mov dword [es:TSS_CR3], eax

    ; Основной цикл OS
    mov word  [es:TSS_CS],  SEGMENT_CORE_CODE
    mov dword [es:TSS_EIP], kernel_loop 

    ; Загрузка сегментов данных
    mov word [es:TSS_DS], SGN_DATA
    mov word [es:TSS_ES], SGN_DATA
    mov word [es:TSS_FS], SGN_DATA
    mov word [es:TSS_GS], SGN_DATA

    ; TSS TIMER
    ; -----------------------------------------

    ; Стек на нулевом уровне защиты
    mov word  [es:TSS_TIMER_SHIFT + TSS_SS0],  SEGMENT_CORE_STACK
    mov dword [es:TSS_TIMER_SHIFT + TSS_ESP0], 0x8000

    ; Стек на первом уровне защиты
    mov word  [es:TSS_TIMER_SHIFT + TSS_SS1],  SEGMENT_CORE_STACK
    mov dword [es:TSS_TIMER_SHIFT + TSS_ESP1], 0x6000

    ; Стек на втором уровне защиты
    mov word  [es:TSS_TIMER_SHIFT + TSS_SS2],  SEGMENT_CORE_STACK
    mov dword [es:TSS_TIMER_SHIFT + TSS_ESP2], 0x4000

    ; Собственный сегмент стека указывает на самый низ
    mov word  [es:TSS_TIMER_SHIFT + TSS_SS],   SEGMENT_CORE_STACK
    mov dword [es:TSS_TIMER_SHIFT + TSS_ESP],  0x2000    

    ; Установка EFLAGS с разрешенными прерываниями
    mov dword [es:TSS_TIMER_SHIFT + TSS_EFLAGS], 0x11202 

    ; Запись PBRD
    mov eax,  cr3
    mov dword [es:TSS_TIMER_SHIFT + TSS_CR3], eax

    ; Основной цикл OS
    mov word  [es:TSS_TIMER_SHIFT + TSS_CS],  SEGMENT_CORE_CODE
    mov dword [es:TSS_TIMER_SHIFT + TSS_EIP], timer_loop 

    ; Загрузка сегментов данных
    mov word [es:TSS_TIMER_SHIFT + TSS_DS], SGN_DATA
    mov word [es:TSS_TIMER_SHIFT + TSS_ES], SGN_DATA
    mov word [es:TSS_TIMER_SHIFT + TSS_FS], SGN_DATA
    mov word [es:TSS_TIMER_SHIFT + TSS_GS], SGN_DATA

    ret

; ----------------------------------------------------
; Выдача ошибки на экран в режиме VGA/VESA
; Фатальная ошибка: остановка с печатью сообщения об ошибке
; DS:EAX - строка ошибки
; ----------------------------------------------------

fatal_error:

    push eax

        mov ax, SGN_DATA
        mov ds, ax 

        ; Разметка максимального размера монитора
        push dword 0    ; x1
        push dword 0    ; y1

        mov  ecx, [SCREEN_WIDTH]
        dec  ecx
        push dword ecx ; x2
        mov  ecx, [SCREEN_HEIGHT]
        dec  ecx    
        push dword ecx  ; y2
        push dword 0x000080  ; color
        call VESA_rectangle
        add  esp, 0x14

        ; ---------------

        mov eax, [SCREEN_HEIGHT]
        sub eax, 19

        push dword 0 ; x1
        push eax     ; y1

        mov  ecx, [SCREEN_WIDTH]
        dec  ecx
        push dword ecx ; x2
        mov  ecx, [SCREEN_HEIGHT]
        dec  ecx    
        push dword ecx  ; y2
        push dword 0x008000  ; color
        call VESA_rectangle
        add  esp, 0x14

    pop eax

    mov  ebx, [SCREEN_HEIGHT]
    sub  ebx, 15

    push dword 8
    push dword ebx
    push dword 0xffffff
    push dword eax
    call VESA_out_text
    add  esp, 0x10

    ; Полная остановка процессора
    cli
    hlt
    jmp +$

; ----------------------------------------------------
; Установка системного таймера 
; ----------------------------------------------------

kernel_set_timer_100:

    mov   al, 0x34              ; set to 100Hz
    out   0x43, al

    mov   al, 0x9b              ; lsb    1193180 / 1193
    out   0x40, al

    mov   al, 0x2e              ; msb
    out   0x40, al

    ret

; ----------------------------------------------------
; Процедура редиректа IRQ
; ----------------------------------------------------

IRQ_redirect:

    mov al, [APIC_presence]
    cmp [APIC_presence], 1
    jne @pmrirq_1

    call disable_APIC

@pmrirq_1:

    mov bx, 2820h
    mov dx, 0FFFFh
    call    redirect_IRQ
    ret

; Перенаправление IRQ от оборудования на другие векторы
;
; | В режиме реальных адресов принято отображать аппаратные прерывания на фиксированные вектора:
; | IRQ 0..7 - на вектора прерываний 8..0Fh, IRQ 8..15 - на 70h..7Fh. При работе в защищённом режиме 
; | такая схема работы IRQ нам не подходит, т.к. вектора 8..0Fh заняты исключениями. В связи с этим
; | возникает необходимость при установке системы прерываний в защищённом режиме перенаправить 
; | аппаратные прерывания на другие вектора, лежащие за пределами 00..1Fh.
; 
; BX = { BL = Начало для IRQ 0..7, BH = начало для IRQ 8..15 }
; DX = Маска прерываний IRQ ( DL - для IRQ 0..7, DH - IRQ 8..15 )
; если бит в маске установлен, то этот IRQ запрещен

; Программируемый контроллер прерываний | http://wiki.osdev.org/8259_PIC

; --------------------------------
; IO базовый адрес для master PIC
; PIC1            0x20        

; IO базовый адрес для slave PIC
; PIC2            0xA0        

; PIC1_COMMAND    PIC1
; PIC1_DATA       PIC1 + 1
; PIC2_COMMAND    PIC2
; PIC2_DATA       PIC2 + 1

; ICW1_ICW4        0x01        /* ICW4 (not) needed */
; ICW1_SINGLE      0x02        /* Single (cascade) mode */
; ICW1_INTERVAL4   0x04        /* Call address interval 4 (8) */
; ICW1_LEVEL       0x08        /* Level triggered (edge) mode */
; ICW1_INIT        0x10        /* Initialization - required! */
; ICW1_INIT        0x20        /* EOI (End of Interrupt)*/
 
; ICW4_8086        0x01        /* 8086/88 (MCS-80/85) mode */
; ICW4_AUTO        0x02        /* Auto (normal) EOI */
; ICW4_BUF_SLAVE   0x08        /* Buffered mode/slave */
; ICW4_BUF_MASTER  0x0C        /* Buffered mode/master */
; ICW4_SFNM        0x10        /* Special fully nested (not) */
; --------------------------------

redirect_IRQ:

    ; Первая команда - записать команду инициализации в 2 PICs (A0h, 20h) = 11h = ICW1_INIT | ICW1_ICW4
    ; Это команда дает возможность записать 4 инициализирующих байта в каждый порт (A1h, 21h), 
    ; 
    ; Первый байт: смещение вектора (ICW2)
    ; Второй байт: каким образом вектор подключен к master/slave (ICW3)
    ; Третий байт: дополнительная информация об окружений
    ; Четвертый байт: маска

    ; Запуск инициализации
    ; Важен порядок загрузки x20, xA0, от этого зависит то, как потом будет работать
    ; IRQ 8..F
    mov al,   11h

    out 20h,  al
    jcxz      $+2
    jcxz      $+2

    out 0a0h, al
    jcxz      $+2
    jcxz      $+2

    ; Первый байт данных (смещения)
    ; ICW2: Slave PIC vector offset
    mov al,   bh
    out 0a1h, al
    jcxz      $+2
    jcxz      $+2

    ; ICW2: Master PIC vector offset
    mov al,   bl
    out 21h,  al
    jcxz      $+2
    jcxz      $+2

    ; ICW3: сообщить, что это slave, и его cascade identity (0000 0010)
    mov al,   02
    out 0a1h, al
    jcxz      $+2
    jcxz      $+2

    ; ICW3: сообщить Master PIC, что есть slave PIC на IRQ2 (0000 0100)
    mov al,   04
    out 21h,  al 
    jcxz      $+2
    jcxz      $+2

    ; outb(PIC2_DATA, ICW4_8086): Окружение 8086/88 (MCS-80/85) режим
    mov al,   01
    out 0a1h, al
    jcxz      $+2
    jcxz      $+2

    ; outb(PIC1_DATA, ICW4_8086): Окружение 8086/88 (MCS-80/85) mode
    out 21h,  al
    jcxz      $+2
    jcxz      $+2

    ; Запись масок прерываний
    mov al,   dh
    out 0a1h, al
    jcxz      $+2
    jcxz      $+2

    mov al,   dl
    out 21h,  al
    jcxz      $+2
    jcxz      $+2

    ret

; ----------------------------------------------------
; Отключение APIC
; ----------------------------------------------------

disable_APIC: 

    mov bl,0
    mov ecx, 1bh

    rdmsr
    test ah, 1000b

    ; Если APIC был уже отключён
    jz  dapic_end   

    ; Сбрасываем 11-й бит в MSR 1Bh
    and ah, 11110111b    
    wrmsr

    mov bl,1

dapic_end:

    mov byte [APIC_presence], bl
    ret

; ----------------------------------------------------
; Установка битовых масок (AH)
; ----------------------------------------------------

IRQ_mask_master:

    in  al,   0x21
    and al,   ah
    out 0x21, al
    ret

IRQ_mask_slave:

    in  al,   0xA1
    and al,   ah
    out 0xA1, al
    ret