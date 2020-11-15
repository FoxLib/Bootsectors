// Читать BYTE из памяти
uint8_t mm_readb(uint32_t addr) {    
    return *((uint8_t*)(addr));
}

// Читать WORD из памяти
uint16_t mm_readw(uint32_t addr) {    
    return *((uint16_t*)(addr));
}

// Читать DWORD из памяти
uint32_t mm_readd(uint32_t addr) {
    return *((uint32_t*)(addr));
}

// Писать BYTE в память
void mm_writeb(uint32_t addr, uint8_t data) {
    *((uint8_t*)(addr)) = data;
}

// Писать WORD в память
void mm_writew(uint32_t addr, uint16_t data) {
    *((uint16_t*)(addr)) = data;
}

// Писать DWORD в память
void mm_writed(uint32_t addr, uint32_t data) {
    *((uint32_t*)(addr)) = data;
}
