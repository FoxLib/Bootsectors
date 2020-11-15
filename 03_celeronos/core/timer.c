// Настройка таймера на частоту 100 Гц
void sys_timer_init() {

    IoWrite8(0x43, 0x34);
    IoWrite8(0x40, 0x9B);
    IoWrite8(0x40, 0x2E);   
    
}

// Обработка системного таймера
void timer_ticker() {
    
    // brk;
    
}