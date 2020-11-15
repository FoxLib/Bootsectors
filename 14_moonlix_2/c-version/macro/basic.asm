macro BRK { 
    xchg bx, bx ; Останов Bochs
}

; параметры
par1 EQU 8  ; первый аргумент
par2 EQU 12
par3 EQU 16
par4 EQU 20
par5 EQU 24
par6 EQU 28
par7 EQU 32

; локальные переменные
loc1 EQU -4
loc2 EQU -8
loc3 EQU -12
loc4 EQU -16

