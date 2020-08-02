#include "main.h"

void main() {

    startup();

    cls(CL_CYAN);

    gui_draw_window("Съешь еще этих мягких французских булок да выпей чаю", 32, 32, 480, 320);

    // fdc_read(0);

    for(;;) {

        handle_mouse_action();
    }
}
