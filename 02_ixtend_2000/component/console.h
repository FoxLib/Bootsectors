// Текстовый буфер ввода для терминала (2 экрана) 24kb
uint16_t terminal_buffer[128 * 48 * 2];

void console_constructor();
void console_redraw();
