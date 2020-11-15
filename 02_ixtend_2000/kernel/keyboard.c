
// Инициализация пере
void keyboard_constructor() {
    
    long i;
    for (i = 0; i < 256; i++) {
        
        keyb_state[i]  = 0;
        keyb_buffer[i] = 0;
    }
    
    keyb_start = 0;
    keyb_end = 0;
}

// Регистрация прерывания клавиатуры
void keyboard_isr()
{
    uint8_t key = IoRead8(0x60);
    
    // Запись статуса клавиши - нажата или нет
    keyb_state[ key & 0x7f ] = (key & 0x80) ? 0 : 0xff;

    // Управляющие клавиши SHIFT, CTRL, ALT...
    if (key == KEY_LSHIFT || key == KEY_RSHIFT || 
        key == KEY_LALT   || key == KEY_LCTRL  || key == 0xe0) 
    {
        return;
    }

    // Добавление в клавиатурный буфер
    keyb_buffer[ keyb_end ] = key;  
    keyb_end++;
}

// Получить следующий символ. Выполнить трансляцию из скан-кода
uint16_t keyboard_getch() 
{
    uint16_t key = 0;
    uint16_t i;

    // Взять следующий символ в циклическом буфере
    if (keyb_end != keyb_start) {
brk;
        cli; 

        key = keyb_buffer[ keyb_start ];
        keyb_start++;

        sti;
    }

    return key;
}

// Выполнить трансляцию символа
uint8_t keyboard_ascii(uint8_t scan)
{
    scan &= 0x7f;

    // Если зажат SHIFT, получить значение из верхнего регистра
    if (keyb_state[ KEY_LSHIFT ] || keyb_state[ KEY_RSHIFT ] ) {
        
        return keyb_ascii_hi[ scan ];

    } else {

        return keyb_ascii_lo[ scan ];
    }
}
