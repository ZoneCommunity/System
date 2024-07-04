nasm -f bin -o build/boot.bin src/boot.asm
nasm -f bin -o build/kernel.bin src/kernel.asm

cat build/boot.bin build/kernel.bin > build/os.bin

qemu-system-x86_64 build/os.bin