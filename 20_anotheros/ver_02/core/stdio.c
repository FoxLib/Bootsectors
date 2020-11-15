
// Конвертация числа в ASCIIZ
int i2a(int num, char* res) {

    char fm[24];

    int i, j = 0, k = 0, neg = 0, dignum = 0;

    // Пропечатка отрицательного числа
    if (num < 0) {
        num = -num;
        dignum++;
        neg = 1;
    }

    // Ищем данные
    for (i = 0; i < 10; i++) {

        dignum++;
        fm[j++] = ('0' + num % 10);
        num = num / 10;

        if (num == 0)
            break;
    }

    // Отрицательный знак
    if (neg) res[k++] = '-';

    // Переписываем в обратную сторону
    for (j--; j >= 0; j--) res[k++] = fm[j]; res[k] = 0;

    return dignum;
}

// Удаление лишних пробелов из s и запись в dest
void trim(const char* s, char* dest) {

    int i = 0, k = 0, left = 0, right = 0, ln = 0;

    // Рассчитать длину строки
    while (s[i++]) ln++;

    // Найти левую и правую сторону
    for (i = 0; i < ln; i++) if (s[i] > ' ') { left = i; break; }
    for (i = ln - 1; i >= 0; i--) if (s[i] > ' ') { right = i; break; }

    // Скопировать в новую строку
    for (i = left; i <= right; i++) dest[k++] = s[i]; dest[k] = 0;
}

// Реализация функции Си
int strcmp(const char* __s1, const char* __s2) {

    int i = 0;

    while (__s1[i] & __s2[i]) i++;

    // Строки совпали
    if (__s1[i] == 0 && __s2[i] == 0)
        return 0;

    // Первая строка меньше второй
    if (__s1[i] == 0)
        return -1;

    // Вторая строка больше
    return 1;
}

// Перевод строки в верхний регистр
void strtoupper(char* s) {

    int i = 0;

    while (s[i]) {

        if (s[i] >= 'a' && s[i] <= 'z')
            s[i] -= 0x20;

        i++;
    }
}

// Очистить область памяти
void bzero(void* s, int n) {

    int i;
    char* bs = (char*)s;

    for (i = 0; i < n; i++) bs[i] = 0;
}

// Печать в телетайп-режиме
void print(const char* s) {

    byte* so = (byte*)s;

    while (*so) {

        if (*so == 10) { // Перевод строки

            vg.cx = 0;
            vg.cy++;

        } else { // Печать символа

            vg.print(vg.cx, vg.cy, *so, vg.fr, vg.bg);
            vg.cx++;

            // Перенос на следующую
            if (vg.cx == 80) {
                vg.cx = 0;
                vg.cy++;
            }
        }

        // Скроллинг
        if (vg.cy == 25) {
            vg.scroll();
        }

        so++;
    }

    // Новая позиция курсора
    vg.cursor(vg.cx, vg.cy);
}

// Печать целого
void print_int(int num) {

    char buf[15];
    i2a(num, buf);  // Конвертация числа в строку
    print(buf);
}

// Печать num-х битного числа, num=1..32
void print_hex(uint hex, int num) {

    int i, n = 0;
    char buf[16];

    for (i = num - 4; i >= 0; i -= 4) {

        byte D = (hex >> i) & 0xF;
        buf[n++] = (D < 10 ? '0' + D : '7' + D);
    }

    buf[n] = 0; print(buf);
}
