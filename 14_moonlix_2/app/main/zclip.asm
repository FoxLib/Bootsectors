; 1 Допустимое пространство x,y,z = {-2147483648,2147483647}
; 2 Данные x,y,z преобразуются в FPU-значения и оперируются далее через FPU
; 3 При проекции FPU -> INT

; ----
; Процедура получает оригинальный треугольник из DS:ESI и, в случае,
; если точка или точки выходят за пределы Z < 1, то такой
; треугольник разбивается на 2 части

; Временные буферы с точками
GD3_TRI EQU PTMP                  ; (0x60) временный треугольник для triout 
G3D_SPL EQU GD3_TRI + 0x60*1      ; (0x60 x 2) возможные треугольники
G3D_PT  EQU G3D_SPL + 0x60*2      ; До 4 точек при разделений Z-плоскостью (0x20 x 4 = 0x80)

Z_CLIP   EQU 8.0 ; Параметр z-clip

; Вывод треугольника с учетом вращения по матрице
; -----------------------------------------------------------------------------------------
triangle:

    call zclip
    ret

; -----------------------------------------------------------------------------------------

; loc = 0,1,2 точки из es:esi
macro add_triangle loc {

    push eax ebx edx esi ecx    
    mov ecx, loc
    call .add_triangle_call
    pop ecx esi edx ebx eax
}

; ref - ref_x, ref_y
; input: eax<k>
; output: ebx = verticles[i].<ref> + eax<k> * (Next.<ref> - verticles[i].<ref>)

macro get_ref ref, dest {

    ; ---
    mov ebx, [loc1]
    inc ebx
    cmp bl, 3
    jne @f
    mov bl, 0
@@: gl_pointr ebx, esi, ref ; st2 = Next.<ref>
    mov [tmp_f], ebx
    fld [tmp_f]

    ; ---
    mov ebx, [loc1]
    gl_pointr ebx, esi, ref ; st0 = verticles[i].<ref>
    mov [tmp_f], ebx
    fld [tmp_f]
    fld [tmp_f]

    fsubp st2, st0 ; st2 = Next.<ref> - verticles[i].<ref>
    fld dword [loc5]
    fmulp st2, st0 ; st1 = k * st2
    faddp st1, st0 ; st0 = verticles[i].<ref> + k*..

    ; записать результат
    fstp dword dest
}

; -----------------------------------------------------------------------------------------
; ds:esi -- входящий треугольник

zclip:

    ; деление сначала по z-части
    ; потом отрезаем по x,y-границам экрана
    ; полученные треугольники растеризуем

    create_frame 8

    push esi

    ; -----
    ; Копирование 3 точек треугольника во временную область
    ; -----
    
    mov edi, PTMP
    mov ecx, 3 * 0x20 / 4 ; 0x20 = sizeof(Point3D), 3 - точки, 4 dword
    rep movsd

    mov esi, PTMP
    mov edi, G3D_PT
   
    ; ----------

    ; <loc1> -- i
    ; <loc2> -- Next.z = verticles[(i+1)%3].z
    ; <loc3> -- verticles[i].z
    ; <loc4> -- count
    ; <loc5> -- kdiv

    ; i<loc1> = 0
    mov [loc1], dword 0
    mov [loc4], dword 0

.cycle:

    ; edx<loc3> = verticles[i].z
    mov edx, [loc1]
    gl_pointr edx, esi, ref_z
    mov [loc3], edx

    ; Next.z<loc2> = verticles[(i+1)%3].z
    mov eax, [loc1]
    inc eax
    cmp al, 3
    jne @f
    mov al, 0
@@: gl_pointr eax, esi, ref_z
    mov [loc2], eax

    ; if (verticles[i].z < gl_z_near) --> переход к .vif1
    ; ---
    fld   [Z_CLIP_f] ;st1
    fld   dword [loc3] ;st0
    fsub  st0,st1
    fistp [tmp_f]
    fstp  st0
    mov   eax, [tmp_f]

    ; verticles[i].z < gl_z_near? (получилось отрицательное verticles[i].z < gl_z_near)
    test eax, 0x80000000
    jne .vif1    

    ; Verticles.push( verticles[i] );
    add_triangle [loc1]
    inc dword [loc4] ; count++

    ; Точка явно не может быть пересечена из - в +
    jmp .vif2

.vif1:

    ; Разделение линии треугольника
    ; if (verticles[i].z < gl_z_near) && (Next.z > gl_z_near) --> .div

    fld   [Z_CLIP_f] ;st1
    fld   dword [loc2] ;st0
    fsub  st0,st1
    fistp [tmp_f]
    fstp  st0
    mov   eax, [tmp_f]

    ; Next.z > gl_z_near? (получилось положительное Next.z - gl_z_near)
    test eax, 0x80000000 
    je .div  
    jmp .nextptr

.vif2:

    ; if (verticles[i].z >= gl_z_near) && (Next.z < gl_z_near) --> .div
    fld   [Z_CLIP_f] ;st1
    fld   dword [loc2] ;st0
    fsub  st0,st1
    fistp [tmp_f]
    fstp  st0
    mov   eax, [tmp_f]

    ; Next.z < gl_z_near? Тогда деление отрезка
    test eax, 0x80000000 
    jne .div 
    jmp .nextptr

; --------------------------------------------------------------------------------------------------------------
; Суб-процедура деления треугольника на 2 части - то есть, рисование точки на z-пересечении
.div:

    ; k = (gl_z_near - verticles[i].z) / (Next.z - verticles[i].z);    
    fld [Z_CLIP_f]   ; st1 = gl_z_near
    fld dword [loc3] ; st0 = verticles[i].z
    fsubp st1,st0    ; st0 = gl_z_near - verticles[i].z

    fld dword [loc2]  ; st1 = Next.z, st2 = ..
    fld dword [loc3]  ; st0 = verticles[i].z
    fsubp st1, st0    ; st0 = Next.z - verticles[i].z, st1 = gl_z_near - verticles[i].z
    fdivp st1, st0    ; st0 = (gl_z_near - verticles[i].z) / (Next.z - verticles[i].z)

    fstp dword [loc5] ; k<loc5>

    ; Добавление новой точки, но с коррекцией позже
    ; ----------------------
    ; Разделение линии на точке пересечения

    add_triangle [loc1]   
    inc dword [loc4] ; count++

    get_ref ref_x, [es:edi - 0x20 + ref_x]    ; x = verticles[i].x + k*(Next.x - verticles[i].x); 
    get_ref ref_y, [es:edi - 0x20 + ref_y]    ; y = verticles[i].y + k*(Next.y - verticles[i].y);        
    mov [es:edi - 0x20 + ref_z], dword Z_CLIP ; z = Z_CLIP    
    get_ref ref_u, [es:edi - 0x20 + ref_u]    ; u = verticles[i].u + k*(Next.u - verticles[i].u);        
    get_ref ref_v, [es:edi - 0x20 + ref_v]    ; v = verticles[i].v + k*(Next.v - verticles[i].v);    
    ; ----------------------

.nextptr:

    inc dword [loc1]
    cmp [loc1], dword 3
    jne .cycle

    ; Вообще не рисовать треугольник, если его нет
    cmp [loc4], dword 3
    jc .fin

    ; Теперь, в зависимости от количества точек, простраиваем треугольник [DS:ESI]
    ; В том числе вычисляя координаты проекции
    ; ------------------------------------------------------------------------------------------------------

    mov esi, G3D_PT
    mov edi, GD3_TRI

    ; Вывод во временный буфер и расчет параметров треугольника
    ; -------------------
    add_triangle 0
    call .prj_triangle

    add_triangle 1
    call .prj_triangle

    add_triangle 2
    call .prj_triangle

    ; Вывод 1 треугольника
    mov  edi, GD3_TRI
    call triout    

    ; Если есть второй треугольник, то выводим его
    ; -----------------------------------------------------------------------------------
    cmp [loc4], dword 4
    jne .fin

    mov edi, GD3_TRI
    add_triangle 0
    call .prj_triangle

    add_triangle 2
    call .prj_triangle

    add_triangle 3
    call .prj_triangle

    ; Вывод 2 треугольника
    mov  edi, GD3_TRI
    call triout   

.fin:

    pop esi
    leave
    ret    

; Расчет проекции x', y'
; ------------------------------------------------------------------------
.prj_triangle:

    push eax ebx edx

    ; x' = 160 + x*200/z
    fld dword [es:edi - 0x20 + ref_x] ; st0=x
    fld dword [PX_DIST] ; st0=200,st1=x
    fmulp st1,st0 ; st0=200*x,st1=z
    fld dword [es:edi - 0x20 + ref_z] ; st0=z
    fdivp st1,st0 ; st0=200*x/z
    fld dword [PX_160]
    faddp st1,st0 ; st=160 + 200*x/z0
    fistp dword [es:edi - 0x20 + ref_vx]

    ; y' = 100 - y*200/z
    fld dword [PX_100] 
    fld dword [es:edi - 0x20 + ref_y] ; st0=x
    fld dword [PX_DIST] ; st0=200,st1=x
    fmulp st1,st0        ; st0=200*y,st1=z
    fld dword [es:edi - 0x20 + ref_z] ; st0=z
    fdivp st1,st0 ; st0=200*y/z
    fsubp st1,st0 ; st0=100 - 200*x/z0
    fistp dword [es:edi - 0x20 + ref_vy]

    pop edx ebx eax
    ret

; loc = 0,1,2 точки из es:esi копируются в es:edi
; ------------------------------------------------------------------------
.add_triangle_call:

    shl ecx, 5
    add esi, ecx

    mov ecx, 0x20 / 4
@@: mov eax, [es:esi]
    stosd
    add esi, 4
    loop @b

    ret

; ------------------------------------------------------------------------

Z_CLIP_f dd Z_CLIP
PX_DIST  dd 200.0 ; dist=200
PX_160   dd 160.0 ; x = width / 2
PX_100   dd 100.0 ; y = height / 2
tmp_f    dd 0
