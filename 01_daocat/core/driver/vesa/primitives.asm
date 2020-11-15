; ---------------------------------------------
; Нарисовать прямоугольник, закрашенный цветом
; VESA_rectangle(dword X1, Y1, X2, Y2, color)
; ds: SEGMENT_CORE_DATA, es: SEGMENT_LFB
; ---------------------------------------------

VESA_rectangle:

    push ebp
    mov ebp, esp

    mov eax, [ebp + BP_ARG_3]
    mov ebx, dword [SCREEN_WIDTH]
    mul ebx
    add eax, [ebp + BP_ARG_4] ; eax = y1 * vga_width + x1

    lea edi, [4*eax] ; eax = 4*(y1 * vga_width + x1)
    lea ebx, [4*ebx] ; ebx = 4*vga_width

    mov esi, [ebp + BP_ARG_1]
    sub esi, [ebp + BP_ARG_3] ; dY = y2 - y1
    inc esi

    ; Итерации на рисование вертикальных линии
@vsr_yloop:

    mov ecx, [ebp + BP_ARG_2]
    sub ecx, [ebp + BP_ARG_4] ; dX = x2 - x1
    mov eax, [ebp + BP_ARG_0] ; eax = color
    inc ecx

    push edi
    rep stosd
    pop edi
    add edi, ebx
    dec esi   
    jne @vsr_yloop

@vsr_yloop_end:

    pop ebp
    ret

; ---------------------------------
; Начертить строку
; (x-3, y-2, color-1, char* text-0)
; ---------------------------------

VESA_out_text:

    push ebp
    mov  ebp, esp

    mov  eax, [ebp + BP_ARG_2]
    mul  dword [SCREEN_WIDTH]
    add  eax, [ebp + BP_ARG_3]

    lea  edi, [4*eax]    ; edi = 4*(y*width + x)
    mov  esi, [ebp + BP_ARG_0] ; esi = string

@ot_symbol:

    lodsb
    and al, al
    je @ot_stop

    movzx eax, al

    ; Высота шрифта 11
    mov ch, 11
    lea ebx, [eax*8 + eax]
    add ebx, eax
    add ebx, eax ; ebx = 11*eax

    push edi

    ; eax = color
    mov eax, [ebp + BP_ARG_1] 

@ot_loopy:    

    mov  cl, 6 ; Ширина 6
    mov  dl, [font6_11 + ebx]
    push edi

@ot_loopx:    

    test dl, 0x80
    je @ot_next_point

        stosd
        jmp @ot_over_point

@ot_next_point:

    add edi, 4

@ot_over_point:

    shl dl, 1
    dec cl
    jne @ot_loopx

    pop edi

    ; y++
    mov edx, [SCREEN_WIDTH]
    lea edx, [4*edx]
    add edi, edx

    inc ebx
    dec ch
    jne @ot_loopy

    pop edi

    ; 4 байта x 6 пикселей
    add edi, 4*6

    ; Следующий символ
    jmp @ot_symbol

@ot_stop:

    pop ebp
    ret    
