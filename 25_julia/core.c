#include "core/kernel.h"

void main() {

    kernel_init_PIC8086(IRQ_KEYB);

    for(;;);
}