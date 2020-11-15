<?php

// Виртуальная эмуляция FAT12/FAT16/ext4

// php fat32.php <diskimage>
//
// * format <1/...> mb
// * write <file> <source|stdin>
// * read <file> <source|stdout>

class FATx
{
    public $disk_handler;

    // BIOS Parameter Block
    public $BPB = array();

    // Это NTFS?
    public $is_NTFS = 0;

    // Тип FAT
    public $FATVersion = 0;

    // Начальный сектор данных
    public $data_first_sector;

    // Сектора начала 2-х таблиц
    public $data_fat1_table;
    public $data_fat2_table;

    // Конечная точка
    /*

    Индексный указатель, соответствующий нулевому кластеру (самый первый указатель таблицы FAT),
    содержит значение BPB_Media в нижних 8 битах; остальные биты устанавливаются в 1. Например,
    если BPB_Media = 0xF8 (жесткий диск), FAT[0] = 0x0FFFFFF8 для FAT32. Таким образом, формально FAT[0] = EOC,
    что используется при обработке файлов нулевого размера */

    public $EOC; // Кластер 0
    public $EOF; // Кластер 1

    // --------------

    public function read_byte($seek)
    {
        fseek($this->disk_handler, $seek, SEEK_SET);
        $chr = fread($this->disk_handler, 1);

        return ord($chr);
    }

    public function read_word($seek)
    {
        return $this->read_byte($seek) + 256 * $this->read_byte($seek + 1);
    }

    public function read_dword($seek)
    {
        return $this->read_word($seek) + 65536 * $this->read_byte($seek + 2);
    }

    public function read_string($seek, $count_bytes)
    {
        fseek($this->disk_handler, $seek, SEEK_SET);
        return fread($this->disk_handler, $count_bytes);
    }

    public function write_byte($seek, $byte)
    {
        if ($byte > 255) die("ошибка: $byte > 255");

        fseek($this->disk_handler, $seek, SEEK_SET);
        fwrite($this->disk_handler, chr($byte));
    }

    // little endian
    public function write_word($seek, $word)
    {
        if ($word > 65535) die("ошибка: $word > 65535");

        $this->write_byte($seek,      $word & 255);
        $this->write_byte($seek + 1, ($word >> 8) & 255);
    }

    public function write_dword($seek, $dword)
    {
        if ($dword > 4294967295) die("ошибка: $dword > 4294967295");

        $this->write_byte($seek,     $dword & 255);
        $this->write_byte($seek + 1, ($dword >> 8) & 255);
        $this->write_byte($seek + 2, ($dword >> 16) & 255);
        $this->write_byte($seek + 3, ($dword >> 24) & 255);
    }

    public function write_string($seek, $string)
    {
        for ($i = 0; $i < strlen($string); $i++)
            $this->write_byte($seek + $i, ord($string[$i]));
    }

    // Запись основного блока BPB
    public function write_bpb()
    {
        // Запись BPB в Boot Sector
        $this->write_string(0x03,   'DAOS+OEM'); // OEM
        $this->write_word(0x0B,     512);        // BytesPerSector
        $this->write_byte(0x0D,     1);          // SectorsPerCluster
        $this->write_word(0x0E,     1);          // ReservedSectors
        $this->write_byte(0x10,     2);          // NumberOfFATs
        $this->write_word(0x11,     0xE0);       // RootEntries
        $this->write_word(0x13,     2880);       // NumberOfSectors
        $this->write_byte(0x15,     0xF0);       // MediaDescriptor
        $this->write_word(0x16,     9);          // SectorsPerFAT

        $this->write_word(0x18,     18);         // SectorsPerHead
        $this->write_word(0x1A,     2);          // HeadsPerCylinder
        $this->write_dword(0x1C,    0);          // HiddenSectors
        $this->write_dword(0x20,    0);          // TotalLogicalSectors

        $this->write_byte(0x24,     0);          // PhysicalDriveNumber (BIOS INT 0x13)
        $this->write_byte(0x25,     0);          // ReservedDRN
        $this->write_byte(0x26,     0x29);       // ExtendedBootSignature
        $this->write_dword(0x27,    0);          // VolumeIDSerialNumber (timestamp)
        $this->write_string(0x2B,   'DAOS       '); // PartitionVolumeLabel
        $this->write_string(0x36,   'FAT12   ');    // FileSystemType

        // Зарезервировано до 40h байт              
        $this->write_word(0x3E,    0x0000);
    }

    // Чтение возможных таблиц FAT
    public function read_bpb()
    {
        if ($this->BPB) return $this->BPB;

        // Описания DOS 3.31 BPB для FAT12/16
        $bpb = array
        (
            'OEM'                       => $this->read_string(0x03, 8),
            'BytesPerSector'            => $this->read_word(0x0B),
            'SectorsPerCluster'         => $this->read_byte(0x0D),
            'ReservedSectors'           => $this->read_word(0x0E), // минимум 1 - включая boot-сектор
            'NumberOfFATs'              => $this->read_byte(0x10),
            'RootEntries'               => $this->read_word(0x11),
            'NumberOfSectors'           => $this->read_word(0x13),
            'MediaDescriptor'           => $this->read_byte(0x15),
            'SectorsPerFAT'             => $this->read_word(0x16),

            // DOS 3.31
            'SectorsPerHead'            => $this->read_word(0x18),
            'HeadsPerCylinder'          => $this->read_word(0x1A),
            'HiddenSectors'             => $this->read_dword(0x1C),
            'TotalLogicalSectors'       => $this->read_dword(0x20),

            // ------------------------------
            'PhysicalDriveNumber'       => $this->read_byte(0x24), // 0x00 - Floopy, 0x80 - HardDrive INT 0x13
            'ReservedDRN'               => $this->read_byte(0x25), // Резервировано (Флаги и др.)
            'ExtendedBootSignature'     => '0x' . dechex($this->read_byte(0x26)), // Should be 0x29

            'VolumeIDSerialNumber'      => '0x' . dechex($this->read_dword(0x27)),
            'PartitionVolumeLabel'      => $this->read_string(0x2B, 11),
            'FileSystemType'            => $this->read_string(0x36, 8),
        );

        // При проверке факта, что том является NTFS, необходимо прежде всего проверить сигнатуру «NTFS ».
        if ($bpb['OEM'] === 'NTFS    ' && $bpb['ReservedSectors'])
        {
            $this->is_NTFS = true;
        }

        $this->BPB = $bpb;
        return $bpb;
    }

    public function parse_date($word)
    {
        return array
        (
            'd' =>  ($word & 0x001F),
            'm' =>  ($word & 0x01E0) >> 5,
            'Y' => (($word & 0xFE00) >> 9) + 1980,
        );
    }

    public function parse_time($word)
    {
        return array
        (
            'H' => ($word & 0xF800) >> 10,
            'i' => ($word & 0x07E0) >> 5,
            's' => ($word & 0x001F),
        );
    }

    public function create_time($timestamp)
    {
        $H = date('H', $timestamp);
        $i = date('i', $timestamp);
        $s = date('s', $timestamp);

        return ($s + ($i << 5) + ($H << 10)) & 0xFFFF;
    }

    public function create_date($timestamp)
    {
        $d = date('d', $timestamp);
        $m = date('m', $timestamp);
        $Y = date('Y', $timestamp);

        return ($d + ($m << 5) + (($Y - 1980) << 9)) & 0xFFFF;
    }

    public function read_entry($seek)
    {
        $entry = array
        (
            'name'        => $this->read_string($seek, 8),
            'ext'         => $this->read_string($seek + 0x08, 3),
            'cluster'     => 65536 * $this->read_word($seek + 0x14) + $this->read_word($seek + 0x1A),
            'size'        => $this->read_dword($seek  + 0x1C),

            // Creation time in tenths of a second.
            'creation_time' => $this->read_byte($seek + 0x0D),
            'time_create'   => $this->parse_time($this->read_word($seek + 0x0E)),
            'date_create'   => $this->parse_date($this->read_word($seek + 0x10)),
            'date_access'   => $this->parse_date($this->read_word($seek + 0x12)),
            'time_modify'   => $this->parse_time($this->read_word($seek + 0x16)),
            'date_modify'   => $this->parse_date($this->read_word($seek + 0x18)),

            'attr'        => array(),
        );

        // Разбор атрибутов
        $attr = $this->read_byte($seek + 0x0B);

        if ($attr & 0x01) $entry['attr']['V'] = true; // бит "том"
        if ($attr & 0x02) $entry['attr']['D'] = true; // бит "каталог"
        if ($attr & 0x04) $entry['attr']['H'] = true;
        if ($attr & 0x08) $entry['attr']['S'] = true; // бит "системный"
        if ($attr & 0x10) $entry['attr']['A'] = true; // бит "архивный"
        if ($attr & 0x20) $entry['attr']['R'] = true; // бит "только для чтения"

        // Включен LongMode
        if ($attr & 0x0F == 0x0F) $entry['LFN'] = true;

        if (ord($entry['name'][0]) == 0xE5) $entry['DELETED'] = true;
        if (ord($entry['name'][0]) == 0x00) return FALSE;

        // todo ... long mode names ... LFN

        return $entry;
    }

    // Записать новые данные
    public function write_entry($entry_start, $entry)
    {
        $this->write_string($entry_start + 0x00, $entry['name']);
        $this->write_string($entry_start + 0x08, $entry['ext']);
        $this->write_word(  $entry_start + 0x14, ($entry['cluster'] >> 16) & 0xFFFF); // cluster.high
        $this->write_word(  $entry_start + 0x1A, $entry['cluster'] & 0xFFFF);         // cluster.low
        $this->write_dword( $entry_start + 0x1C, $entry['size']);

        $this->write_byte( $entry_start + 0x0D, $entry['creation_time']);
        $this->write_word( $entry_start + 0x0E, $entry['time_create']);
        $this->write_word( $entry_start + 0x10, $entry['date_create']);
        $this->write_word( $entry_start + 0x12, $entry['date_access']);
        $this->write_word( $entry_start + 0x16, $entry['time_modify']);
        $this->write_word( $entry_start + 0x18, $entry['date_modify']);

        $this->write_byte( $entry_start + 0x0B, $entry['attr']);
    }

    // Поиск свободного кластера
    public function find_free_cluster()
    {
        $fat_size = $this->BPB['SectorsPerFAT'] * $this->BPB['BytesPerSector'];

        if ($this->FATVersion == 12)
            $fat_size = intval($fat_size / 1.5);
        elseif ($this->FATVersion == 16)
            $fat_size = intval($fat_size / 2);
        else
            $fat_size = intval($fat_size / 4);

        // Просмотр всей таблицы fat
        for ($cluster = 2; $cluster < $fat_size; $cluster++)
        {
            $next = $this->read_FAT($cluster);
            if (!$next) return $cluster;
        }

        // Нет свободного места
        return 0;
    }

    // Официальный способ определить файловую систему
    public function fat_type_detection()
    {
        $bpb = $this->read_bpb();

        // Расчет количества секторов на корневую директорию
        $root_dir_sectors = intval( (($bpb['RootEntries'] * 32) + ($bpb['BytesPerSector'] - 1)) / $bpb['BytesPerSector'] );

        // Старт секторов данных
        $this->data_first_sector = ($bpb['ReservedSectors'] + ($bpb['NumberOfFATs'] * $bpb['SectorsPerFAT']) + $root_dir_sectors);

        // Сектор начала таблицы FAT1
        $this->data_fat1_table   = $bpb['ReservedSectors'];
        $this->data_fat2_table   = $bpb['ReservedSectors'] + $bpb['SectorsPerFAT'];

        // Количество секторов, отведенные на данные
        $data_sectors     = $bpb['NumberOfSectors'] - $this->data_first_sector;

        // Всего кластеров на сектор
        $total_clusters   = intval( $data_sectors / $bpb['SectorsPerCluster'] );

        if ($total_clusters < 4085)
        {
            $this->FATVersion = 12;
        }
        else
        {
            if ($total_clusters < 65525)
            {
                $this->FATVersion = 16;
            }
            else
            {
                $this->FATVersion = 32;
            }
        }

        // Прочитать маркер окончания файла
        if ($this->FATVersion == 12)
        {
            $this->EOC = $this->read_fat12_next_cluster(0) & 0x0FFF;
            $this->EOF = $this->read_fat12_next_cluster(1);
        }
        elseif ($this->FATVersion == 16)
        {
            $this->EOC = $this->read_word($this->data_fat1_table * $this->BPB['BytesPerSector'] + 0);
            $this->EOF = $this->read_word($this->data_fat1_table * $this->BPB['BytesPerSector'] + 2);
        }
        else
        {
            $this->EOC = $this->read_dword($this->data_fat1_table * $this->BPB['BytesPerSector'] + 0);
            $this->EOF = $this->read_dword($this->data_fat1_table * $this->BPB['BytesPerSector'] + 4);
        }

        return $this->FATVersion;
    }

    // Чтение корневого каталога (включая удаленные файлы)
    public function read_root_entries()
    {
        $bpb = $this->read_bpb();

        // Получаем номер сектора
        $root = $bpb['SectorsPerFAT'] * $bpb['NumberOfFATs'] + $bpb['ReservedSectors'];

        $list = array();
        $entry_row = 0;

        $seek_root = $root * $bpb['BytesPerSector'];

        while (($entry = $this->read_entry($seek_root + 0x20 * $entry_row)) && $entry_row < $bpb['RootEntries'])
        {
            // Номер позиции
            $entry['ENTRY_ROW'] = $entry_row;

            $list[] = $entry;
            $entry_row++;
        }

        return $list;
    }

    // Прочитать полуторабайты следующего сектора для FAT12
    public function read_fat12_next_cluster($cluster)
    {
        $W = $this->read_word( intval($this->data_fat1_table * $this->BPB['BytesPerSector'] + $cluster * 1.5) );

        if ($cluster % 2 == 0)
            return  $W & 0x0FFF;
        else
            return ($W & 0xFFF0) >> 4;
    }

    // ----------------------------------------------------
    // Битонезависимое чтение номера следующего кластера
    public function read_FAT($cluster)
    {
        $fat_start = $this->data_fat1_table * $this->BPB['BytesPerSector'];

        // 12 бит на кластер
        if ($this->FATVersion == 12)
        {
            return $this->read_fat12_next_cluster($cluster);
        }
        elseif ($this->FATVersion == 16) // 16 бит на кластер
        {
            return $this->read_word($fat_start + 2*$cluster);
        }
        else // 32 бит на кластер
        {
            return $this->read_dword($fat_start + 4*$cluster);
        }
    }

    // Обновление элемента цепи
    public function update_FAT($cluster, $value)
    {
        $fat1_start = $this->data_fat1_table * $this->BPB['BytesPerSector'];
        $fat2_start = $this->data_fat2_table * $this->BPB['BytesPerSector'];

        // 12 бит на кластер
        if ($this->FATVersion == 12)
        {
            $A1 = intval($fat1_start + $cluster * 1.5);
            $A2 = intval($fat2_start + $cluster * 1.5);

            // Читать значения из 2-х таблиц
            $W1 = $this->read_word($A1);
            $W2 = $this->read_word($A2);

            if ($cluster % 2 == 0)
            {
                $W1 = ($W1 & 0xF000) | ($value & 0x0FFF);
                $W2 = ($W2 & 0xF000) | ($value & 0x0FFF);
            }
            else
            {
                $W1 = ($W1 & 0x000F) | (($value & 0x0FFF) << 4);
                $W2 = ($W2 & 0x000F) | (($value & 0x0FFF) << 4);
            }

            $this->write_word($A1, $W1);
            $this->write_word($A2, $W2);
        }
        elseif ($this->FATVersion == 16)
        {
            $this->write_word($fat1_start + 2*$cluster, $value);
            $this->write_word($fat2_start + 2*$cluster, $value);
        }
        elseif ($this->FATVersion == 32)
        {
            $this->write_dword($fat1_start + 4*$cluster, $value);
            $this->write_dword($fat2_start + 4*$cluster, $value);
        }
    }
    // ----------------------------------------------------

    // Чтение файла из кластера
    public function read_file($cluster, $size)
    {
        $filebody     = '';
        $data_offset  = $this->data_first_sector;

        // Размер кластера
        $cluster_size = $this->BPB['SectorsPerCluster'] * $this->BPB['BytesPerSector'];

        while ($size > 0)
        {
            $current = ($data_offset + ($cluster - 2) * $this->BPB['SectorsPerCluster']) * $this->BPB['BytesPerSector'];

            // Размер оставшегося файла меньше, чем размер кластера, прочитать остальное и выйти
            if ($size <= $cluster_size)
            {
                fseek($this->disk_handler, $current, SEEK_SET);
                $filebody .= fread($this->disk_handler, $size);

                break;
            }
            else
            {
                fseek($this->disk_handler, $current, SEEK_SET);

                // Читаем кластер с позиции
                $filebody .= fread($this->disk_handler, $cluster_size);

                // Уменьшить остаточный размер на значение кластера
                $size -= $cluster_size;

                // Этот кластер является последним (первые 2 кластера)
                if ($cluster == $this->EOF || $cluster >= $this->EOC)
                    break;

                $cluster = $this->read_FAT($cluster);
            }
        }

        return $filebody;
    }

    // Поиск файла на диске
    public function search($name)
    {
        // Сначала ищем файл в корневой директории
        $data = $this->read_root_entries();

        // ----

        $whofile  = explode('.', strtoupper($name));

        $filename = str_pad($whofile[0], 8, ' ');
        $fileext  = isset($whofile[1]) ? str_pad($whofile[1], 3, ' ') : '   ';

        foreach ($data as $item)
        {
            if (isset($item['DELETED'])) continue;

            // Файл найден
            if ($item['name'] === $filename && $item['ext'] === $fileext)
                return $item;
        }

        return false;
    }

    // Создать файл в root-entry
    public function create_file($filename, $first_cluster, $file_size)
    {
        $bpb = $this->read_bpb();

        // Получаем номер сектора
        $root = $bpb['SectorsPerFAT'] * $bpb['NumberOfFATs'] + $bpb['ReservedSectors'];

        $entry_row = 0;
        $seek_root = $root * $bpb['BytesPerSector'];

        // Читаем таблицу RootEntries
        while ($entry_row < $bpb['RootEntries'])
        {
            $entry = $this->read_entry($seek_root + 0x20 * $entry_row);

            // ------------------------------------------------------
            // Либо запись удалена, либо не существует - вставка сюда
            // ------------------------------------------------------

            if (isset($entry['DELETED']) || !$entry)
            {
                $fn = explode('.', strtoupper($filename));

                // Верхний регистр, не более 8 символов
                $entry = array
                (
                    'name' => str_pad(substr($fn[0], 0, 8), 8, ' '),
                    'ext'  => (isset($fn[1])) ? str_pad(substr($fn[1], 0, 3), 3, ' ') : '   ',

                    'cluster'     => $first_cluster,
                    'size'        => $file_size,

                    'creation_time' => 0x00,
                    'time_create'   => $this->create_time(time()),
                    'date_create'   => $this->create_date(time()),
                    'date_access'   => $this->create_date(time()),
                    'time_modify'   => $this->create_time(time()),
                    'date_modify'   => $this->create_date(time()),

                    // 'attr'        => 0x02, // Каталог
                     'attr'        => 0x00, // Каталог
                );

                // Записать в каталог новый entry
                $this->write_entry($seek_root + 0x20 * $entry_row, $entry);

                return true;
            }

            $entry_row++;
        }

        return false;
    }

    // Затереть файл из FAT
    public function erase($item)
    {
        $cluster = $item['cluster'];

        $sector_root_start = $this->BPB['ReservedSectors'] + $this->BPB['NumberOfFATs'] * $this->BPB['SectorsPerFAT'];

        // Отметить файл как удаленный
        $this->write_byte($sector_root_start * $this->BPB['BytesPerSector'] + 32*$item['ENTRY_ROW'], 0xE5);

        do
        {
            // Получить указатель на следующий кластер
            $next_cluster = $this->read_FAT($cluster);

            // Удалить элемент цепи из FAT
            $this->update_FAT($cluster, 0);

            // Перейти на следующий кластер
            $cluster = $next_cluster;
        }
        // Либо EOF, либо EOC, либо NULL
        while ($cluster != $this->EOF || $cluster < $this->EOC || $next_cluster == 0);
    }
}

// ---------------------------------------------------------------------------------------------------------------------

$fatx      = new FATx();
$diskimage = isset($argv[1]) ? $argv[1] : NULL;
$command   = isset($argv[2]) ? $argv[2] : NULL;

if ($diskimage)
{
    $fatx->disk_handler = fopen($diskimage, 'r+');
    $outf = fopen("php://stderr", "w");

    $fatnumber = $fatx->fat_type_detection();

    // fwrite($outf, "FAT $fatnumber\n");
}
// ---------------------------------------------------------------------------------------------------------------------
if ($command == 'create')
{
    if (isset($argv[3]))
        $disk_size = $argv[3] * 1024 * 1024; // в мегабайтах
    else
    {
        $disk_size = 1474560;
        echo "default disk: floppy 1.44 mb\n";
    }

    ftruncate($fatx->disk_handler, 0);
    fseek($fatx->disk_handler, 0, SEEK_SET);

    while ($disk_size > 0)
    {
        if ($disk_size >= 4096)
        {
            fwrite($fatx->disk_handler, str_repeat(chr(0), 4096));
            $disk_size -= 4096;
        }
        else
        {
            fwrite($fatx->disk_handler, str_repeat(chr(0), $disk_size));
            $disk_size = 0;
        }
    }

    $fatx->write_dword(0,   0x0090FEEB); // jmp $+0 nop
    $fatx->write_word (510, 0xAA55);     // bootsignature


    echo "Операция создания диска выполнена\n";
}
// Дебаг BPB
// ---------------------------------------------------------------------------------------------------------------------
elseif ($command == 'read-bpb')
{
    $data = $fatx->read_bpb();

    print_r($data);
}
// ---------------------------------------------------------------------------------------------------------------------
elseif ($command == 'root')
{
    $data = $fatx->read_root_entries();
    foreach ($data as $item)
    {
        if (isset($item['DELETED'])) echo '- '; else echo '  ';

        echo $item['name'] . '.' . $item['ext'] . " " . join('', array_keys($item['attr'])) . ' ' . $item['size'] . '   ';
        echo '[create ' . join(':', $item['time_create']) . ' ' . join('/', $item['date_create']) . '] [access=' . join('/', $item['date_access']) . '] ';
        echo 'modify ' . join(':', $item['time_modify']) . ' ' . join('/', $item['date_modify']) . ']';
        echo "\n";
    }
}
// Прочитать файл
// ---------------------------------------------------------------------------------------------------------------------
elseif ($command == 'read')
{
    // Файл был успешно найден в таблице поиска?
    if ($item = $fatx->search($argv[3]))
    {
        fwrite($outf, "[found cluster=".$item['cluster']."], size = ".$item['size']."\n");

        echo $fatx->read_file($item['cluster'], $item['size']);
    }
}
// Стереть файл с диска
// ---------------------------------------------------------------------------------------------------------------------
elseif ($command == 'erase')
{
    // Файл был успешно найден в таблице поиска?
    if ($item = $fatx->search($argv[3]))
    {
        $fatx->erase($item);
        echo "DONE\n";
    }
    else echo "Nothing to do: file not found\n";
}
// Записать файл
// ---------------------------------------------------------------------------------------------------------------------
elseif ($command == 'write')
{
    // Если файл бы - стереть
    if ($item = $fatx->search($argv[3]))
    {
        $fatx->erase($item);
    }

    // Входной файл задан?
    $file_in = isset($argv[4]) ? fopen($argv[4], 'r') : fopen("php://stdin", 'r');

    // Размер кластера в байтах
    $cluster_size = $fatx->BPB['BytesPerSector'] * $fatx->BPB['SectorsPerCluster'];

    // Это - первый кластер
    $cluster      = 0;

    // Конечный размер файла
    $file_size    = 0;

    // Откуда начинаюстя данные
    $data_offset = $fatx->data_first_sector * $fatx->BPB['BytesPerSector'];

    // Запись файла
    do
    {
        $data_cluster = fread($file_in, $cluster_size);
        $data_length  = strlen($data_cluster);
        $file_size   += $data_length;

        // Дополняем нулями кластер
        $data_cluster = str_pad($data_cluster, $cluster_size, "\x00");

        // Поиск свободного кластера (если возможно)
        if (!($cluster_next = $fatx->find_free_cluster()))
            die("Нет свободного места на диске\n");

        // Записываем номер первого кластера цепи
        if (!$cluster) $first_cluster = $cluster_next;

        // Пишем последний сектор
        if (feof($file_in))
        {
            // Данные были получены?
            if ($data_length)
            {
                // Если этот сектор не первый был
                if ($cluster) $fatx->update_FAT($cluster, $cluster_next);

                // Пишем полученные данные
                fseek($fatx->disk_handler, ($cluster_next - 2) * $cluster_size + $data_offset, SEEK_SET);
                fwrite($fatx->disk_handler, $data_cluster);

                // Окончательный указатель EOF
                $fatx->update_FAT($cluster_next, $fatx->EOF);
            }

            break;
        }
        else
        {
            // Создается указатель на предыдущий кластер
            if ($cluster) $fatx->update_FAT($cluster, $cluster_next);

            // Пишем полученные данные
            fseek($fatx->disk_handler,  ($cluster_next - 2) * $cluster_size + $data_offset, SEEK_SET);
            fwrite($fatx->disk_handler, $data_cluster);

            // Пишем укзатель, что это конечная точка
            $fatx->update_FAT($cluster_next, $fatx->EOF);

            // Сохраняем указатель на номер этого кластера
            $cluster = $cluster_next;
        }
    }
    while (true);

    // Создать файл в RootEntries (либо в подкаталогах)
    if (!($fatx->create_file($argv[3], $first_cluster, $file_size)))
        die("Нет больше возможности добавить файл: слишком много файлов\n");
}
// Запись BOOT сектора
// ---------------------------------------------------------------------------------------------------------------------
elseif ($command == 'boot')
{
    // Входной файл задан?
    $file_in = isset($argv[3]) ? fopen($argv[3], 'r') : fopen("php://stdin", 'r');

    fseek($fatx->disk_handler, 0, SEEK_SET);
    fseek($fatx->disk_handler, 0, SEEK_SET);

    $origdisk = fread($fatx->disk_handler, 512);
    $bootcode = fread($file_in, 510) . chr(0x55) . chr(0xAA);

    for ($i = 0; $i < 512; $i++)
    {
        if ($i >= 3 && $i < 0x40) // BPB нельзя перезаписывать
        {
            $fatx->write_byte($i, ord($origdisk[$i]) );
        }
        else
        {
            $fatx->write_byte($i, ord($bootcode[$i]) );
        }
    }

    fclose($file_in);
}
// ---------------------------------------------------------------------------------------------------------------------
elseif ($command == 'format')
{
    $disk_size = filesize($diskimage);

    // Форматировать стандартный флоппи-диск
    if ($disk_size == 1474560)
    {
        $fatx->write_bpb();

        // Очистка 2x таблиц FAT
        for ($i = 0; $i < 9 * 512 * 2; $i++) $fatx->write_word(0x200 + $i, 0x00);

        if ($fatx->FATVersion == 12)
        {
            // FAT-1
            $fatx->write_word(0x200,     0xFFF0);   // EOC-1
            $fatx->write_byte(0x202,     0xFF);     // EOF-1

            // FAT-2
            $fatx->write_word(0x200 + 9*512, 0xFFF0);  // EOC-1
            $fatx->write_byte(0x202 + 9*512, 0xFF);    // EOF-1
        }
        else
        {
            // todo not implemented
        }
    }
    else
    {
        echo " non-floppy not supported yet\n";
    }
}
else
{
    echo "\n";
    echo "  php fat32.php <diskimage> ...\n";
    echo "\n";
    echo "  create [fd|mb]    -- создать чистый образа диска (мегабайт). С stub-boot сектором.\n";
    echo "  format            -- отформатировать диск/дискету в fat\n";
    echo "  read-bpb          -- прочитать подробные данные о BPB\n";
    echo "  root              -- вывести листинг корневой таблицы\n";
    echo "  read <file>       -- прочесть файл в stdout\n";
    echo "  write <to_file> <in_file> -- записать файл на диск\n";
    echo "  boot <boot.bin>    -- записать бут-сектор\n";

    echo "\n";
}

if ($diskimage && isset($outf))
{
    fclose($fatx->disk_handler);
    fclose($outf);
}
