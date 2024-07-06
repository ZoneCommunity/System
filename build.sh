# asm to bin
nasm -f bin -o build/boot.bin src/Boot/Boot.asm
nasm -f bin -o build/kernel.bin src/kernel.asm

# disk image
dd if=/dev/zero of=build/ReDOS.img bs=512 count=2880
mkfs.fat -F 12 -n "REDOS" build/ReDOS.img
dd if=build/boot.bin of=build/ReDOS.img conv=notrunc
mcopy -i build/ReDOS.img build/kernel.bin "::kernel.bin"
mcopy -i build/ReDOS.img build/test.txt "::test.txt"
mcopy -i build/ReDOS.img build/system "::system"


qemu-system-i386 -boot c -m 256 -fda build/ReDOS.img
