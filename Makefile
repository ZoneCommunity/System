CC = nasm

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
TUI_SRC=$(SRCDIR)/tui/tui.asm
COMMAND_SRC=$(SRCDIR)/utils/command2.asm

BOOT_BIN=$(BUILDDIR)/boot.bin
KERNEL_BIN=$(BUILDDIR)/kernel.bin
TUI_BIN=$(BUILDDIR)/tui.bin
COMMAND_BIN=$(BUILDDIR)/command.com
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

# Rule to compile tui.asm to tui.bin
$(TUI_BIN): $(TUI_SRC)
	@mkdir -p $(BUILDDIR)
	$(NASM) $(NASMFLAGS) -o $@ $<

# Rule to compile command.asm to command.com
$(COMMAND_BIN): $(COMMAND_SRC)
	@mkdir -p $(BUILDDIR)
	$(NASM) -f bin -o $@ $<

# Rule to merge bootloader.bin, kernel.bin, and command.com into os.bin
merge_boot_kernel: $(BOOT_BIN) $(KERNEL_BIN)
	cat $(BOOT_BIN) $(KERNEL_BIN) > $(OS_BIN)
	dd if=build/os.bin of=build/os.img
	mkdir -v iso
	mv -v build/os.img iso
	mkisofs -b os.img -no-emul-boot -o iso/os.iso iso/

# Rule to run os.bin with qemu
run_os: $(OS_BIN)
	qemu-system-x86_64 iso/os.img

# Clean
clean:
	rm -rf $(BUILDDIR)
	rm -rf iso

# Build boot
build_boot: $(BOOT_BIN)

# Build kernel
build_kernel: $(KERNEL_BIN)

# Build tui
build_tui: $(TUI_BIN)

# Build command
build_command: $(COMMAND_BIN)

.PHONY: all clean run_os build_boot build_kernel build_tui build_command merge_boot_kernel
