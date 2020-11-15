; TODO

; 1 Вычисление параметров для рисования текстуры на FPU
; 2 Кусочно-перспективный рендеринг треугольника
; 3 Запись в Z-буфер и другие буферы

; ES:ESI - Треугольник для рисования на экране. Треугольник должен быть уже
; подготовленным. Должны быть вычислены проекции, Z и заданы текстуры, точки
; -----------------------------------------------------------------------------
triout:

    create_frame 32 ; 32 x 4(dword) 

    ; esi - указатель на данные о рисуемом треугольнике
    gl_subpt loc1, 1, ref_vx, 0, ref_vx ; loc1 [ABx] = Apoint[1].x - Apoint[0].x    
    gl_subpt loc2, 2, ref_vx, 0, ref_vx ; loc2 [ACx] = Apoint[2].x - Apoint[0].x   
    gl_subpt loc3, 1, ref_vy, 0, ref_vy ; loc3 [ABy] = Apoint[1].y - Apoint[0].y    
    gl_subpt loc4, 2, ref_vy, 0, ref_vy ; loc4 [ACy] = Apoint[2].y - Apoint[0].y

    ; if (ACx*ABy - ABx*ACy >= 0) return;
    gl_sqmatrix loc2,loc3, loc1,loc4 ; [fmacros.asm]

    ; В случае, если получилось ПОЛОЖИТЕЛЬНОЕ число, то не рисовать треугольник
    ; Поскольку порядок вершин должен обходиться >> по часовой стрелке <<
    jns .finish 

    ; loc1 - xrs
    ; loc2 - xr
    ; loc3 - k = 0..1
    ; loc4 - xl
    ; loc5 - xs / смещение
    ; loc6 - Apoint[k].y    | Верхняя граница растеризации
    ; loc7 - Apoint[k+1].y  | Нижняя граница
    ; loc8 - XL | Левая граница при растеризации
    ; loc9 - XR | Правая граница 


    ; Сортировка точек по Y
    ; ---------------------------------------------------
    stage3d_sorting PTMP  ; [fmacros.asm]

    ; Если рисуемый общий треугольник не линия (и не за верхней и нижней границами)
    ; ---------------------------------------------------

    ; Расчет величины шага для отрезка AC на каждый Y
    gl_subtr eax, PTMP, 2, 0, ref_vx ; ACx<eax> = Apoint[2].x - Apoint[0].x -- может быть отрицательным
    gl_subtr ebx, PTMP, 2, 0, ref_vy ; ACy<ebx> = Apoint[2].y - Apoint[0].y -- всегда больше 0

    ; xrs<loc1> = (Apoint[2].x - Apoint[0].x) / (Apoint[2].y - Apoint[0].y)
    ; call Engine3D.get_xrs

    shl eax, 0x10
    cdq
    idiv ebx 
    mov [loc1], eax 

    ; xr<loc2> = Apoint[0].x
    ; call Engine3D.get_xr

    mov eax, 0
    gl_pointr eax, PTMP, ref_vx ; eax = Apoint[0].x
    shl eax, 0x10
    mov [loc2], eax

    ; Рисуем 2 части треугольника - слева и справа к 3-й стороне
    ; for (k = 0; k < 2; k++)
    ; -----------------------
    mov [loc3], dword 0 ; k<loc3> = [0..1]

    ; Рисуется полутреугольник
    ; ---------------------------------------------------

.half_triangle:

    ; Если Apoint[k + 1].y < 0, значит, что левую границу треугольника необходимо прирастить
    ; При этом сам полутреугольник не рисовать совсем
    ; Проверим на то, выходит ли за границу конец правого отрезка 

    mov eax, [loc3]
    inc eax
    gl_pointr eax, PTMP, ref_vy  ; eax = Apoint[k + 1].y

    ; Apoint[k + 1].y >= 0?
    ; Если конец линии полутреугольника находится в видимом экране, то начать рисовать
    test eax, 0x80000000
    je .has_draw 

    ; Если конец правостороннего отрезка за верхней границей, то
    ; сам отрезок не рисовать, но прирастить левую границу на
    ; количество горизонтальных линии этой границы
    ; 
    ; xr += xrs * (Apoint[k + 1].y - Apoint[k].y)    
    ; 
    stage3d_triangle_skip 
    jmp .next_k

.has_draw:

    mov eax, [loc3]
    mov ebx, eax
    inc ebx
    gl_pointr eax, PTMP, ref_vy ; eax = Apoint[k].y
    gl_pointr ebx, PTMP, ref_vy ; ebx = Apoint[k+1].y

    ; Apoint[k + 1].y > Apoint[k].y ? Нет - пропуск
    ; ---
    cmp ebx, eax
    jle .next_k

    ; Расчет параметров смещения
    ; xl<loc4> = Apoint[k].x
    ; xs<loc5> = (Apoint[k + 1].x - Apoint[k].x) / (Apoint[k + 1].y - Apoint[k].y);
    stage3d_calculate_right

    ; Проверка на превышение верхней границы по Y
    mov eax, [loc3]
    gl_pointr eax, PTMP, ref_vy  ; EAX = Apoint[k].y

    ; Принудительное окончание рисования, если мы только начинаем рисовать, 
    ; и уже за нижней границей экрана
    cmp eax, 200
    jge .next_k

    ; Если, Apoint[k].y < 0, скорректировать
    test eax, 0x80000000
    je .ok_draw

    ; На вход Apoint[k].y (eax)
    ; Выполнение следующих арифметических действий
    ; ----
    ; xl<loc4>  = Apoint[k].x - xs * Apoint[k].y;
    ; xr<loc2> -= xrs * Apoint[k].y;
    ; Apoint[k].y = 0;
    ; ----

    stage3d_adjust_lr    

.ok_draw:

    ; if (Apoint[k + 1].y >= 200) Apoint[k + 1].y = 199;
    stage3d_adjust_down

    ; Простановка границ Y = 0..319
    ; --------------------------------
    mov eax, [loc3]
    mov ebx, eax
    inc ebx
    gl_pointr eax, PTMP, ref_vy  
    gl_pointr ebx, PTMP, ref_vy  
    mov [loc6], eax ; Нижняя
    mov [loc7], ebx ; Верхняя

.rep_scanline:

    ; XL<eax> = (int)xr, XR<ebx> = (int)xl
    ; if (XL > XR) swap(XL, XR)
    ; if (XL < 0) XL = 0;
    ; if (XR > 319) XR = 319;    
    ; ----
    ; На выходе: XL<loc8>, XR<loc9>    
    stage3d_bound_adjusts

    ; XR < 0? Пропускаем такую линию
    test [loc9], word 0x8000
    jne .row_next

    ; XL > 319? Пропускаем
    cmp [loc8], word 319
    jnb .row_next

    ; Вычисление позиции
    mov edx, 320
    mov eax, [loc6] ; y = Apoint[k].y
    mul edx
    add eax, [loc8]
    mov edi, eax
    add edi, FRAME_BUFFER

    ; Основной цикл
    ; ----------------------------------------------------
.repeat:

    mov al, 0x02 ; тестовый цвет (зеленый)
    stosb 

    inc dword [loc8] ; x++
    mov eax, [loc8]
    cmp eax, [loc9]
    jle .repeat
    ; ----------------------------------------------------

.row_next:

    ; xr<loc2> += xrs<loc1>
    mov eax, [loc2]
    add eax, [loc1]
    mov [loc2], eax

    ; xl<loc4> += xs<loc5>
    mov eax, [loc4]
    add eax, [loc5]
    mov [loc4], eax

    inc dword [loc6] ; Apoint[k].y++
    mov eax, [loc6]
    cmp eax, [loc7]
    jle .rep_scanline

.next_k:

    ; k++
    inc dword [loc3]
    cmp [loc3], dword 2
    jne .half_triangle

.finish: 
        
    leave
    ret 


; --------------------------
; Копирование буфера из памяти

copy_buffers:

    push ds
    push es
    pop ds
    mov esi, FRAME_BUFFER
    mov edi, 0xA0000
    mov ecx, 320*200/4
    rep movsd
    pop ds

    ret    

; Очистка памяти
; --------------------------
clear_buffer:

    mov edi, FRAME_BUFFER
    mov al, 0x00
    mov ecx, 320*200
    rep stosb

    ret