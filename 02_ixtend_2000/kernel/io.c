// Макрос для вызова rep outsw
#define IoWriteSW(port, addr, cnt) io_port = port; io_addr = addr; io_count = cnt; IoOutSW();

// Макрос для вызова rep insw
 /* Из-за этого компилятора и моей криворукости */
 /* Я записываю сначала в память */
 /* А потом читаю из nasm-процедуры */
 /* Как же это тупо... */
 
#define IoReadSW(port, addr, cnt) io_port = port; io_addr = addr; io_count = cnt; IoInSW();         

// Процедура необходимой задержки для корректной работы прерываний
#define IoWait asm volatile("jecxz 1f" "\n\t" "1:jecxz 2f" "\n\t" "2:");

// Писать в (port) данные data
static inline void IoWrite8(int16_t port, int8_t data) {
    
    __asm__ volatile("outb %b0, %w1" : : 
        "a" (data), 
        "Nd" (port));
}

static inline void IoWrite16(int16_t port, int16_t data) {
    
    __asm__ volatile("outw %w0, %w1" : : 
        "a" (data), 
        "Nd" (port));
}

static inline void IoWrite32(int16_t port, int32_t data) {
    
    __asm__ volatile("outl %0, %w1" : : 
        "a" (data), 
        "Nd" (port));
}

// Читать данные из порта (port)
static inline uint8_t IoRead8(int16_t port) {
    
    uint8_t data;  
      
    __asm__ volatile("inb %1, %0" : 
        "=a" (data) :
        "Nd" (port));
         
    return data;
}

static inline uint16_t IoRead16(int16_t port) {
    
    uint16_t data;
    
    __asm__ volatile("inw %1, %0" : 
        "=a" (data) : 
        "Nd" (port));
        
    return data;
}


static inline uint32_t IoRead32(int16_t port) {
    
    uint32_t data;
    
    __asm__ volatile("inl %1, %0" : 
        "=a" (data) : 
        "Nd" (port));
        
    return data;
}

