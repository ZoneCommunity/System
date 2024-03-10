CC = nasm

# Define compiler and flags
NASM=nasm
NASMFLAGS=-f bin

# Define source and build directories
SRCDIR=src
SRCEXTDIR=srcext
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
OS_IMG=$(BUILDDIR)/os.img
ISO_FILE=$(ISODIR)/os.iso

# List of files to copy from srcext to os.img
SRCEXT_FILES=$(wildcard $(SRCEXTDIR)/*)

# Default target
all: clean build_boot build_kernel build_command build_os run_os

# Rule to compile Boot.asm to boot.bin
$(BOOT_BIN): $(BOOT_SRC)
	@mkdir -p $(BUILDDIR)
	$(NASM) $(NASMFLAGS) -o $@ $<

# Rule to compile kernel.asm to kernel.bin
$(KERNEL_BIN): $(KERNEL_SRC)
	@mkdir -p $(BUILDDIR)
	$(NASM) $(NASMFLAGS) -o $@ $<

# Rule to compile command.asm to command.com
$(COMMAND_BIN): $(COMMAND_SRC)
	@mkdir -p $(BUILDDIR)
	$(NASM) -f bin -o $@ $<

# Rule to create the os.img file with the file system and copy srcext files
$(OS_IMG): $(BOOT_BIN) $(KERNEL_BIN) $(COMMAND_BIN) $(SRCEXT_FILES)
	dd if=/dev/zero of=$@ bs=512 count=2880
	mformat -i $@ -f 1440 ::
	@for file in $(BOOT_BIN) $(KERNEL_BIN) $(COMMAND_BIN) $(SRCEXT_FILES); do \
		mcopy -i $@ $$file ::; \
	done

# Rule to run os.img with qemu
run_os: $(OS_IMG)
	qemu-system-x86_64 $<

# Clean
clean:
	rm -rf $(BUILDDIR)
	rm -rf iso

# Build boot
build_boot: $(BOOT_BIN)

# Build kernel
build_kernel: $(KERNEL_BIN)

# Build command
build_command: $(COMMAND_BIN)

# Build os
build_os: $(OS_IMG)

.PHONY: all clean run_os build_boot build_kernel build_command build_os
