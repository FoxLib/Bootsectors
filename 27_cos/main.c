#include "main.h"
#include "ata.h"
#include "fdc.h"
#include "pic.h"
#include "ps2mouse.h"
#include "vga.h"

void main() {

    irq_init(IRQ_KEYB | IRQ_FDC | IRQ_CASCADE | IRQ_PS2MOUSE);

    init_vg();
    init_ata_devices();
    fdc_init();
    ps2_init_mouse();

    vg_block(0,0,639,479,3);
    vg_ttf_print(8,8,"Hello World!",15);

    sti;
	for(;;);
}
