#include "main.h"

void main() {

    startup();

    cls(CL_CYAN);

    gui_draw_window("Любя, съешь щипцы, - вздохнёт мэр, - кайф жгуч.", 32, 32, 480, 320);

    for(;;) {

        handle_mouse_action();
    }
}
