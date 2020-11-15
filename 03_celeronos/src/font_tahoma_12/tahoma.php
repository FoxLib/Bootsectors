<?php

$t = imagecreatefrompng("tahoma.png");

// 15 x 72
echo 'u8 tahoma[1080] = {' . "\n";
for ($i = 0; $i < 72; $i++) {

    echo "   ";
    for ($j = 0; $j < 120; $j += 8) {

        $b = 0;
        for ($k = 0; $k < 8; $k++) {

            $m = (imagecolorat($t, $j + $k, $i) & 255) > 128 ? 1 : 0;
            $b |= (pow(2, 7 - $k) * $m);
        }

        echo '0x' . str_pad(dechex($b), 2, '0', STR_PAD_LEFT) . ', ';
    }

    echo "\n";
}
echo "};\n";