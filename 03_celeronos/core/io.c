/*
 * Писать в (port) данные data
 */
static inline void IoWrite8(u16 port, u8 data)
{
    __asm__ volatile("outb %b0, %w1" : : "a" (data), "Nd" (port));
}

static inline void IoWrite16(unsigned short port, unsigned short data)
{
    __asm__ volatile("outw %w0, %w1" : : "a" (data), "Nd" (port));
}

/*
 * Читать данные из порта (port)
 */
 
static inline u8 IoRead8(u16 port)
{
    u8 data;    
    __asm__ volatile("inb %1, %0" : "=a" (data) : "Nd" (port));
    return data;
}

static inline u16 IoRead16(u16 port)
{
    u16 data;
    __asm__ volatile("inw %1, %0" : "=a" (data) : "Nd" (port));
    return data;
}
