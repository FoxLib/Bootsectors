// http://wiki.osdev.org/VGA_Hardware

#include "h/vga.h"
#include "h/vgamodes.h"

// Установка видеорежима через запись регистров
void write_regs(unsigned char *regs)
{
    unsigned i;

    /* Записать MISCELLANEOUS регистр. */
    outb(VGA_MISC_WRITE, *regs);
    regs++;

    /* write SEQUENCER regs */
    for(i = 0; i < VGA_NUM_SEQ_REGS; i++)
    {
        outb(VGA_SEQ_INDEX, i);
        outb(VGA_SEQ_DATA, *regs);

        regs++;
    }

    /* Разблокируем CRTC регистры */
    outb(VGA_CRTC_INDEX, 0x03);
    outb(VGA_CRTC_DATA, inb(VGA_CRTC_DATA) | 0x80);

    outb(VGA_CRTC_INDEX, 0x11);
    outb(VGA_CRTC_DATA, inb(VGA_CRTC_DATA) & ~0x80);

    /* Оставим их разблокированными */
    regs[0x03] |= 0x80;
    regs[0x11] &= ~0x80;

    /* write CRTC regs */
    for(i = 0; i < VGA_NUM_CRTC_REGS; i++)
    {
        outb(VGA_CRTC_INDEX, i);
        outb(VGA_CRTC_DATA, *regs);
        regs++;
    } 
 
    /* write GRAPHICS CONTROLLER regs */
    for(i = 0; i < VGA_NUM_GC_REGS; i++)
    {
        outb(VGA_GC_INDEX, i);
        outb(VGA_GC_DATA, *regs);
        regs++;
    }

    /* Записать ATTRIBUTE CONTROLLER регистры */
    for(i = 0; i < VGA_NUM_AC_REGS; i++)
    {
        // Необходимо прочесть, чтобы контроллер знал,
        // что мы сейчас будем писать пару индекс-значение
        (void)inb(VGA_INSTAT_READ); 

        outb(VGA_AC_INDEX, i);
        outb(VGA_AC_WRITE, *regs);

        regs++;
    }

    /* Заблокировать 16-color палитру и разблокировать дисплей */
    (void)inb(VGA_INSTAT_READ);
    outb(VGA_AC_INDEX, 0x20);
}

// Установить указатель на видеопамять
void set_plane(unsigned p)
{
    unsigned char pmask;

    p &= 3;
    pmask = 1 << p;

    /* set read plane */
    outb(VGA_GC_INDEX, 4);
    outb(VGA_GC_DATA,  p);

    /* set write plane */
    outb(VGA_SEQ_INDEX, 2);
    outb(VGA_SEQ_DATA, pmask);
}

/*****************************************************************************
VGA framebuffer is at A000:0000, B000:0000, or B800:0000
depending on bits in GC 6
*****************************************************************************/
unsigned get_fb_seg(void)
{
    unsigned seg;

    outb(VGA_GC_INDEX, 6);
    seg = inb(VGA_GC_DATA);
    seg >>= 2;
    seg &= 3;

    switch(seg)
    {
        case 0: case 1: seg = 0xA000; break;
        case 2: seg = 0xB000; break;
        case 3: seg = 0xB800; break;
    }
    return seg;
}

void vmemwr(unsigned dst_off, unsigned char *src, unsigned count)
{
    unsigned p = 16 * get_fb_seg() + dst_off, i;

    // Записать необходимое количество байт в видеопамять
    for (i = 0; i < count; i++) writeb(p + i, src[i]);    
}

/*****************************************************************************
write font to plane P4 (assuming planes are named P1, P2, P4, P8)
*****************************************************************************/
void write_font(unsigned char *buf, unsigned font_height)
{
    unsigned char seq2, seq4, gc4, gc5, gc6;
    unsigned i;

    /* save registers set_plane() modifies GC 4 and SEQ 2, so save them as well */
    outb(VGA_SEQ_INDEX, 2);
    seq2 = inb(VGA_SEQ_DATA);

    outb(VGA_SEQ_INDEX, 4);
    seq4 = inb(VGA_SEQ_DATA);

    /* turn off even-odd addressing (set flat addressing)
    assume: chain-4 addressing already off */
    outb(VGA_SEQ_DATA, seq4 | 0x04);

    outb(VGA_GC_INDEX, 4);
    gc4 = inb(VGA_GC_DATA);

    outb(VGA_GC_INDEX, 5);
    gc5 = inb(VGA_GC_DATA);

    /* turn off even-odd addressing */
    outb(VGA_GC_DATA, gc5 & ~0x10);

    outb(VGA_GC_INDEX, 6);
    gc6 = inb(VGA_GC_DATA);

    /* turn off even-odd addressing */
    outb(VGA_GC_DATA, gc6 & ~0x02);

    /* write font to plane P4 */
    set_plane(2);

    /* write font 0 */
    for(i = 0; i < 256; i++)
    {
        vmemwr(i * 32, buf, font_height);
        buf += font_height;
    }

    /* restore registers */
    outb(VGA_SEQ_INDEX, 2);
    outb(VGA_SEQ_DATA,  seq2);
    
    outb(VGA_SEQ_INDEX, 4);
    outb(VGA_SEQ_DATA,  seq4);
    
    outb(VGA_GC_INDEX,  4);
    outb(VGA_GC_DATA,   gc4);
    
    outb(VGA_GC_INDEX,  5);
    outb(VGA_GC_DATA,   gc5);

    outb(VGA_GC_INDEX,  6);
    outb(VGA_GC_DATA,   gc6);
}

// mode = 0x04 (80x50) or 0x13 и др.
void set_video_mode(int mode)
{
    switch (mode) 
    {
        case 0x04:    

            write_regs((unsigned char *)&g_80x50_text);
            write_font(g_8x8_font, 8);
            break;

        case 0x13:

            write_regs((unsigned char *)&g_320x200x256);
            break;

        case 0x12:

            write_regs((unsigned char *)&g_640x480x16);
            break;
    }   
}