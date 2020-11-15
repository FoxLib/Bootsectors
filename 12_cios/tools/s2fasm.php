<?php 

/*
 * Конвертирование .S файлов FASM-формат
 */ 

$f = array_map('rtrim', file($argv[1]));
$o = array();

foreach ($f as $v) {

    
    // Генерация данных
    $v = preg_replace('/^\s+\.string\s(.+)$/', "\tdb \\1, 0", $v);
    $v = preg_replace('/^\s+\.byte/', "\tdb", $v);
    $v = preg_replace('/^\s+\.word/', "\tdw", $v);
    $v = preg_replace('/^\s+\.long/', "\tdd", $v);

    // Пустые (нулевые байты)
    if (preg_match('/^\s+\.zero\s+(\d+)/', $v, $c)) {
        $v = str_replace($c[0], "\tdb " . substr(str_repeat(',0', $c[1]), 1), $v);
    }    

    // Пропуск специальных конструкции
    if (!preg_match('/^(\#|\s+\.)/', $v)) {

        // Замена слов
        $v = preg_replace('/(\w+) ptr/i', '\\1', $v);

        // Преобразовать ds:4096 -> [ds:4096]
        $v = preg_replace('/(es|ds)\:(\d+)/', '[\\1:\\2]', $v);

        // Ссылки на данные
        $v = preg_replace('/OFFSET FLAT:/', '', $v);

        // Замена byte reference
        $v = preg_replace('/(WORD|BYTE|DWORD) (\w+)\[(.+)\]/i', '\\1 [\\2+\\3]', $v);
        $v = preg_replace('/(WORD|BYTE|DWORD) (\w+)$/i', '\\1 [\\2]', $v);
        $v = preg_replace('/(WORD|BYTE|DWORD) (\w+)([^,]+),/i', '\\1 [\\2\\3],', $v);
        $v = preg_replace('/(WORD|BYTE|DWORD) (\w+),/i', '\\1 [\\2],', $v);

        $v = preg_replace('/\.LC/', 'LC', $v);

        $v = preg_replace('/st\(\d\)/', 'st\\1', $v);

        $o[] = $v;
    }

}

file_put_contents($argv[2], join("\n", $o));
