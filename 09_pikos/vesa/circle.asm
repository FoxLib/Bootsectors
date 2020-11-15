;
; Рисовать на экране закрашенную окружность
; 
; ecx   Радиус
; esi   X
; edi   Y
;

vesa.Circle:

        xor     ebx, ebx                    ; x = 0
        mov     eax, 3
        imul    edx, ecx, 2                 ; ecx = радиус
        sub     eax, edx                    ; d = 3 - 2*радиус
.while: cmp     ebx, ecx                    ; while (x <= y)
        jg      vesa.Circle.Line.fin
        call    vesa.Circle.FillX           ; line(xc-x,yc-y)-(xc+x,yc-y)
        xchg    ebx, ecx                    ; line(xc-x,yc+y)-(xc+x,yc+y)
        call    vesa.Circle.FillX           ; line(xc-y,yc-x)-(xc+y,yc-x)
        xchg    ebx, ecx                    ; line(xc-y,yc-x)-(xc+y,yc-x)
        imul    eax, ebx, 4
        add     eax, 6
        add     edx, eax                    ; d += 4*x + 6
        and     edx, edx
        js      .next                       ; if d >= 0
        imul    eax, ecx, 4
        add     edx, 4
        sub     edx, eax                    ; d += 4*(1 - y)
        dec     ecx                         ; y--
.next:  inc     ebx                         ; x++
        jmp     .while
        
vesa.Circle.FillX:

        mov     ebp, edi
        sub     ebp, ecx
        call    vesa.Circle.Line
        add     ebp, ecx
        add     ebp, ecx

vesa.Circle.Line:

        pusha
        cmp     ebp, [vesa.height]
        jnb     .skip                   ; (y < 0) or (y > height) - выход
        imul    ecx, ebx, 2             ; cx *= 2
        sub     esi, ebx                ; x = xc - x
        mov     eax, [vesa.width]       ; bx = 2*(width * y)
        imul    eax, ebp
        xchg    eax, ebx
        mov     ax, [vesa.color]
        inc     ecx
        add     ebx, ebx
        add     ebx, [vesa.linear]
.loop:  cmp     esi, [vesa.width] 
        jnl     .skip                   ; si > width?
        jnb     .pix                    ; si < 0?
        mov     [ebx + 2*esi], ax
.pix:   inc     esi
        loop    .loop
.skip:  popa
.fin:   ret
