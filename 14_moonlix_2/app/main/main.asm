include 'loader.asm'

; --------------------------
; Ветвление на реализацию 3D-движка типа "Конструктор" (Minecraft)
; 1 Отдел геометрии (16мб)
;   Геометрия подгружается с диска по мере надобности
;
; 2 Банки текстур (4Мб), 64 текстуры
; 3 Буферы (1мб)
; ---
; 0x00142000 Системные данные
; 0x00400000 Буферы
; 0x00500000 Текстуры
; 0x00900000 Геометрия
; до конца свободной памяти
; --------------------------

Main_Application:

    fninit

    create_frame 32

    ; Установка VGA-видеорежима 640 x 480 x 16 + стандартная палитра
    mov ax, 0x0013
    int 0x30

    ; Включение прерываний
    sti

    ; бесконечный цикл
TC: 
    
    cmp [es:timer_ticks], dword 100
    jb TC

   
    call clear_buffer

    mov esi, current_triangle
    call triangle

    call copy_buffers
    
; brk

    mov [es:timer_ticks], dword 0

    ; 0
    fld dword [current_triangle + ref_z]
    fld [tx]
    faddp st1,st0
    fstp dword [current_triangle + ref_z]

    ; 1
    fld dword [current_triangle + 0x20 + ref_z]
    fld [tx]
    faddp st1,st0
    fstp dword [current_triangle + 0x20 + ref_z]

    ; 2
    fld dword [current_triangle + 0x40 + ref_z]
    fld [tx]
    faddp st1,st0
    fstp dword [current_triangle + 0x40 + ref_z]

    jmp TC

tx  dd -0.01

; ------------
current_triangle:

    Point3D -10.0,  -4.0, 15.0,  0,0,0,0,0
    Point3D  10.0,  -4.0, 15.0,  0,0,0,0,0
    Point3D  10.0,  -4.0, 5.0,   0,0,0,0,0
