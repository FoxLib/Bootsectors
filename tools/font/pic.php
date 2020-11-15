<?php

$im = imagecreatefrompng("pic/{$argv[1]}.png");
$sx = imagesx($im);
$sy = imagesy($im);

$rows = [];
for ($y = 0; $y < $sy; $y++) {

    $cols = [];
    for ($x = 0; $x < $sx; $x++) {

        $cl = imagecolorat($im, $x, $y);
        $wc = c24to16($cl);

        $cols[] = sprintf("0x%04X", $wc);
    }
    $rows[] = "    " . join(", ", $cols);
}
echo "const static unsigned short image[$y][$x] = {\n".join(",\n", $rows)."\n};\n";

function c24to16($cl) {
    return
        ((($cl & 0xFF0000) >> 19) << 11) |
        ((($cl & 0xFF00) >> 10) << 5) |
        (( $cl & 0xFF) >> 3);
}
