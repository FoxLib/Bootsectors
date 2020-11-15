; Макрос остановки для отладчика
macro brk { xchg bx, bx }

macro saveall { 
    push rax rbx rcx rdx rsi rdi rbp 
    cld
} 

macro loadall { pop  rbp rdi rsi rdx rcx rbx rax } 

; ------------------------------

par1 EQU ebp + 0x10
par2 EQU ebp + 0x18
par3 EQU ebp + 0x20
par4 EQU ebp + 0x28
par5 EQU ebp + 0x30

loc1 EQU ebp - 0x08 ; [ebp] = esp, поэтому локальная паременная начинается с - 0x04
loc2 EQU ebp - 0x10
loc3 EQU ebp - 0x18
loc4 EQU ebp - 0x20
loc5 EQU ebp - 0x28
loc6 EQU ebp - 0x30
loc7 EQU ebp - 0x38
loc8 EQU ebp - 0x40
loc9 EQU ebp - 0x48

; -----------------------------------------------------------------------------------------

macro vc2 F,A,B { ; 2 параметра
    push qword B
    push qword A
    call F
    add  rsp, 0x10
}

macro vc3 F,A,B,C { ; 3 параметра
    push qword C
    push qword B
    push qword A
    call F
    add  rsp, 0x18
}

macro vc4 F,A,B,C,D { ; 4 параметра
    push qword D
    push qword C
    push qword B
    push qword A
    call F
    add  rsp, 0x20
}

macro vc5 F,A,B,C,D,E { ; 5 параметров
    push qword E
    push qword D
    push qword C
    push qword B
    push qword A
    call F
    add  rsp, 0x28
}

macro vc6 F,A,B,C,D,E,Z { ; 6 параметров 
    push qword Z
    push qword E
    push qword D
    push qword C
    push qword B
    push qword A
    call F
    add  rsp, 0x30
}