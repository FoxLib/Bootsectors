<?php

$arg1 = isset($argv[1]) ? $argv[1] : '';

if (preg_match('/Com/', $arg1)) $org = '100h'; else $org = '0';

// ---------------------------

$in = fopen("php://stdin", "r");

// echo "org 0\n"; // binary dao file
echo "ORG $org\n"; // test.com file
echo "use16\n";
echo "        jmp main\n\n";

// stub
// Учесть тупой регистр gs:[20] <--- что с ним делать?
echo "__stack_chk_fail: ret\n";

while (!feof($in))
{
    $line = rtrim(fgets(($in)));

    // Указатели на данные
    $line = preg_replace('/\s(QWORD|WORD|BYTE|DWORD)\s+PTR\s+\.L(.*)/i', ' \\1 [label_L\\2]', $line);
    $line = preg_replace('/\s(QWORD|WORD|BYTE|DWORD)\s+PTR\s+(fs|gs)\:(.*)/i', ' \\1 [\\2:\\3]', $line);

    // Метки
    $line = preg_replace('/^\./i', 'label_', $line);
    $line = preg_replace('/\s\.L/', ' label_L', $line);

    // Замена инструкции LEAVE на 32-бит
    $line = preg_replace('/(\s)leave/', "\\1mov esp, ebp\n\tpop ebp", $line);
    $line = preg_replace('/(\s)ret/', "\\1db 66h\n\tret", $line);

    // FPU
    $line = preg_replace('/st\((\d+)\)/', "st\\1", $line);

    if (preg_match('/\.string\s+/', $line))
    {
        $line = str_replace('\\r', '", 0x0D, "', $line);
        $line = str_replace('\\n', '", 0x0A, "', $line);
    }

    // Строки (z-terminated)
    $line = preg_replace('/\.string\s+(.*)$/i', 'db \\1, 0', $line);
    $line = preg_replace('/\.long\s+(.*)$/i', 'dd \\1', $line);
    $line = preg_replace('/\.align\s+(.*)$/i', 'align \\1', $line);

    // "Длинный" call
    $line = preg_replace('/(\s)call\s+/i', '\\1call dword ', $line);

    // Указатели на строки
    $line = preg_replace('/OFFSET FLAT:\./i', 'label_', $line);

    // Убрать все управляющие конструкции
    $line = preg_replace('/^\s+\..*$/', '', $line);
    $line = preg_replace('/^#.*$/', '', $line);

    // Указатели
    $line = preg_replace('/(qword|dword|word|byte) ptr/i', '\\1', $line);

    if ($line)
    {
        echo "$line\n";
    }
}