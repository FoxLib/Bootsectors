
// Процедура, которая переводит IRQ с их стандартных позиции из R-Mode в P-Mode
void kernel_pic_redirect(int bitmask) {   

    apic_disable();    

    // Запуск последовательности инициализации (в режиме каскада)
    IoWrite8(PIC1_COMMAND, ICW1_INIT + ICW1_ICW4); IoWait;
    IoWrite8(PIC2_COMMAND, ICW1_INIT + ICW1_ICW4); IoWait;

    IoWrite8(PIC1_DATA, 0x20); IoWait; // ICW2: Master PIC vector offset 0x20 .. 0x27    
    IoWrite8(PIC2_DATA, 0x28); IoWait; // ICW2: Slave PIC vector offset 0x28 .. 0x2F

    IoWrite8(PIC1_DATA, 4); IoWait; // ICW3: послать сигнал на Master PIC, что существует slave PIC at IRQ2 (0000 0100)    
    IoWrite8(PIC2_DATA, 2); IoWait; // ICW3: сигнал Slave PIC на идентификацию каскада (0000 0010)

    // 8086/88 (MCS-80/85) режим (master/slave)
    IoWrite8(PIC1_DATA, ICW4_8086); IoWait;
    IoWrite8(PIC2_DATA, ICW4_8086); IoWait;

    // Записать маски (полностью блокировать прерывания)
    IoWrite8(PIC1_DATA, 0xff); IoWait;
    IoWrite8(PIC2_DATA, 0xff); IoWait;

    // Размаскировать некоторые прерывания
    IoWrite8(PIC1_DATA, IoRead8(PIC1_DATA) & (~bitmask & 0xff));
    IoWrite8(PIC2_DATA, IoRead8(PIC2_DATA) & ((~bitmask >> 8) & 0xff)); 
}
