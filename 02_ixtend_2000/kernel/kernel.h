
// Некоторые ассемблерные вставки
#define brk __asm__ __volatile__("xchg %bx, %bx");
#define cli __asm__ __volatile__("cli");
#define sti __asm__ __volatile__("sti");

// Типы данных
// См. http://ru.cppreference.com/w/cpp/language/types
#define int8_t      signed char
#define uint8_t     unsigned char

#define int16_t     signed short
#define uint16_t    unsigned short

#define int32_t     signed int
#define uint32_t    unsigned int

#define int64_t     long long
#define uint64_t    unsigned long long

// Порты ввода-вывода
static inline void IoWrite8(int16_t port, int8_t data);
static inline void IoWrite16(int16_t port, int16_t data);
static inline uint8_t IoRead8(int16_t port);
static inline uint16_t IoRead16(int16_t port);

// Прототипы
void _irq_isr_null();
void isr_timer();
void isr_keyboard();
void isr_cascade();
void apic_disable();
void fbvesa_set();

extern void IoOutSW();     // rep outsw
extern void IoInSW();      // rep insw

uint16_t io_port;
uint64_t io_addr;
uint64_t io_count;

// Постоянный указатель на начало памяти
uint8_t  * m8;
uint16_t * m16;
uint32_t * m32;
uint64_t * m64;

// Указатель на начало видеопамяти
uint16_t * fb_vesa; 
