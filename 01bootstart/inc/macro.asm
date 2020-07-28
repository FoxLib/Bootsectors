macro   brk { xchg bx, bx }

arg0    equ word [bp + 4]
arg1    equ word [bp + 6]
arg2    equ word [bp + 8]

macro invoke proc {
    call proc
}

macro invoke proc, [arg] {

    reverse
        push arg
    common
        call proc
}

