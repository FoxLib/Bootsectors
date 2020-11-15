#include "kernel.h"
#include "kernel/fs.h"
#include "kernel/mm.h"
#include "kernel/task.h"
#include "kernel/core.h"
#include "kernel/canvas.h"
#include "kernel/string.h"

#include "app/desktop.h"

// Графика
#include "kernel/vga.c"
#include "kernel/canvas.c"
#include "kernel/gui.c"

// Устройства
#include "kernel/timer.c"
#include "kernel/keyboard.c"
#include "kernel/ps2mouse.c"
#include "kernel/fdc.h"
#include "kernel/fdc.c"

// Ядро
#include "kernel/string.c"
#include "kernel/fs.c"
#include "kernel/mm.c"
#include "kernel/pic.c"
#include "kernel/task.c"
#include "kernel/core.c"

// GDI, USER, etc
#include "gdi/gdi.h"
#include "gdi/gdi.c"

// Некоторые "приложения"
#include "app/desktop.c"
#include "app/miner.c"

/* Данная ОС работает только в Bochs, и не работает больше нигде пока */
// ---------------------------------------------------------------------

void main() {

    init(0);
    mouse_show(1);
    cls(1);

    make_desktop();
    make_miner();

    panel_repaint();
    sti; for(;;);
}
