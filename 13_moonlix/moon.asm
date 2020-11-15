; Компиляция и запись на виртуальный диск для тестирования
; ----------------------------------------------------------------------
; fasm moon.asm && ./update moon.bin flash.img && bochs -f boot.bxrc -q

    include 'lib/macros.asm'    ; Макросы
    include 'lib/variables.asm' ; Указатели на фиксированные переменные'

; Начало кода здесь 0:0xC000
    
    org 0xC000

    cli
    cld
    call create_initial_gdt     ; Создание первичных дескрипторов [lib/rmode.asm]        
    pm_jump                     ; Переходим в "Protected Mode" (защищенный режим)
    jmp 0x0008 : PROTECTED_MODE_CODE  

    ; Функции для реального режима
    include 'lib/rmode.asm'  

; Само ядро начинается с этого адреса. Предыдущий код становится недоступным
; ==========================================================================================
PROTECTED_MODE_CODE:
; ==========================================================================================

    use32    
    
    pm_init    
    irq_redirect 1110111111111000b ; Переброс IRQ (PIC) и установка маски [lib/bootstrap.asm]   

    call I80_clrscr  ; 80x25 перекрасить экран

    ; ---------------------    
    call CLEAR_memory ; Очистить системную память
    invk1 I80_log, const.log1_clear_memory
    
    call INT_setup    ; Инициализация всех системных прерываний [lib/bootstrap.asm]  
    invk1 I80_log, const.log1_interrupt_setup
    
    call PS2_mouse    ; Инициализация мыши
    invk1 I80_log, const.log1_ps2mouse
    
    call TIMER_init   ; 100 Hz системный таймер
    invk1 I80_log, const.log1_timer_init
    
    call MAX_memory   ; Расчет максимально доступной памяти [lib/memory.asm]
    invk1 I80_log, const.log1_getmax_mem
    
    call PAGING_init  ; Инициализация страничной адресации по размеру памяти [lib/memory.asm]
    invk1 I80_log, const.log1_paging_ok
    
    call enable_sse   ; Включение поддержки SSE (или зависание)
    invk1 I80_log, const.log1_sse_enabled
    ; ---------------------
     
    ; Основные задачи
    task_create TASK_main,  TSS_general, main_application ; Создание задачи ядра (TSS=0x28) [variables.asm]

    ; Определение жестких дисков через IDENTIFY и их перечисление

    call ATA_init_devices ; [lib/fs/ata.asm]    
    invk1 I80_log, const.log1_ata_initialized

    ; Включаем многозадачность
    ; Сегмент 0x28 становится Busy 32bit TSS
    load_task TASK_main

    ; Запуск основной программы
    jmp main_application ; [app/main/main.asm]

; Функции для оболочки
; ------------------------------------------------------------------------------------------

	include 'lib/const.asm'		   		 ; Системные константы (строки)
	include 'lib/glob.asm'				 ; Глобальные переменные

    include 'lib/loader.asm'    ; Загрузчик кода
    include 'app/mc/main.asm'   ; Основная программа
    include 'lib/data.asm'      ; Данные
