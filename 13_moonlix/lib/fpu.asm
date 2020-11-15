t1  dd 1.0
t2  dd 2.0
t3  dd 0

; Сложение A + B -> eax
; in: A(float), B(float)
; out: eax(float)
; -----------------------------------------------
macro fpu_add A,B,C {

    push dword [A]
    fld  dword [A]
    fld  dword [B]
    fadd st0, st1
    fstp dword [A]
    fstp st0
    mov  C, [A]
    pop  dword [A]    
} 

; Из float в integer
; in: A(float)
; out: eax(int)
; -----------------------------------------------
fpu_toint:

    create_frame 1
    fld dword [par1]
    fistp dword [loc1]
    mov eax, [loc1]
    leave
    ret    

; (int)eax = (float)A
; -----------------------------------------------
fpu_tofloat:

    create_frame 1
    fild dword [par1]
    fstp dword [loc1]
    mov eax, [loc1]
    leave
    ret    

; (float)eax = (float)A - (float)B
; -----------------------------------------------
fpu_sub:

    create_frame 1    
    fld  dword [par2]
    fld  dword [par1]
    fsub st0, st1
    fstp dword [loc1]
    fstp st0
    mov  eax, [loc1]
    leave
    ret    

; (float)eax = (float)A * (float)B
; -----------------------------------------------
fpu_mul:

    create_frame 1
    fld  dword [par2]
    fld  dword [par1]
    fmul st0, st1
    fstp dword [loc1]
    fstp st0
    mov  eax, [loc1]
    leave
    ret    

; (float)eax = (float)A / (float)B
; -----------------------------------------------
fpu_div:

    create_frame 1
    fld  dword [par2]
    fld  dword [par1]
    fdiv st0, st1
    fstp dword [loc1]
    fstp st0
    mov  eax, [loc1]
    leave
    ret    

; -----------------------------------------------
fpu_sqrt:

    create_frame 1
    leave
    ret    

; -----------------------------------------------
fpu_pow:  

    create_frame 1
    leave
    ret    
