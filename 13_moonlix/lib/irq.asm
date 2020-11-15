include "irq/irq0_timer.asm"
include "irq/irq1_keyb.asm"
include "irq/irqC_mouse.asm"

;Master PIC
;IRQ 0 – system timer (cannot be changed)
;IRQ 1 – keyboard controller (cannot be changed)
;IRQ 2 – cascaded signals from IRQs 8–15 (any devices configured to use IRQ 2 will actually be using IRQ 9)
;IRQ 3 – serial port controller for serial port 2 (shared with serial port 4, if present)
;IRQ 4 – serial port controller for serial port 1 (shared with serial port 3, if present)
;IRQ 5 – parallel port 2 and 3  or  sound card
;IRQ 6 – floppy disk controller
;IRQ 7 – parallel port 1. It is used for printers or for any parallel port if a printer is not present. It can also be potentially be shared with a secondary sound card with careful management of the port. 

; Slave PIC
;IRQ 8 – real-time clock (RTC)
;IRQ 9 – Advanced Configuration and Power Interface system control interrupt on Intel chipsets.[1] Other chipset manufacturers might use another interrupt for this purpose, or make it available for the use of peripherals (any devices configured to use IRQ 2 will actually be using IRQ 9)
;IRQ 10 – The Interrupt is left open for the use of peripherals (open interrupt/available, SCSI or NIC)
;IRQ 11 – The Interrupt is left open for the use of peripherals (open interrupt/available, SCSI or NIC)
;IRQ 12 – mouse on PS/2 connector
;IRQ 13 – CPU co-processor  or  integrated floating point unit  or  inter-processor interrupt (use depends on OS)
;IRQ 14 – primary ATA channel
;IRQ 15 – secondary ATA channel (ATA interface usually serves hard disks and CD drives)

; ========================================================= PRIMARY

; --------------------------------------------------------- СИСТЕМНЫЙ ТАЙМЕР

; Системный таймер
; Пока что выполняет функцию таймера, но не является прерыванием 
; выполнения задачи на данный момент

IRQ_0:

    save_state
    call irq0_timer
    eoi_master
    load_state    
    iret

; --------------------------------------------------------- КЛАВИАТУРА
IRQ_1:

    brk
    save_state
    call irq1_keyb
    eoi_master   
    load_state
    iret

; --------------------------------------------------------- КАСКАД НА SLAVE
IRQ_2:

    save_state
    eoi_master   
    load_state
    iret

; ---------------------------------------------------------
IRQ_3:

    save_state
    eoi_master   
    load_state
    iret    

; ---------------------------------------------------------
IRQ_4:

    save_state
    eoi_master   
    load_state
    iret    

; ---------------------------------------------------------
IRQ_5:

    save_state
    eoi_master   
    load_state
    iret  

; ---------------------------------------------------------
IRQ_6:

    save_state
    eoi_master   
    load_state
    iret 

; ---------------------------------------------------------
IRQ_7:

    save_state
    eoi_master   
    load_state
    iret

; ========================================================= SLAVE
IRQ_8:

    save_state
    eoi_slave   
    load_state
    iret

; ---------------------------------------------------------
IRQ_9:

    save_state
    eoi_slave   
    load_state
    iret 

; ---------------------------------------------------------
IRQ_A:    

    save_state
    eoi_slave   
    load_state
    iret 

; ---------------------------------------------------------
IRQ_B:

    save_state
    eoi_slave   
    load_state
    iret

; ---------------------------------------------------------
IRQ_C:

    save_state

    call PS2_mouse_handler ; [lib/mouse/ps2.asm]
    eoi_slave   
    load_state
    iret    

; ---------------------------------------------------------
IRQ_D:

    save_state
    eoi_slave   
    load_state
    iret    

; ---------------------------------------------------------
IRQ_E:

    save_state
    eoi_slave   
    load_state
    iret    

; ---------------------------------------------------------
IRQ_F: ; Срабатывает каскад с IRQ-2 / PS2

    save_state
    eoi_slave   
    load_state
    iret    
