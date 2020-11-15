#include "kernel.h"
#include "kernel/pic_redirect.c"
#include "display/util.c"
#include "ui/start.c"

void main() {

    kernel_pic_redirect(0);    
    ui_start();
    for(;;);
}
