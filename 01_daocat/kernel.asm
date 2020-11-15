    
    Debug equ 1

; Ассемблирование и выполнение
; --------------------------------
; # Ассемблирование, запись файла loader16.run 
; fasm kernel.asm && php tools/fat32.php disk.img write loader16.run kernel.bin
;
; # Запуск bochs
; bochs -f dao.bxrc -q
; --------------------------------

    ORG 0
    jmp main

    ; Заголовочные файлы
    include "core/decl/macro.asm"      ; Макросы
    include "core/decl/memorymap.asm"
    include "core/decl/stack.asm"
    include "core/decl/tss.asm"
    include "core/decl/types.asm"
    include "core/decl/gdt.asm"        ; Таблица GDT

    ; Общие функции ядра
    include "core/sys.asm"
    include "core/memory.asm"

    ; Конфигурирование VESA
    include "core/driver/vesa/realmode.asm"

main:

    use16

    cli   
    call vesa_set           ; Включение VESA    
    call set_descriptors    ; Инициализация загрузочных дескрипторов
    
    mov eax, cr0
    or  al,  1
    mov cr0, eax

    ; Выполняем "прыжок в 8-селектор"
    jmp SEGMENT_CORE_CODE : start_protected_mode

; ----------------------------------------------------------------------------------------------------------------------
; Здесь начинается работа в защищенном режиме
; ----------------------------------------------------------------------------------------------------------------------

start_protected_mode:

    ; Код является 32-х разрядным, поэтому должно быть включено use32
    ; Если не включить этот код, в конвейер команд будет записан mov eax, вместо mov ax
    ; Поскольку процессор до перехода в защищенный режим записал в конвейер eax (будучи еще в режиме реальных адресов)

    use32     

    ; Важно загрузить теневые сегменты!
    ; Процессор после перехода в PM должен загрузить сегментные регистры 
    ; в их теневые копии

    mov ax, SGN_DATA
    mov ds, ax
    mov fs, ax
    mov gs, ax

    ; Инициализация сегмента стека
    mov ax, SEGMENT_CORE_STACK
    mov ss, ax
    mov sp, 0xF000
    
    ; Загрузка новых векторов прерываний
    call set_interrupts 
    
    ; ---
    mov  ah, 11111000b     ; 0=Timer, 1=Keyboard, 2=Каскад
    call IRQ_mask_master   ; Разрешение прерываний IRQ-Master

    mov  ah, 11101111b
    call IRQ_mask_slave    ; Разрешение прерываний IRQ-Slave
    ; ---

    call memory_paged_init ; Общая разметка памяти для первого мегабайта
    call set_tss           ; Установка двух главных tss

    ; Загрузка LTR
    mov ax,   SEGMENT_TSS0 
    ltr ax 

    mov ax,   SEGMENT_GDT
    mov ds,   ax
    and byte [SEGMENT_TSS0 + 5], 0xFD

    ; Перед тем как переключить задачу, надо сбросить бит Busy,
    ; который находится в GDT. Его туда поставил LTR
    ; ---
    ; А теперь немного истории. Из-за этой одной только инструкции я потратил на поиск бага аж 4 часа!
    ; Я даже начал читать коды Bochs, чтобы выяснить, что такое происходит при переключении задач.
    ; Оказалось все проще, как я и думал (а я так и думал, но не знал, где). И вот - когда загружаем 
    ; LTR, в дескриптор, куда указывает селектор TSS, ставится флаг "Busy" = 1, и процессор не переходит
    ; на задачу, которая и так уже Busy.
    ; ---
    ; p.s. процессор не может сменить задачу на собственную же после загрузки ltr, с использованием jump far.

    mov ax, SGN_DATA
    mov ds, ax

    ; Инициализация PS/2, COM-мыши
    call init_ps2_mouse

    ; Очистка элементов списка UI
    call events_clear

    ; Инициализация базовых элементов рабочего стола
    call basic_desktop_components_register

    ; После Full Repaint в сегменте es << video segment
    call full_repaint

    ; Установка координат мыши
    call ui_init_mouse

    ; Таймер, 100 герц
    call kernel_set_timer_100

    ; Первая отрисовка указателя мыши
    call ui_mouse_enable

    sti 

    ; Разрешить прерывания и запустить ожидание, когда сработает IRQ-0
    ; Когда он сработает, он и будет проводить процесс диспетчеризации

    jmp $+0

; --------------------------------------------------------------------------------------------------------------------
; НАЧАЛО РАБОТЫ ЯДРА
; --------------------------------------------------------------------------------------------------------------------

kernel_loop:

    hlt
    jmp kernel_loop

; Возврат из прерывания события
kernel_test:

    brk
    iret

; --------------------------------------------------------------------------------------------------------------------
; TIMER IRQ
; При переходе на эту задачу у нее должен быть очищен флаг Busy
; --------------------------------------------------------------------------------------------------------------------

timer_loop:        

    cli

    ; Переключиться на задачу
    ; Только надо принудительно очистить флаг busy - потому что задача была прервана по причине Interrupt

    mov ax, SEGMENT_GDT
    mov fs, ax
    and byte [fs:SEGMENT_TSS0 + 5], 0xFD

    ; Ставим другой EIP
    mov ax, SEGMENT_TSS_RW
    mov fs, ax
    mov dword [fs:TSS_EIP], kernel_loop 

    ; Отослать EOI
    mov  al, 0x20
    out  0x20, al

    sti    

      ; Диспетчеризация
      db 0xEA
      dd 0
dtss  dw SEGMENT_TSS0 ; Здесь должен быть открыт сегмент на чтение

    ; Вернуться в основной цикл, после переключения задач через Interrupt
    jmp timer_loop

; ----------------------------------------------------------------------------------------------------------------------
; Код. Встроенные драйвера и обработчики
; ----------------------------------------------------------------------------------------------------------------------
    
    use32

    ; Ядро
    include "core/events.asm"
    include "core/ui.asm"
    include "core/interrupts.asm"
    include "core/driver/vesa/primitives.asm"

    ; Пользовательский интерфейс
    include "core/ui/desktop.asm"
    include "core/ui/mouse.asm"

    ; Драйвера
    include "core/driver/peripherals/mouse.asm"
    include "core/driver/peripherals/keyboard.asm"

END_OF_CODE = $

; ----------------------------------------------------------------------------------------------------------------------
; Данные. Читать из Protected Mode
; ----------------------------------------------------------------------------------------------------------------------

    ORG 0

    include "core/decl/graphics.asm"
    include "core/decl/strings.asm"       ; Системные строки
    include "core/decl/ints.asm"
    include "core/decl/sysdata.asm"       ; Общесистемные данные
    include "core/decl/ui_components.asm" ; Данные основных UI-компонентов задачи ядра

    include "core/ui/icons.asm"

    ; Описатель базовых прерываний
    include "core/fonts/std_6_11.asm"

END_OF_DATA = $