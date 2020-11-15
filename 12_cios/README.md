# OS
Операционная система защищенного режима на C/Fasm

Необходимо создать пустой файл c.img объемом, например, 2004877312 байт.

Как собрать и запустить ОС:
<pre> 
  cd boot && fasm boot.asm && dd conv=notrunc if=boot.bin of=../c.img bs=446 count=1
  sh make
</pre>
И на этом все.
