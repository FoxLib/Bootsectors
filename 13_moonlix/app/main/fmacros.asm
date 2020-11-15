ref_x  EQU 0x00
ref_y  EQU 0x04
ref_z  EQU 0x08
ref_u  EQU 0x10
ref_v  EQU 0x12
ref_s  EQU 0x14
ref_t  EQU 0x16
ref_vx EQU 0x18
ref_vy EQU 0x1C

G3D_TSIZE EQU 0x60                ; Размер структуры (треугольника)

FRAME_BUFFER   EQU  0x00180000    ; frame-buffer

; ------------------------------------------------------------------------------------------------------

; c - цвет
macro Point3D x,y,z,c, t,u,v,s
{
    dd x, y, z, c ; данные по координатам 
    dw u, v, s, t ; параметры текстуры
    dd 0, 0       ; проекции точек [рассчитываются]
}

; Вычисление "input" = Apoint[<point1>].<ref1> - Apoint[<point2>].<ref1>
macro gl_subpt rcb, p1, ref1, p2, ref2 {

    mov eax,  [es:edi + p1 * 0x20 + ref1]
    sub eax, dword [es:edi + p2 * 0x20 + ref2]
    mov [rcb], eax
}

; <dest> = <src>[P1].ref - <src>[P0].ref
macro gl_subtr dest, src, P1, P0, ref {

    mov dest, [es:src + 0x20*P1 + ref]
    sub dest, [es:src + 0x20*P0 + ref] 
}

; <dest> = <ptrp>[P].ref
macro gl_pointr dest, ptrp, ref {

    shl dest, 5    
    mov dest, [es:ptrp + dest + ref] 
}

; eax = A*B - C*D
; ------------------------------------------------------------------------------------------------------
macro gl_sqmatrix A,B,C,D {

    mov  eax, [C]
    imul dword [D]
    mov  ebx, eax
    mov  eax, [A] 
    imul dword [B]
    sub  eax, ebx
}

; Обмен 32-х байтного значения по указателям [A + B] и [A + C]
; т.е. по сути это SWAP-32
macro gl_pswap A,B,C {

    push eax ebx ecx edx
    mov  ecx, 8
@@: mov  eax, [es:A + B]    
    xchg eax, [es:A + C]
    mov  [es:A + B], eax
    add B, 4 
    add C, 4
    loop @b
    pop edx ecx ebx eax
}

; ---------------------------------------------------- СТАДИИ -----------------------------------

; СТАДИЯ 1. Сортировка точек по Y
; ---------
macro stage3d_sorting X {

    mov edi, X ; Указатель на временный регион для рисования треугольника
    mov ebx, 0 ; i=0

.swap_i:

    mov edx, ebx  

.swap_j:    

    add edx, 0x20 ; j=i+1  
    cmp edx, 0x60 ; j >= 3? 
    je .swap_inc

    mov eax, [es:edi + ebx + ref_vy]
    cmp eax, [es:edi + edx + ref_vy] ; P[j].y > P[i].y
    jle .swap_j

    ; Обмен точек в указателях EBX, EDX     
    gl_pswap edi, ebx, edx 
    jmp .swap_j

.swap_inc:

    add ebx, 0x20
    cmp ebx, 0x40 ; i=2, выход
    jne .swap_i
}


; СТАДИЯ 2. Приращение при отсутствующем полутреугольнике
; ---------
macro stage3d_triangle_skip {

    ; ebx = k
    mov ebx, [loc3]

    ; ebx = Apoint[k].y       
    gl_pointr ebx, PTMP, ref_vy 

    ; eax = Apoint[k + 1].y - Apoint[k].y
    sub eax, ebx              

    ; xr<loc2> += xrs<loc1> * (Apoint[k + 1].y - Apoint[k].y)
    mov ebx, [loc1] ; <xrs>
    cdq
    imul ebx 
    add [loc2], eax
}


; СТАДИЯ 3. Расчет точки приращения и самого приращения
; ---------
macro stage3d_calculate_right {

    ; xl<loc4> = Apoint[k].x
    mov eax, [loc3]
    gl_pointr eax, PTMP, ref_vx ; eax = Apoint[k].x
    shl eax, 0x10
    mov [loc4], eax

    ; edx = Apoint[k+1].x - Apoint[k].x
    mov eax, [loc3]
    mov edx, eax
    inc edx

    gl_pointr eax, PTMP, ref_vx ; eax = Apoint[k].x
    gl_pointr edx, PTMP, ref_vx ; edx = Apoint[k+1].x

    sub edx, eax
    shl edx, 0x10

    ; ebx = Apoint[k+1].y - Apoint[k].y
    mov eax, [loc3]
    mov ebx, eax
    inc ebx
    gl_pointr eax, PTMP, ref_vy ; eax = Apoint[k].y
    gl_pointr ebx, PTMP, ref_vy ; ebx = Apoint[k+1].y
    sub ebx, eax

    ; xs<loc5> = (Apoint[k + 1].x - Apoint[k].x) / (Apoint[k + 1].y - Apoint[k].y);
    xchg eax, edx
    cdq
    idiv ebx
    mov [loc5], eax
}

; СТАДИЯ 4. Приращение к левому и правому краю в случае, когда верх отрезка находится < 0, а низ > 0
; ВХОД: eax = Apoint[k].y
; ---------

macro stage3d_adjust_lr {

    ; eax = -Apoint[k].y
    neg  eax 
    push eax 

    ; -xs*Apoint[k].y
    cdq
    imul dword [loc5] 
    xchg eax, ebx

    ; xl<loc4> = Apoint[k].x - xs*Apoint[k].y 
    mov eax, [loc3]
    gl_pointr eax, PTMP, ref_vx 
    shl eax, 0x10
    add eax, ebx 
    mov [loc4], eax 

    ; xr<loc2> -= xrs<loc1>*Apoint[k].y
    pop eax
    cdq
    imul dword [loc1] 
    add [loc2], eax 
   
    ; Установить Apoint[k].y = 0
    mov eax, [loc3]
    shl eax, 5    
    mov [es:PTMP + eax + ref_vy], dword 0
}

; СТАДИЯ 5. f (Apoint[k + 1].y >= 200) Apoint[k + 1].y = 199;
; ---------

macro stage3d_adjust_down {

    ; Apoint[k+1].y > 200 ? 
    mov eax, [loc3]
    inc eax
    gl_pointr eax, PTMP, ref_vy  
    cmp eax, 200
    jl .lcurrent

    ; Apoint[k+1].y = 199
    mov eax, [loc3]
    inc eax
    shl eax, 5    
    mov [es:PTMP + eax + ref_vy], dword 199

.lcurrent:

}

; ---------------------------------------------------------------

; РАСЧЕТ ГРАНИЦ ТРЕУГОЛЬНИКА ПЕРЕД ЕГО РАСТЕРИЗАЦИЕЙ
; ----
; XL = xl, XR = xr;
; if (XL > XR) swap(XL, XR);
; XL = (int)XL, XR = (int)XR;
;
; if (XL < 0) XL = 0;
; if (XR > 319) XR = 319;

macro stage3d_bound_adjusts {

    ; Вычисление границ X
    mov ebx, [loc2] ; xr
    mov ecx, [loc4] ; xl

    cmp ebx, ecx
    jle .swap_no

    xchg ebx, ecx

.swap_no:    

    sar ebx, 0x10 ; XL<eax> = (int)xr
    sar ecx, 0x10 ; XR<ebx> = (int)xl

    ; if (XL < 0) XL = 0;
    test bx, 0x8000
    je .overflow_xlow
    xor ebx, ebx 

.overflow_xlow:

    ; if (XR >= 320) XR = 319;
    cmp ecx, 320
    jl .overflow_xhigh
    mov ecx, 319

.overflow_xhigh:

    mov [loc8], ebx ; XL<loc8>
    mov [loc9], ecx ; XR<loc9>
}