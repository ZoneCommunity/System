# asm to bin
nasm -f bin -o build/boot.bin src/boot.asm
nasm -f bin -o build/kernel.bin src/kernel.asm

# disk image
dd if=/dev/zero of=build/ReDOS.img bs=512 count=2880

# copy bootloader to the disk img
dd if=build/boot.bin of=build/ReDOS.img conv=notrunc bs=512 count=1

# copy kernel to the disk img (sector 2)
dd if=build/kernel.bin of=build/ReDOS.img conv=notrunc bs=512 seek=1

# Run QEMU
qemu-system-x86_64 -fda build/ReDOS.img