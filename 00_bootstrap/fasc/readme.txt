// Ассемблер, но слегка получше

int print_rectangle(char* a, int b, long m) {

    uint32 p = 0xB8000
    uint16 t, i
    for (i = 0; i < 16; i++) {

        t = i*2
        p[t] = 2*a
        (p + t) = 3*a

    }
}