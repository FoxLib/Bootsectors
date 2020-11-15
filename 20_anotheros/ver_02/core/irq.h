
/** Обращения к startup.asm */
void  INT_null();
void  IRQ_timer();
void  IRQ_keyboard();
void  IRQ_ps2mouse();
void  IRQ_fdc();
void  IRQ_cascade();
void  IRQ_master();
void  IRQ_slave();
void  delay();

/** Прототипы */
dword get_timer();
void  irq_redirect(uint);
void  irq_make(dword, void*, byte);
void  irq_init(uint);

/** Переменные */
dword timer;
