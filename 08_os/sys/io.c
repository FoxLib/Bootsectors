/*
 * Писать в (port) данные data
 */
static inline void IoWrite8(u16 port, u8 data)
{
    __asm__ volatile("out %w0, %b1" : : "Nd" (port), "a" (data));
}

static inline void IoWrite16(u16 port, u16 data)
{
    __asm__ volatile("out %w0, %w1" : : "Nd" (port), "a" (data));
}

/*
 * Читать данные из порта (port)
 */
 
static inline u8 IoRead8(u16 port)
{
    u8 data;
    __asm__ volatile("in %b0, %w1" : "=a" (data) : "Nd" (port));
    return data;
}

static inline u16 IoRead16(u16 port)
{
    u16 data;
    __asm__ volatile("in %w0, %w1" : "=a" (data) : "Nd" (port));
    return data;
}
