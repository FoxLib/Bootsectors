// ---------------------------------------------------------------------
#include "kernel/kernel.h"
#include "kernel/io.c"
#include "kernel/isr.c"
#include "kernel/vesafb.h"
#include "kernel/vesafb.c"
#include "kernel/piodisk.c"
#include "kernel/functions.c"
#include "kernel/filesystem.c"
#include "kernel/windows.c"
// ---------------------------------------------------------------------
#include "component/console.h"
#include "component/console.c"

void main() {

    constructor();
    fbvesa_set();
    isr_create();
    
    console_redraw();

    sti;
    
    // Ожидание наступления событий
    while(1) {
        
        keyboard_getch();        
    }
}
