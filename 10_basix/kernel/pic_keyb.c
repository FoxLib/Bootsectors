uint8_t keyb_press[32];
uint8_t keyb_buffer[256];

// Неблокирующий метод на получение символа с клавиатуры (если он есть)
uint8_t kernel_pic_keyb_getchar() {
 
    return 0;   
}

// Обработка нажатии клавиатуры
void kernel_pic_keyb() {
    
    brk;

    uint8_t key = IoRead8(0x60);
    
    // Запись в буфер (с ограничением)
    if (keyb_buffer_position < 255) {        
        
        keyb_buffer[ keyb_buffer_position] = key;
        keyb_buffer_position++;    
    }
}
