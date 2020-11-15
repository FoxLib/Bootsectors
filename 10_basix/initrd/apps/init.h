// ---------------------------------------------------------------------
#define brk asm volatile("xchg %bx, %bx");

#define int8_t      signed char
#define uint8_t     unsigned char

#define int16_t     signed short
#define uint16_t    unsigned short

#define int32_t     signed int
#define uint32_t    unsigned int

#define int64_t     long long
#define uint64_t    unsigned long long

// ---------------------------------------------------------------------

#define KCALL_VIDEO         1               // Видеосервис
#define KCALL_FILES         2               // Файлы
#define KCALL_PROCESS       3               // Взаимодействие процессов

// Обработка вызова Kernel
uint32_t kcall(uint32_t func_id, uint32_t params);
