# Define compiler and flags
NASM=nasm
NASMFLAGS=-f bin

# Define source and build directories
SRCDIR=src
BUILDDIR=build
ISODIR=iso

# Define input and output files
BOOT_SRC=$(SRCDIR)/boot.asm
KERNEL_SRC=$(SRCDIR)/kernel.asm

BOOT_BIN=$(BUILDDIR)/boot.bin
KERNEL_BIN=$(BUILDDIR)/kernel.bin
OS_BIN=$(BUILDDIR)/os.bin
OS_IMG=$(BUILDDIR)/os.img
IMG_SIZE=1440

# Default target
all: clean build_boot build_kernel build_os_img create_iso run_os

# Rule to compile Boot.asm to boot.bin
$(BOOT_BIN): $(BOOT_SRC)
	@mkdir -p $(BUILDDIR)
	$(NASM) $(NASMFLAGS) -o $@ $<

# Rule to compile kernel.asm to kernel.bin
$(KERNEL_BIN): $(KERNEL_SRC)
	@mkdir -p $(BUILDDIR)
	$(NASM) $(NASMFLAGS) -o $@ $<

# Rule to concatenate boot.bin and kernel.bin into os.bin
$(OS_BIN): $(BOOT_BIN) $(KERNEL_BIN)
	cat $^ > $@

# Rule to create the OS image from os.bin
$(OS_IMG): $(OS_BIN)
	dd if=/dev/zero of=$@ bs=512 count=$(IMG_SIZE)
	dd if=$< of=$@ conv=notrunc

# Rule to run os.img with qemu
run_os: $(OS_IMG)
	qemu-system-x86_64 $<

# Clean
clean:
	rm -rf $(BUILDDIR)
	rm -rf $(ISODIR)

# Build boot
build_boot: $(BOOT_BIN)

# Build kernel
build_kernel: $(KERNEL_BIN)

# Build OS image
build_os_img: $(OS_IMG)

.PHONY: all clean build_boot build_kernel build_os_img create_iso
