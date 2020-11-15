<?php 

/*
 * Преобразование изображения в 16-цветное
 */

class Dithering {

    protected $w;
    protected $h;
    protected $color_plane;
    
    protected $colors_num = 16;
    protected $colors_tbl = 'colors';
    
    protected $colors4 = array(
    
        // R    G    B
//        [  0,   0,   0], // 0 Черный
//        [  0, 255, 255], // 1 Голубой
//        [255,   0, 255], // 2 Пурпурный
//        [255, 255, 255], // 3 Белый

        // Эта палитра подходит лучше
        [  0,   0,   0], // 0 Черный
        [  0,   0, 255], // 1 Синий
        [  0, 255,   0], // 2 Желтый 255 255 0
        [255, 255, 255], // 3 Белый        
    );
    
    protected $colors2 = array(
    
        [  0,   0,   0], // 0 Черный
        [255, 255, 255], // 1 Белый
    
    );

    // Стандартная цветовая палитра 16 цветов
    protected $colors = array
    (
        [  0,   0,   0],  // 0
        [  0,   0, 128],  // 1
        [  0, 128,   0],  // 2
        [  0, 128, 128],  // 3
        [128,   0,   0],  // 4
        [128,   0, 128],  // 5
        [128, 128,   0],  // 6
        [192, 192, 192],  // 7
        [128, 128, 128],  // 8
        [  0,   0, 255],  // 9
        [  0, 255,   0],  // 10
        [  0, 255, 255],  // 11
        [255,   0,   0],  // 12
        [255,   0, 255],  // 13
        [255, 255,   0],  // 14
        [255, 255, 255],  // 15
    );
    
    public function set4colors() {
        
        $this->colors_num = 4;
        $this->colors_tbl = 'colors4';
        
    }
    
    public function set2colors() {

        $this->colors_num = 2;
        $this->colors_tbl = 'colors2';
        
    }

    /*
     * Найти ближайший color_id
     */

    public function search_nearest($r, $g, $b)
    {
        $psort = array();

        $colors = $this->colors_tbl;
        for ($k = 0; $k < $this->colors_num; $k++) {

            $dist = pow($r - $this->$colors[ $k ][0], 2) +
                    pow($g - $this->$colors[ $k ][1], 2) +
                    pow($b - $this->$colors[ $k ][2], 2);

            $psort[$k] = $dist;
        }

        // Отсортировать по ближайшему
        asort($psort);

        // Вернуть номер цвета
        return key($psort);
    }

    /*
     * Выполнить канальный Dithering
     */

    public function dither_channels($R, $G, $B, $dith = 1)
    {
        $C = array();
        $colors = $this->colors_tbl;

        for ($y = 0; $y < $this->h; $y++) {

            for ($x = 0; $x < $this->w; $x++) {

                // Старые цвета
                list($old_R, $old_G, $old_B) = array($R[$x][$y], $G[$x][$y], $B[$x][$y]);

                // Поиск ближайшего цвета из палитры
                $color_id = $this->search_nearest($old_R, $old_G, $old_B);

                // Новые цвета
                list($new_R, $new_G, $new_B) = array(
                    $this->$colors[ $color_id ][0],
                    $this->$colors[ $color_id ][1],
                    $this->$colors[ $color_id ][2]
                );

                // Записать обратно
                list($R[$x][$y], $G[$x][$y], $B[$x][$y]) = array($new_R, $new_G, $new_B);

                // Записать номер цвета
                $C[$x][$y] = $color_id;

                // Вычисляем ошибку квантования
                list($quant_error_R, $quant_error_G, $quant_error_B) = array($old_R - $new_R, $old_G - $new_G, $old_B - $new_B);

                // ----------------------
                // Распространение ошибки
                // ----------------------
                
                if ($dith) {                

                    // Канал RED
                    $R[$x + 1][$y    ] = @$R[$x + 1][$y    ] + $quant_error_R * 7 / 16;
                    $R[$x - 1][$y + 1] = @$R[$x - 1][$y + 1] + $quant_error_R * 3 / 16;
                    $R[$x    ][$y + 1] = @$R[$x    ][$y + 1] + $quant_error_R * 5 / 16;
                    $R[$x + 1][$y + 1] = @$R[$x + 1][$y + 1] + $quant_error_R * 1 / 16;

                    // Канал GREEN
                    $G[$x + 1][$y    ] = @$G[$x + 1][$y    ] + $quant_error_G * 7 / 16;
                    $G[$x - 1][$y + 1] = @$G[$x - 1][$y + 1] + $quant_error_G * 3 / 16;
                    $G[$x    ][$y + 1] = @$G[$x    ][$y + 1] + $quant_error_G * 5 / 16;
                    $G[$x + 1][$y + 1] = @$G[$x + 1][$y + 1] + $quant_error_G * 1 / 16;

                    // Канал BLUE
                    $B[$x + 1][$y    ] = @$B[$x + 1][$y    ] + $quant_error_B * 7 / 16;
                    $B[$x - 1][$y + 1] = @$B[$x - 1][$y + 1] + $quant_error_B * 3 / 16;
                    $B[$x    ][$y + 1] = @$B[$x    ][$y + 1] + $quant_error_B * 5 / 16;
                    $B[$x + 1][$y + 1] = @$B[$x + 1][$y + 1] + $quant_error_B * 1 / 16;
                
                }
            }
            
            echo round($y / $this->h * 100, 2) . "%\r";
        }

        return [$R, $G, $B, $C];
    }

    /*
     * Создать новое изображение
     */

    public function create($im, $DTH = true)
    {
        $R = $G = $B = array();

        if (empty($im)) {

            echo "ОШИБКА загрузки изображения\n";
            exit(1);
        }

        // Определение размера
        list($this->w, $this->h) = [imagesx($im), imagesy($im)];

        // Создать новое изображение
        $out = imagecreate($this->w, $this->h);
        $colors = $this->colors_tbl;
        
        for ($i = 0; $i < $this->colors_num; $i++) {
            imagecolorallocate($out, $this->$colors[$i][0], $this->$colors[$i][1], $this->$colors[$i][2]);
        }

        // Разделить на каналы
        for ($y = 0; $y < $this->h; $y++) {

            for ($x = 0; $x < $this->w; $x++) {

                $R[$x][$y] = (imagecolorat($im, $x, $y) >> 16) & 255;
                $G[$x][$y] = (imagecolorat($im, $x, $y) >> 8) & 255;
                $B[$x][$y] =  imagecolorat($im, $x, $y) & 255;
            }                    
        }

        // Выполнить основной процессинг
        list($R, $G, $B, $C) = $this->dither_channels($R, $G, $B, $DTH);

        // Найти цвета
        for ($y = 0; $y < $this->h; $y++) {
            for ($x = 0; $x < $this->w; $x++) {
                imagesetpixel($out, $x, $y, $C[$x][$y]);
            }
        }

        // Запись информации о полученных ID цветах
        $this->color_plane = $C;

        // Результирующее изображение
        return $out;
    }    
}
