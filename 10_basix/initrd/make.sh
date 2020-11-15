# @TODO Файлы, которые требуется скопировать .... 
# ----------------------------------------------------------------------

# cp .. disk/

# Компрессия
# ----------------------------------------------------------------------

cp initrd.img temporary.img
compress temporary.img
mv temporary.img.Z ../disk/initrd.img
./cleandisk