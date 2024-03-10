# Define variables
NASM=nasm
DD=dd
MFORMAT=mformat
MOUNT=mnt

# Define targets
all: Boot1.bin KRNLDR.SYS os.flp

# Compile Boot1.asm into Boot1.bin
Boot1.bin: Boot1.asm
	$(NASM) -f bin Boot1.asm -o Boot1.bin

# Compile Stage2.asm into KRNLDR.SYS
KRNLDR.SYS: Stage2.asm
	$(NASM) -f bin Stage2.asm -o KRNLDR.SYS

# Create the OS floppy image
# Create the OS floppy image
os.flp: Boot1.bin KRNLDR.SYS
	# Create a blank floppy disk image of 1.44MB size (standard size for floppy disks)
	dd if=/dev/zero of=os.img bs=512 count=2880
	# Copy Boot1.bin to the floppy disk image
	dd if=Boot1.bin of=os.img bs=512 count=3 conv=notrunc
	dd if=Boot1.bin of=os.img bs=512 skip=62 seek=1 conv=notrunc
	# Concatenate KRNLDR.SYS to the floppy disk image at the appropriate location
	cat KRNLDR.SYS >> os.img


# Clean up intermediate and generated files
clean:
	rm -f Boot1.bin KRNLDR.SYS os.img
