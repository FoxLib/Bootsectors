<?php

$name = $argv[1];
$im = imagecreatefrompng($name.'/font.png');
$sx = imagesx($im);
$sy = imagesy($im);

$dataset = [];
$bytes   = floor($sx / 8) + ($sx % 8 ? 1 : 0);

// Генератор тайловой маски
for ($g = 0; $g < $bytes; $g++) {

    for ($y = 0; $y < $sy; $y++) {

        $mask = 0;
        for ($k = 0; $k < 8; $k++) {

            $x = 8*$g + $k;
            $b = (int) @ imagecolorat($im, $x, $y);
            $mask |= ($b * (1 << $k));
        }
        $dataset[$g][$y] = $mask;
    }
}

// Вывод сгенерированных данных
echo "const static unsigned char font_{$name}[".count($dataset)."][$sy] = {\n";
foreach ($dataset as $rows) {

    echo "    {";
    $list = []; foreach ($rows as $byte) $list[] = sprintf("0x%02X", $byte);
    echo join(", ", $list);
    echo "},\n";
}
echo "};\n";

// Вывод инфы о смещениях
$st = array_map('trim', file("$name/font.txt"));
echo "const static unsigned char map_{$name}[".count($st)."][3] = {\n";
foreach ($st as $id => $row) {

    $sym = mb_substr($row, 0, 1);
    $oth = @ mb_substr($row, 2);
    @ list($x, $n) = explode(" ", $oth);
    $x = (int)$x;
    $n = (int)$n;

    $ch = 32 + $id;
    if ($ch >= 127) $ch = 32;
    if ($ch == 0x5C) $ch = 32;

    echo sprintf("    { 0x%02X, 0x%02X, 0x%02X }, /* %02X %c */\n", $x&255, $x>>8, $n, 32 + $id, $ch);
}
echo "};\n";

