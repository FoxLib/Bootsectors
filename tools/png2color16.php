<?php

include 'dither.class.php';

$dt = new Dithering();
// $dt->set4colors();

$im = imagecreatefrompng($argv[1]);
$image = $dt->create($im);

imagepng($image, "result.png");

shell_exec("convert result.png image.bmp");
//unlink('result.png');
