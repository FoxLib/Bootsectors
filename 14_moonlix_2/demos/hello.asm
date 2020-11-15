; make:
; ------------------
; fasm hello.asm && cp hello.bin ../demo.bin && ../update ../demo.bin ../flash.img && cp ../demo.bin ../moon.bin && bochs -f boot.bxrc -q
; ----------------------------------------------------------------------------------------

    include 'loader.asm'

    call lib_grayscale_palette

    brk

    ; https://ru.wikipedia.org/wiki/SSE
    ; http://www.club155.ru/x86cmdsimd/CMPPS

    lea esi, [a]
    movups xmm0, [esi]

    lea esi, [b]
    movups xmm1, [esi]
    mulps  xmm0, xmm1 
    movups [esi], xmm0

    cvttss2si eax, [esi]
    cvttss2si eax, [esi + 4]
    
    mov edi, 0xA0000
    mov ecx, 320 * 200

@@:
    stosb
    inc al
    loop @b
    

    jmp $

a   dd 2.0, 2.5, 1.1, 5.2
b   dd 2.0, 2.2, 1.1, 5.2
c   dd 0, 0, 0, 0

    include '../lib/libdemos.asm'