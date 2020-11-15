<?php

$f = fopen($argv[1], "r");

while (!feof($f))
{
    // Прочитать новую строку, если она пуста - пропустить
    $row = trim(fgets($f)); if ($row === '') continue;

    echo "$row\n";

}
fclose($f);