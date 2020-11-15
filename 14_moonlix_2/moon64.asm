; 64-х разрядная операционная система с js-интерпретатором
;
; Используемые ресурсы
; ------
; doc/
; lib64/
; -----

    include 'lib64/const.asm'     ; Константы
    include 'lib64/macros.asm'    ; Макросы

; --- компиляция ---
; fasm moon64.asm && ./update moon64.bin flash.img && cp moon64.bin moon.bin && bochs -f boot.bxrc -q
; ----------------------------------------------------------------------------------------

    org 0xC000

    ; 16 бит   
    cli

    ; Установка видеорежима VGA/VESA
    ; call vesa_set_1024x768 ; [lib64/vesa.asm]
    call vga_set_320x200 ; [lib64/vga.asm]

    ; Загружаем GDT-дескриптор, который уже подготовлен
    lgdt [cs:GDTR]        
 
    ; Переключаемся в 32-х бит защищенный режим
    mov   eax, cr0        
    or    al, 1
    mov   cr0, eax
    jmp   CODE_SELECTOR : pm_start

    include 'lib64/vga.asm'     ; Включение VGA через BIOS
    include 'lib64/vesa.asm'    ; Включение VESA через BIOS

; 32 bit    
; ----------------------------------------------------------------------------------------

    USE32

pm_start:
   
    mov eax, DATA_SELECTOR ; загрузим 4 GB дескриптор данных [lib64/const.asm]
    mov ds, ax             ; на все сегментные регистры
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; ESP прямо под PML4
    mov esp, 0x09A000 

    ; Включение опции физического расширения адреса 
    mov  eax, cr4
    or   eax, 1 shl 5
    mov  cr4, eax         

    ; Определение размера памяти
    call get_memory_size  ; [lib64/paging.asm]

    ; Создать 64-х битные таблицы
    call page64_create ; [lib64/paging.asm]

    ; Переключение в "длинный" режим
    mov  ecx, 0C0000080h ; EFER MSR
    rdmsr
    or   eax, 1 shl 8        
    wrmsr

    ; Включение страничной адресации
    mov  eax, cr0
    or   eax, 1 shl 31
    mov  cr0, eax        

    ; Прыжок в длинный режим
    jmp  LONG_SELECTOR : long_start

    ; Для 32-х битного режима
    ; -----
    include 'lib64/paging.asm'    ; Страничная организация памяти
    include 'lib64/gdt.asm'       ; Дескрипторные таблицы

    USE64

; 64 bit | Что дает нам 64 бит? MM7, XMM7, R15 - 32 свободно доступных регистра 
; ----------------------------------------------------------------------------------------

long_start:

    ; Теперь загружаем 64-х битные селекторы для доступа к более чем 4 Гб 
    ; физической памяти. Пока что могу сказать, что на моем компьютере 32 Гб памяти
    ; Но учитывается не только физическая, но еще и виртуальная, которая равна размеру 
    ; файла подкачки (LinuxSwap). Обычно я делаю его размером 64Гб. Хотя 32 гб хватает
    ; для памяти уж вполне. Ни разу не жаловался ["30-сен-2015"]

    mov ax, LDAT_SELECTOR
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    call xored              ; Очистить 64-х битные регистры общего назначения и память [lib64/sys.asm]   
    call interrupt_redirect ; Переброс векторов IRQ с 00h-0Fh на 20h-2Fh [lib64/pio.asm]
    call create_idt         ; Создание таблиц прерываний в 64 битном режиме [lib64/idt.asm]
    call ps2_mouse          ; Инициализировать мышку на работу через PS/2 [lib64/ps2.asm]
    call timer_clock_1000hz ; Включение 1000 Гц скорости таймера [lib64/sys.asm]
    call enable_sse         ; Включать поддержку SSE надо отдельно, выставляя нужный бит в CR4 регистр [lib64/sys.asm]
    call keyboard_init      ; Настройка клавиатурного буфера [lib64/handler/keyb.asm]

    ; http://www.sandpile.org/x86/tss.htm

; Основной старт программы ОС
; ----------------------------------------------------------------------------------------

    ; Задать back-буфер
    mov rax, 0x300000
    call memalloc
    ; mov [vesa_ptr], rdi ; на всякий случай

brk
    mov eax, 0x000080 ; Предположительно, синий цвет
    call vga13_cls    ; [lib64/canvas/drawing.asm]
    ;;call canvas_cls ; [lib64/canvas/drawing.asm]

    ; Показать мышку
    call mouse_show

    sti
    mov [ps2_a], byte 0xFF
    
tc: 

    cmp [ps2_a], byte 0xFF
    jne tc
    mov [ps2_a], byte 0x00

    cli 
    ; обязательно на время прерывания мыши очищать ее
    ; иначе могут вознинуть "артефакты", когда при отрисовке мыши она снова появляется
    call mouse_hide

    call mouse_show

    ; call bk2front ; скопировать задний буфер на фронт
    sti
    jmp tc

WINDOW_TEST:

    call WINDOW_TEST
    mov rax, [ps2_x]
    mov rbx, [ps2_y]
    mov rcx, rax
    mov rdx, rbx
    add rcx, 640
    add rdx, 480

    vc5 canvas_block,[rpx],[rpy],641,481,0x000080

    mov [rpx], rax
    mov [rpy], rbx

    vc5 canvas_block,rax,rbx,640,480,0x00

    vc5 canvas_block,rax,rbx,1,480,0xc0c0c0
    vc5 canvas_block,rax,rdx,640,1,0xc0c0c0
    vc5 canvas_block,rcx,rbx,1,480,0xc0c0c0

    vc5 canvas_block,rax,rbx,640,16,0xffffff

    add rax, 4
    add rbx, 4
    vc4 canvas_monotext,rax,rbx,0x00,txt1
    vc4 canvas_monotext,rax,rbx,0x00,txt1

    ret

; ----
txt1 db 'Окно, которое таскается само по себе', 0
rpx  dq 0
rpy  dq 0

; ----------------------------------------------------------------------------------------

    ; Обработчики
    include 'lib64/handler/clock.asm'
    include 'lib64/handler/keyb.asm'
    include 'lib64/handler/mouse.asm'
    include 'lib64/handler/exceptions.asm'

    ; Системные
    include 'lib64/sys.asm'
    include 'lib64/pio.asm'
    include 'lib64/idt.asm'
    include 'lib64/memory.asm'

    ; Устройства
    include 'lib64/ps2.asm'

    ; Функции рисования на экране
    include 'lib64/canvas/drawing.asm'
