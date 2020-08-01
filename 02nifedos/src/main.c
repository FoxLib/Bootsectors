#include "io.h"
#include "ata.h"
#include "fdc.h"
#include "pic.h"
#include "ps2mouse.h"
#include "vga.h"

void main() {

    irq_init(IRQ_KEYB | IRQ_FDC | IRQ_CASCADE | IRQ_PS2MOUSE);

    init_ata_devices();
    fdc_init();
    ps2_init_mouse();

    block(0,0,1023,767, rgb(0,128,128));
    ttf_print(8,8,"Hello World!", CL_WHITE);

    sti;
    for(;;) {

        pset(ps2.x, ps2.y, CL_WHITE);

    }
}
