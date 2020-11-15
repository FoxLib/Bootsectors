
#include "kernel.h"
#include "kernel/fs.h"
#include "kernel/mm.h"
#include "kernel/task.h"
#include "kernel/core.h"
#include "kernel/canvas.h"
#include "kernel/string.h"

#include "app/desktop.h"

// Видеоадаптер
#include "kernel/vga/driver.h"
#include "kernel/vga/driver.c"

// Отрисовка
#include "kernel/canvas.c"
#include "kernel/gui.c"

// Устройства
#include "kernel/timer.c"
#include "kernel/keyboard.c"
#include "kernel/ps2mouse.c"

// Ядро
#include "kernel/string.c"
#include "kernel/fs.c"
#include "kernel/mm.c"
#include "kernel/pic.c"
#include "kernel/task.c"
#include "kernel/core.c"

// GDI, USER, etc
#include "api/gdi.h"
#include "api/gdi.c"

// Некоторые "приложения"
#include "app/desktop.c"
#include "app/miner.c"

/* Данная ОС работает только в Bochs, и не работает больше нигде пока */
// ---------------------------------------------------------------------

void main() {

    init(0); mouse_show(1); cls(3);

    make_desktop();
    make_miner();

    // http://www.sig9.com/articles/att-syntax
    // ljmp	*(%eax)			jmp  far  [eax]

    panel_repaint();
    sti; for(;;);
}
