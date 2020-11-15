def func x

    declare a b c
    a b c = 5 10 15

label:

    add a b c
    sub a x b
    alloca d 1024 ; выделить на стеке 1024 байта

    cmp a c
    if < label

    return x