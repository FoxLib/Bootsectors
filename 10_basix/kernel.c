#include "kernel.h"
#include "kernel/strings.h"
#include "kernel/strings.c"
#include "mm/helpers.c"
#include "mm/palloc.c"
#include "mm/kalloc.c"
#include "fs/vfs.c"
#include "pci/init.c"
#include "display/util.c"
#include "display/vga.c"
#include "kernel/pic_redirect.c"
#include "kernel/pic_keyb.c"
#include "kernel/app.c"
#include "kernel/isr_init.c"
#include "kernel/init.c"
#include "ui/put_image.c"
#include "ui/start.c"
#include "ui/handler.c"

// ---------------------------------------------------------------------

void main() {

    kernel_init();
    pci_init();
    kernel_pic_redirect(IRQ_KEYB);
    kernel_isr_init();
    fs_init();
    
    ui_init();    
    ui_start();
    
    // BIN-это откомпилированная программа    
    int app_id = app_load_raw("app/desktop.raw");
    //int app_id = app_load_raw("app/testing.raw");
    
    // передача кванта времени приложению
    app_start(app_id);
    
    
    sti;
    for(;;);
}
