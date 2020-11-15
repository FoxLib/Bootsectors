#!/bin/sh

# 1. Ассемблируем запускной файл для kernel.c с ISR-процедурами
if (nasm -felf64 -o startup.o nasm/startup.asm)
then

    # 2. Компиляция 64-битного ядра
    if (clang -Os -ffreestanding -m64 -msse -msse2 -c -o kernel.o kernel64.c)
    then

        # Отладка
        # objdump -M intel-mnemonic -S kernel.o
        
        # 3. Компиляция 64-битного Kernel        
        # 1`00000 - 2`7FFFF КОД     1.5 мб
        # 2`80000 - 3`7FFFF ДАННЫЕ  1 мб      
        #  
        
        if (ld -m elf_x86_64 -nostdlib -nodefaultlibs --oformat binary -Ttext=0x100000 -Tdata=0x280000 startup.o kernel.o -o kernel.c.bin)
        then

            # 4. Скомпилировать стартер в 64 битный режим + полученный [kernel.c.bin]
            if (fasm kernel.asm) 
            then

                # 5. Переместить готовый файл на диск
                if (mv kernel.bin disk/kernel.run)
                then

                    rm *.o
                    rm kernel.c.bin
                    
                    bochs -f c.bxrc -q

                fi
            fi            
        fi
    fi
fi
