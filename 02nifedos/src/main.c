#include "io.h"
#include "ata.h"
#include "fdc.h"
#include "pic.h"
#include "ps2mouse.h"
#include "vga.h"
#include "main.h"

void main() {

    startup();

    block(0, 0, 1123, 767, CL_CYAN);

    int xp = -1, yp = -1;
    for(;;) {

        cli; // -- обязательно
        if (ps2.x != xp || ps2.y != yp) {

            line(xp, yp, ps2.x, ps2.y, CL_WHITE);
            xp = ps2.x;
            yp = ps2.y;
        }
        sti;
    }
}
