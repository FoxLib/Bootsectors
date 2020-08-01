#include "stddef.h"

// ---------------------------------------------------------------------
// I/O Macros
// ---------------------------------------------------------------------

static inline void IoWrite8(uint16_t port, uint8_t data) {
    asm volatile("outb %0, %1" :: "a"(data), "Nd"(port));
}

static inline void IoWrite16(uint16_t port, uint16_t data) {
    asm volatile("outw %0, %1" :: "a"(data), "Nd"(port));
}

static inline void IoWrite32(uint16_t port, uint32_t data) {
    asm volatile("outl %0, %1" :: "a"(data), "Nd"(port));
}

static inline uint8_t IoRead8(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a"(data) : "Nd" (port));
    return data;
}

static inline uint16_t IoRead16(uint16_t port) {
    uint16_t data;
    asm volatile ("inw %1, %0" : "=a"(data) : "Nd" (port));
    return data;
}

static inline uint32_t IoRead32(uint16_t port) {
    uint32_t data;
    asm volatile ("inl %1, %0" : "=a"(data) : "Nd" (port));
    return data;
}

static inline uint8_t read(uint32_t addr) {

    volatile uint8_t* vm = (uint8_t*)1;
    return  vm[addr-1];
}


