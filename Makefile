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
ISO_FILE=$(ISODIR)/os.iso
OS_ISO=$(ISODIR)/os.iso


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

# Rule to create a blank disk image and copy bootloader and kernel into it
build_os_img: $(BOOT_BIN) $(KERNEL_BIN)
	dd if=/dev/zero of=$(OS_IMG) bs=512 count=2880
	cat $(BOOT_BIN) $(KERNEL_BIN) > $(OS_IMG)

# Rule to create the ISO image
create_iso: build_os_img
	mkdir -p $(ISODIR)
	cp $(BOOT_BIN) $(KERNEL_BIN) $(ISODIR)
	mkisofs -b boot.bin -no-emul-boot -o $(OS_ISO) $(ISODIR)

# Rule to run os.bin with qemu
run_os:
	qemu-system-x86_64 build/os.img

# Clean
clean:
	rm -rf $(BUILDDIR)
	rm -rf $(ISODIR)

# Build boot
build_boot: $(BOOT_BIN)

# Build kernel
build_kernel: $(KERNEL_BIN)

.PHONY: all clean build_boot build_kernel build_os_img create_iso
