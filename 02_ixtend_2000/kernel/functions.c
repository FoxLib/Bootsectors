// Установка важных указателей
void constructor() {
	
    m8  = (uint8_t *)  0;
    m16 = (uint16_t *) 0;
    m32 = (uint32_t *) 0;
    m64 = (uint64_t *) 0;

    // Инициализая буфера клавиатуры
    keyboard_constructor();    
}
