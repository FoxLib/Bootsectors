# -*- encoding: utf-8 -*-
# ----------------------------------------------------------------------
# Определение, где начинается раздел
# Файл setup.py должен запускаться из предыдущей директории
# ----------------------------------------------------------------------

import getpass
from struct import unpack

# Определение первой записи о валидном FAT32 (type=0B)
# ----------------------------------------------------------------------

start = 0

# Справка по файловой системе
# https://www.ibm.com/developerworks/ru/library/l-python_part_8/
# https://docs.python.org/3/library/struct.html

f = open("disk.img", "rb+") 
f.seek(446);

for i in range(0,4):
    
    p = f.read(16)            
    x = unpack("<8c2i", p)      
    
    # Необходимый раздел обнаружен
    if ord(x[4]) == 0x0B:
        start = x[8]
        break

f.close()

# ----------------------------------------------------------------------
# loop   -- блочный LOOP-девайс (понятия не имею, что это)
# rw     -- read/write
# uid    -- пользователь
# sync   -- синхронизировать сразу же при записи
# offset -- где находится fat-раздел
# ----------------------------------------------------------------------

print "Раздел начинается в ["+str(start)+"] секторе"
print "Команда для монтирования:"
print
print "  sudo mount disk.img -t vfat -o loop,rw,uid="+getpass.getuser()+",sync,offset=$["+str(start) +"*512] /mnt/disk";
print
