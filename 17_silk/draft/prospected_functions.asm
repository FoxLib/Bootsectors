; Выделить память для ядра (ring-0), работает только для RING-0
kmalloc(size_t size)        

; Выделить фрагмент памяти на заданном сегменте
malloc(int segment, size_t size)

; Выделить память и создать новый сегмент в LDT/GDT
smalloc(size_t size)
