; **********************************************************************
; Важные системные макросы для FASM, чтобы ускорить разработку, сделать
; код более удобочитаемым.
; **********************************************************************

; Макрос отладки
macro brk { 
    xchg bx,bx 
}

; Макрос, который вызывает процедуры и восстанавливает за собой стек
; Работает так:
; 1. Сначала инициализируется переменная-счетчик
; 2. В обратном порядке выдается push <argument>
; 3. Делается call <proc>
; 4. Если аргументы были, то восстаналивает стек через add esp


macro invoke proc {
    call [proc]
}

macro invoke proc,[arg] {

    common

        size@call = 0

    reverse 

        size@call = size@call + 4
        pushd arg

    common 

        call [proc]

        if size@call
        add esp, size@call
        end if
}

; Упрощение создания строки, оканчивающейся на '0'
macro strz str {

    db str, 0

}

; Заголовок для функции Invoke
macro BEGIN stack_frame {

    push    ebp
    mov     ebp, esp

    if frame
    sub     esp, 4 * frame
    end if

}

; Параметры аргументов
; ----------------------------------------------------------------------

arg_1           equ ebp + 8
arg_2           equ ebp + 12
arg_3           equ ebp + 16
arg_4           equ ebp + 20

