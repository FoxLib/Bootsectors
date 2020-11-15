; ----------- c-call -----
par1 EQU ebp + 0x08
par2 EQU ebp + 0x0C
par3 EQU ebp + 0x10
par4 EQU ebp + 0x14
par5 EQU ebp + 0x18

loc1 EQU ebp - 0x04 ; [ebp] = esp, поэтому локальная паременная начинается с - 0x04
loc2 EQU ebp - 0x08
loc3 EQU ebp - 0x0C
loc4 EQU ebp - 0x10
loc5 EQU ebp - 0x14
loc6 EQU ebp - 0x18
loc7 EQU ebp - 0x1C
loc8 EQU ebp - 0x20
loc9 EQU ebp - 0x24

; МАКРОСЫ
; ------------------------------------------------------------------------------

macro brk { xchg bx, bx }
        
; out(A, B)
macro outb_wait port, d {
    mov al, d
    out port, al
    jcxz $+2
    jcxz $+2
}

macro outb D, A {
    mov dx, D
    mov al, A
    out dx, al
}

macro inb D {
    mov dx, D
    in  al, dx
}

; Маскирование битовой маски
macro IRQ_mask channel, bitmask {
    in  al, channel
    and al, bitmask
    out channel, al
}

; "Прыжок в 8-селектор"
macro pm_jump {
    mov eax, cr0
    or  al,  1    
    mov cr0, eax       
    jmp 0x0008:0x0000  
}

; Инициализация сегментов защищенного режима
macro pm_init 
{
    mov ax, 0x0010
    mov ds, ax
    mov ax, 0x0018
    mov ss, ax
    mov ax, 0x0020
    mov es, ax
    mov esp, 0x3FFFF

    ; Для того, чтобы не сбились дескрипторы при pop fs gs
    ; и не вызвали general exception
    ; т.к. в при запуске fs и gs не являются 0
    mov ax, 0
    mov fs, ax
    mov gs, ax
}

macro load_task TR
{
    mov ax, TR
    ltr ax
}

; Инициализация IRQ (PIC)
macro irq_redirect mask 
{
    mov  bx, mask 
    call IRQ_redirect 
}

; Создание IDT в PM
macro create_idt_descriptor address 
{
    mov  eax, address
    call CREATE_idt_descriptor ; lib/bootstrap.asm
}

; Создание шлюза задачи
macro create_task_gate selector 
{
    mov  bx, selector
    call CREATE_task_gate ; lib/bootstrap.asm
}

; Создать фрейм локальных переменных (dword)
macro create_frame count 
{
    push ebp
    mov  ebp, esp
    sub  esp, count * 4
}

; EOI: master, slave
macro eoi_master 
{
    mov al, 0x20
    out 0x20, al
}

macro eoi_slave 
{
    mov al, 0x20
    out 0xA0, al
    out 0x20, al
}

; Сохранение регистров в стеке для INT
macro save_state 
{
    pusha
    push ds es fs gs
}

; Восстановление состояния
macro load_state 
{
    pop gs fs es ds
    popa
}

; Синоним stosd
macro stosde m {
    mov eax, m
    stosd
}

; Создать задачу ядра уровня 0
macro task_create selector, tss_addr, eip_addr ; [lib/bootstrap.asm]
{ 
    mov  ax,  selector
    mov  ebx, tss_addr
    mov  edx, eip_addr    
    call TASK_create_0
}

; Вызов процедур в C-стиле
; -------------------------
macro invk1 F,A { ; 1 параметр
    push dword A
    call F
    add  esp, 4
}

macro invk2 F,A,B { ; 2 параметра
    push dword B
    push dword A
    call F
    add  esp, 8
}

macro invk3 F,A,B,C { ; 3 параметра
    push dword C
    push dword B
    push dword A
    call F
    add  esp, 0x0C
}

macro invk4 F,A,B,C,D { ; 4 параметра
    push dword D
    push dword C
    push dword B
    push dword A
    call F
    add  esp, 0x10
}

macro invk5 F,A,B,C,D,E { ; 4 параметра
    push dword E
    push dword D
    push dword C
    push dword B
    push dword A
    call F
    add  esp, 0x10
}

; [lib/formatex.asm] ОТЛАДКА
; ------------------------------------------------------------------------------------

macro write_decimal number, dest 
{
    mov edi, dest
    mov eax, number
    call WRITE_decimal
}

; Печать строки в 0x8b000 (src - es:источник, dest - y*80 +x, attr - атрибуты)
macro cprint_str_ex src, dest, attr 
{       
    mov esi, src

    mov edi, dest
    add edi, edi
    add edi, 0xb8000 ; edi = 2*edi + 0xb8000

    mov ah,  attr
    call CPRINT_string
}

; Потоковая запись строки [ds:src] в консоль [es:edi] c attr
macro cprint_str src, attr {

    mov ah, attr
    mov esi, src
    call CPRINT_string
}

; Потоковая печать строки из esi в edi
macro sprintf_str src, attr {

    mov esi, src
    mov ah, attr
    call SPRINTF_string
}

; Печать числа по определенным координатам
macro sprint_decimal number, x, y, attr {

    pusha
    write_decimal number, 0x6800

    mov eax, y
    mov ebx, 80
    mul ebx
    add eax, x

    ; Печать чиcла
    cprint_str_ex 0x6800, eax, attr

    pop  esi
    push edi ; запоминаем EDI
    popa
}
