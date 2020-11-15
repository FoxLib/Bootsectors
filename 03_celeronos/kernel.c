#include "core/defines.h"
#include "core/io.c"
#include "core/irq.c"
#include "core/memory.c"

#include "core/vga.c"
#include "core/font/tahoma.c"

#include "core/device/keyb.c"
#include "core/timer.c"
#include "core/device/mouse.c"
#include "core/user_interface.c"

// --- Стартовые процедуры ---
#include "core/start.c"

/*
 * Здесь начинается ядро
 */

void __kernel() {

	// [core/start.c] Основные инициализации
    startup();

    // Показать экран
    printzs(8,16,"I'm best of the best", 7);

	ui_draw_window(20, 50, 560, 240, "Cozy Atmosphere: CharTable");
   
    // int i; for (i = 0; i < 256; i++) printc(30 + (i % 64)*8, 90 + 16 * (i/64), i, 0);
    font_tahoma_prints_bold(30, 90, "Helloz Peoples!?!  ~ Hi! ~ I`m Mystyca....01&2+3(=) >>  ^_^ 0_O", 0);

    sti;   
    while(1); /* Никогда не возвращаться из цикла */
}
