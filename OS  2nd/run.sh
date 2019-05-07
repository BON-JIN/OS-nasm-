#!/bin/bash

rm boot.bin
rm sector2.bin
rm image.bin
nasm boot.asm -f bin -o boot.bin
nasm sector2.asm -f bin -o sector2.bin
cat boot.bin sector2.bin > image.bin

qemu-system-i386 -fda image.bin



#sudo dd if=boot.bin of=/dev/sd3 bs=512
#sudo dd if=boot2.bin of=/dev/sd3 bs=512 seek=1
