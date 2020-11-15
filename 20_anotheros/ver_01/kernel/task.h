
// https://wiki.osdev.org/Task_State_Segment
struct __attribute__((__packed__)) TSS_item {

    /* 00 */ uint32_t link;
    /* 04 */ uint32_t esp0;
    /* 08 */ uint32_t ss0;
    /* 0C */ uint32_t esp1;
    /* 10 */ uint32_t ss1;
    /* 14 */ uint32_t esp2;
    /* 18 */ uint32_t ss2;
    /* 1C */ uint32_t cr3;
    /* 20 */ uint32_t eip;
    /* 24 */ uint32_t eflags;

    /* 28 */ uint32_t eax;
    /* 2C */ uint32_t ecx;
    /* 30 */ uint32_t edx;
    /* 34 */ uint32_t ebx;
    /* 38 */ uint32_t esp;
    /* 3C */ uint32_t ebp;
    /* 40 */ uint32_t esi;
    /* 44 */ uint32_t edi;

    /* 48 */ uint32_t es;
    /* 4C */ uint32_t cs;
    /* 50 */ uint32_t ss;
    /* 54 */ uint32_t ds;
    /* 58 */ uint32_t fs;
    /* 5C */ uint32_t gs;
    /* 60 */ uint32_t ldtr;
    /* 64 */ uint32_t iobp;

};

struct TSS_item* TSS_Main;
