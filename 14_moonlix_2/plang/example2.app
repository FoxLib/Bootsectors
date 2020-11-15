# Объявление одиночных переменных
var float ppd wh hh

# Определение типа point
type point x y

# Присвоить значения кортежу
ppd wh hh = 200 160 100

def projection x y z

    var float px py # если не задан явно тип, будет int-64
    point prj # Объявление типа prj (point)

    prj.x = x * ppd / z + wh 
    prj.y = y * ppd / z + hh

    return prj

def halftriangle

    var y y1 y2 x1 x2 x3 t
    x1 x2 x3 y1 y2 = 50 25 150 100 200
    
    t  = y2 - y1
    xa = x2 - x1 / t
    xb = x3 - x1 / t
    #xa = + - x2 x1 - y2 y1

    y = y1
    while y < y2

        x1 = x1 + xa
        x2 = x2 + xb
        y = y + 1

        x = x1
        while x < x2

            x = x + 1
            pset x y 255 255 255

def main

    point p
    p = projection 10 50 10