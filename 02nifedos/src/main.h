#include "io.h"
#include "ata.h"
#include "fdc.h"
#include "pic.h"
#include "ps2mouse.h"
#include "vga.h"
#include "stdio.h"
#include "stdlib.h"
#include "fs.h"
#include "gui.h"

// Инициализация устройств
void startup() {

    vg_init(); // Инициализировать видеоадаптер

    // Простановка IRQ
    irq_init(IRQ_KEYB | IRQ_FDC | IRQ_CASCADE | IRQ_PS2MOUSE);

    init_ata_devices();     // Найти ATA
    fdc_init();             // Инициализировать FDD
    ps2_init_mouse();       // Обнаружить мышь
    gui_init();             // gui.c
    stdlib_init();          // stdlib.c

    sti; // Включить прерывания
}
