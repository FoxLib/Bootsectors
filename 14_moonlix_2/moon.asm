; Компиляция и запись на виртуальный диск для тестирования
; fasm moon.asm && ./update moon.bin flash.img && bochs -f boot.bxrc -q

    include 'lib/macros.asm'    ; Макросы
    include 'lib/variables.asm' ; Указатели на фиксированные переменные'

; Начало кода здесь 0:0xC000
    
    org 0xC000

    cli
    cld
    call create_initial_gdt     ; Создание первичных дескрипторов [lib/rmode.asm]    
    pm_jump                     ; Переходим в "Protected Mode" (защищенный режим)

    include 'lib/rmode.asm'     ; Функции реального режима
    include 'lib/rvm.asm'       ; V86 точка входа

; Само ядро начинается с этого адреса. Предыдущий код становится недоступным
; ==========================================================================================
PROTECTED_MODE_CODE:
; ==========================================================================================

    org 0
    use32    

    pm_init    
    irq_redirect 1110111111111000b ; Переброс IRQ (PIC) и установка маски [lib/bootstrap.asm]

    call CLEAR_memory ; Очистить системную память
    call INT_setup    ; Инициализация всех системных прерываний [lib/bootstrap.asm]  
    call PS2_mouse    ; Инициализация мыши
    call TIMER_init   ; 100 Hz системный таймер
    call MAX_memory   ; Расчет максимально доступной памяти
    call PAGING_init  ; Инициализация страничной адресации по размеру памяти

    ; Основные задачи
    task_create TASK_main,  TSS_general, TC          ; Создание задачи ядра (TSS=0x28) [variables.asm]
    task_create TASK_timer, TSS_timer,   IRQ_0_TASK  ; Создание задачи таймера [lib/irq.asm]
    task_create TASK_vm,    TSS_VM,      0           ; Создание задачи VM / не требуется

    ; Инициализация сегментов и указателей
    call VM_initialize

    ; Определение жестких дисков через IDENTIFY и их перечисление
    call ATA_init_devices ; [lib/fs/ata.asm]

    ; Включаем многозадачность
    ; Сегмент 0x28 становится Busy 32bit TSS
    load_task TASK_main

    ; -- отладка fpu только при отключенном task switching ---
 ;brk ; место для долбления головой

    ; Запуск основной программы
    jmp Main_Application ; [app/main/main.asm]

; Функции для оболочки
; ------------------------------------------------------------------------------------------

    include 'lib/loader.asm'    ; Загрузчик кода
    include 'app/main/main.asm' ; Основная программа (можно менять источник)
    include 'lib/data.asm'      ; Данные
