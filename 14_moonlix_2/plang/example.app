# Все переменные являются 8-байтными значениями, либо указателями на объекты
# Все должно разделяться пробелами

include console strings files 
namespace prog # Теперь обращения prog:main
def main argc argv
    
    # var поддерживаются только фиксированного размера
    # для каждой функции свой стек
    # а для динамической памяти нужен malloc

    var byte s[1024]
    var f i

    if argc == 1

        i = 0
        s = concat "Параметры # " argv[i]
        printf s
        printf "String testing"

        f = open argv[0] # Открыть файл
        while eof f == 0
        
            s = fgets f            
            console:write s

        close f # Закрыть

    if argc == 0
        console:write "Ничего нет"
