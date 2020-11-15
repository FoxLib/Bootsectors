#!/bin/sh

if (fasm pikos.asm)
then
	if (mv pikos.bin disk/pikos.com)
	then	
		bochs -f c.bxrc -q
	fi    
fi
