#include "main.h"

void main() {

    startup();

    cls(CL_CYAN);

    gui_draw_window("Just Hello World Application", 32, 32, 320, 240);
    // fdc_read(0);

    for(;;) {

        handle_mouse_action();
    }
}
