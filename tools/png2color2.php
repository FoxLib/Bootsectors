<?php

include 'dither.class.php';

$dt = new Dithering();
$dt->set2colors();

$im = imagecreatefrompng($argv[1]);
$image = $dt->create($im);

imagepng($image, "result2.png");
