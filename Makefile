CC = nasm

# Define compiler and flags
NASM=nasm
NASMFLAGS=-f bin

# Define source and build directories
SRCDIR=src32
BUILDDIR=build
ISODIR=iso

# Define input and output files
BOOT_SRC=$(SRCDIR)/boot.asm # change this to boot later
KERNEL_SRC=$(SRCDIR)/kernel.asm

BOOT_BIN=$(BUILDDIR)/boot.bin
KERNEL_BIN=$(BUILDDIR)/kernel.bin
OS_BIN=$(BUILDDIR)/os.bin
ISO_FILE=$(ISODIR)/os.iso

# Default target
all: clean build_boot build_kernel merge_boot_kernel run_os

# Rule to compile Boot.asm to boot.bin
$(BOOT_BIN): $(BOOT_SRC)
	@mkdir -p $(BUILDDIR)
	$(NASM) $(NASMFLAGS) -o $@ $<

# Rule to compile kernel.asm to kernel.bin
$(KERNEL_BIN): $(KERNEL_SRC)
	@mkdir -p $(BUILDDIR)
	$(NASM) $(NASMFLAGS) -o $@ $<

# Rule to merge bootloader.bin and kernel.bin into os.bin
merge_boot_kernel: $(BOOT_BIN) $(KERNEL_BIN)
	cat $(BOOT_BIN) $(KERNEL_BIN) > $(OS_BIN)

# Rule to run os.bin with qemu
run_os: $(OS_BIN)
	qemu-system-x86_64 $(OS_BIN)

# Clean
clean:
	rm -rf $(BUILDDIR)

# Build boot
build_boot: $(BOOT_BIN)

# Build kernel
build_kernel: $(KERNEL_BIN)

.PHONY: all clean run_os build_boot build_kernel merge_boot_kernel
