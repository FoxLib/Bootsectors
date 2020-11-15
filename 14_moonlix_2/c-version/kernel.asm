; Ядро может быть размером 64 кб

; bochs -f boot.bxrc -q
; qemu-system-i386 -fda fdd.img -m 32
; 
; sudo dd if=fdd.img of=/dev/sdf

    org 0x8000
    use16

    include 'macro/basic.asm'

    ;BRK

    ; Отладка
    ; -------------------------------
    jmp  short @f

    ; Установка необходимых дескрипторов
@@: call set_descriptors

    ; Переход к PM
    mov eax, cr0
    or  al,  1    
    mov cr0, eax   

    ; Выполняем "прыжок в 8-селектор"
    jmp 8 : 0x0000 

    ; Загрузка первичной GDT происходит здесь
    include 'loader/pmenter.asm'
    include 'x64/hello.asm'

Protected_Core:

; -----------------------------------------------------------------------        
; ЯДРО OS PROTECTED MODE 32 bit
; -----------------------------------------------------------------------    
    org 0
    use32

    ; Данные ядра
    mov ax, 0x0010
    mov ds, ax

    ; Стек
    mov ax, 0x0018
    mov ss, ax
    mov es, ax
    mov esp, 0xFFFF

    ; Вся доступная память
    mov ax, 0x0020
    mov fs, ax
       
    ; Инициализация GS, прерываний, настройка PIC
    ; Настройка TSS / Paging, системного таймера    
    call bootstrap_main

    mov ax, 0x30 ; AX содержит селектор tss(0) см. TSS_SEG в memory.h
    ltr ax  ; после загрузки TSS сегмент становится BUSY [type=SYS_SEGMENT_BUSY_386_TSS]
    sti     ; Включаем прерывания

    ; "Зациклить" выполнение "Системного Монитора"
    jmp system_loop    

    ; Запускные функции ядра
    include 'loader/bootstrap.asm'         ; инициализация сегментов и прерываний
    include 'loader/console.asm'           ; работа с консолью
    include 'loader/kernel.asm'            ; ядро системы
    include 'loader/iomem.asm'             ; fasm-функции inb, outb

    ; Interrupts
    include 'ints/locator.asm'             ; fasm-заглушки 
    include 'ints/softint.asm'             ; функции ядра

    ; Драйвера
    include 'driver/ps2mouse.asm'          ; ps/2 мышь
    include 'driver/vga.asm'               ; VGA driver
    include 'driver/ata.asm'               ; ATA driver

    ; FS
    include 'fs/fat32.asm'                 ; FAT16/32 driver
 
    ; Ядро и отладочные приложения
    include 'generaltask/sysmon.asm'       ; системный монитор
    include 'generaltask/main.asm'         ; главная задача ядра (TSS)    
    include 'stdlib/syscall.asm'           ; библиотека основных системных вызовов
    include 'app/disassemble/main.asm'     ; встроенная в ядро функция дизассемблирования    

    ; Ассемблерные обертки для "c"
    include 'fasmcall/b8000_lib.asm'       
    include 'fasmcall/memory_alloc.asm'
    include 'fasmcall/ata.asm'