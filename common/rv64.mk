# rv64.mk — shared build rules for every lab in this repo.
#
# A per-lab Makefile only needs to say:
#
#     PROG = hello
#     include ../../common/rv64.mk
#
# Targets: all (default), run, debug, dump, clean, help
# Students should not need to edit this file.

# ---------------------------------------------------------------- locations
# Resolve paths relative to THIS file, so labs work from any directory depth.
COMMON    := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
REPO_ROOT := $(abspath $(COMMON)/..)
SCRIPTS   := $(REPO_ROOT)/scripts

# ---------------------------------------------------------------- toolchain
# setup.sh writes common/toolchain.env after probing which RISC-V toolchain is
# actually installed. That file uses `KEY=value` syntax, which is valid for
# BOTH make and sh, so scripts/ can source the same file.
-include $(COMMON)/toolchain.env

# Fall back to probing PATH if toolchain.env is missing (e.g. repo copied by
# hand without running setup.sh). riscv64-linux-gnu- is the apt package on
# Raspberry Pi OS and is the expected one; the others are for dev machines.
ifeq ($(strip $(RISCV_PREFIX)),)
RISCV_PREFIX := $(shell for p in riscv64-linux-gnu- riscv64-unknown-elf- \
                                 riscv64-elf-; do \
                    command -v $${p}gcc >/dev/null 2>&1 && { echo $$p; break; }; \
                  done)
endif

# Only hard-fail on targets that actually need the toolchain.
ifeq ($(strip $(RISCV_PREFIX)),)
ifeq ($(filter clean help,$(MAKECMDGOALS)),)
$(error No RISC-V compiler found on PATH. Run ~/comparch/setup.sh first)
endif
endif

CC      := $(RISCV_PREFIX)gcc
OBJDUMP := $(RISCV_PREFIX)objdump
QEMU    := qemu-system-riscv64

# gdb-multiarch is what apt provides on Raspberry Pi OS; it speaks RISC-V.
# A toolchain-native gdb is used instead if one happens to be installed.
GDB := $(shell command -v gdb-multiarch 2>/dev/null \
              || command -v $(RISCV_PREFIX)gdb 2>/dev/null \
              || echo gdb-multiarch)

# ---------------------------------------------------------------- ISA flags
# RV64GC = the 64-bit base integer ISA (rv64i) plus the G set (multiply,
# atomics, single- and double-precision float) and C (compressed, 2-byte
# instructions). This matches the course materials.
ARCH ?= rv64gc
ABI  ?= lp64d

CFLAGS := -march=$(ARCH) -mabi=$(ABI) -g -Wall

# We use a Linux-targeting toolchain to build bare-metal programs, so we must
# switch off everything it would normally assume:
#   -nostdlib -nostartfiles  no libc, no crt0 -- _start really is the entry
#   -no-pie -static          Debian gcc defaults to PIE; we need a fixed
#                            load address of 0x80000000, so force EXEC
#   --build-id=none          drop the build-id note section
LDFLAGS := -nostdlib -nostartfiles -no-pie -static \
           -Wl,--build-id=none -T $(COMMON)/link.ld

# Our single load segment can trip a spurious warning on newer binutils.
# Only pass the suppression flag if this linker understands it.
LDFLAGS += $(shell $(RISCV_PREFIX)ld --help 2>/dev/null \
                   | grep -q -- '--no-warn-rwx-segments' \
                   && echo -Wl,--no-warn-rwx-segments)

GDB_PORT ?= 1234

# ---------------------------------------------------------------- artifacts
PROG ?= hello
ELF  := $(PROG).elf
OBJ  := $(PROG).o

# Labs that print numbers or strings link against common/uart.s. Lab 0 does
# not -- it is deliberately self-contained so there is exactly one file to
# read when you are checking your environment works.
USE_UART ?= 0
ifeq ($(USE_UART),1)
OBJ += uart.o
endif

# A lab that needs to link extra objects (the C bridge lab compiles a .c file)
# sets EXTRA_OBJS before including this file, and supplies its own rule for
# building them.
EXTRA_OBJS ?=
OBJ += $(EXTRA_OBJS)

.PHONY: all run debug dump clean help
.DEFAULT_GOAL := all

all: $(ELF)

# Assemble and link are kept as separate steps on purpose: it mirrors the
# toolchain pipeline described in Patterson & Hennessy chapter 2.
$(PROG).o: $(PROG).s
	@echo "  AS      $<"
	@$(CC) $(CFLAGS) -c $< -o $@

uart.o: $(COMMON)/uart.s
	@echo "  AS      common/uart.s"
	@$(CC) $(CFLAGS) -c $< -o $@

$(ELF): $(OBJ) $(COMMON)/link.ld
	@echo "  LD      $@"
	@$(CC) $(CFLAGS) $(LDFLAGS) $(OBJ) -o $@
	@echo "  OK      built $@ ($(ARCH)/$(ABI))"

# ---------------------------------------------------------------- run/debug
run: $(ELF)
	@echo ""
	@echo "  Running $(ELF) under QEMU."
	@echo "  If it does not exit on its own, quit with:  Ctrl-A  then  X"
	@echo ""
	@$(SCRIPTS)/run_qemu.sh $(ELF)

debug: $(ELF)
	@$(SCRIPTS)/run_qemu.sh --debug --port $(GDB_PORT) $(ELF)

# Disassemble what the assembler actually produced. Worth doing on every lab:
# this is where you see pseudo-instructions expand into real machine code, and
# where 2-byte compressed (c.*) instructions become visible.
dump: $(ELF)
	@$(OBJDUMP) -d -M no-aliases,numeric $(ELF)

clean:
	@rm -f *.o *.elf *.bin *.dump $(EXTRA_CLEAN)
	@echo "  CLEAN   $(CURDIR)"

help:
	@echo "Targets for this lab:"
	@echo "  make          assemble and link $(PROG).s -> $(ELF)"
	@echo "  make run      run $(ELF) in QEMU (quit with Ctrl-A then X)"
	@echo "  make debug    run under QEMU's GDB stub on port $(GDB_PORT)"
	@echo "  make dump     disassemble $(ELF) to see the machine code"
	@echo "  make clean    delete build artifacts"
	@echo ""
	@echo "Toolchain: $(RISCV_PREFIX)  ISA: $(ARCH)/$(ABI)  GDB: $(GDB)"
