#include "keyb.h"

// Текущее положение в буфере
u32 keyb_buffer_ptr = 0;

/* 
 * Регистрация прерывания клавиатуры
 */

void dev_keyb_isr()
{
    u8 key = IoRead8(0x60);

    // Определить нажатые в текущий момент клавиши
    if (key & 0x80) {
        mem_keyb_pressed[key & 0x7f] = 0;
    } else {
        mem_keyb_pressed[key] = 255;
    }

    // SHIFT, CTRL, ALT...
    if (key == KEY_LSHIFT || 
        key == KEY_RSHIFT || 
        key == KEY_LALT || 
        key == KEY_LCTRL || 
        key == 0xe0) {
        return;
    }

    // Добавление в клавиатурный буфер
    mem_keyb_buffer[ keyb_buffer_ptr++ ] = key;
}

/*
 * Получить следующий символ. Выполнить трансляцию из скан-кода
 */ 

u8 dev_keyb_get() 
{
    u8 key = 0;
    u16 i;

    // Произвести извлечение символа
    // Отключить прерывания на время получения
    if (keyb_buffer_ptr) {

        cli; 

        key = mem_keyb_buffer[0];

        // Сдвинуть буфер на 1 символ 
        for (i = 0; i < keyb_buffer_ptr; i++) 
            mem_keyb_buffer[i] = mem_keyb_buffer[i + 1];

        keyb_buffer_ptr--;

        sti;
    }

    return key;
}

/*
 * Тест клавиши
 */

u8 dev_key_test(u8 k) {
    return mem_keyb_pressed[k] ;
}

/*
 * Выполнить трансляцию символа
 */

u8 dev_key_ascii(u8 scan)
{
    scan &= 0x7f;

    // Если зажат SHIFT, получить значение из верхнего регистра
    if (dev_key_test(KEY_LSHIFT) || 
        dev_key_test(KEY_RSHIFT) ) {
        return dev_keyb_scan2ascii_HI[scan];

    } else {

        return dev_keyb_scan2ascii[scan];
    }
}