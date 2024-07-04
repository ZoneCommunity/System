# asm to bin
nasm -f bin -o build/boot.bin src/boot.asm
nasm -f bin -o build/kernel.bin src/kernel.asm

# disk image
dd if=/dev/zero of=build/ReDOS.img bs=512 count=2880

# copy bootloader to the disk img
dd if=build/boot.bin of=build/ReDOS.img conv=notrunc bs=512 count=1

# init FAT12
dd if=/dev/zero bs=512 count=1 > build/fat12.bin

# FAT tables (0xF8)
echo -n -e "\xF8\xFF\xFF" | dd of=build/fat12.bin conv=notrunc bs=1 seek=0
echo -n -e "\xF8\xFF\xFF" | dd of=build/fat12.bin conv=notrunc bs=1 seek=512

# move to disk image (sectors 1-9 for first FAT, 10-18 for second FAT, 19-32 for root directory)
dd if=build/fat12.bin of=build/ReDOS.img conv=notrunc bs=512 seek=1 count=32

# Run QEMU
qemu-system-x86_64 -fda build/ReDOS.img
