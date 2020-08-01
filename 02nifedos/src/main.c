#include "io.h"
#include "ata.h"
#include "fdc.h"
#include "pic.h"
#include "ps2mouse.h"
#include "vga.h"
#include "stdio.h"
#include "main.h"

void main() {

    startup();

    block(0, 0, 1024, 768, CL_CYAN);

    block(100, 100, 480, 300, C(0xd5d5d5));
    lineb(100, 100, 480, 300, 0);
    block(102, 102, 478, 124, C(0x77b584));
    ttf_print(107, 109, "Introduction to Nifedov OS", 0);
    ttf_print(106, 108, "Introduction to Nifedov OS", 0xffff);

    print("Hello, worldart!");

    fdc_read(0);

    int xp = -1, yp = -1;
    for(;;) {
        // ..
    }
}
