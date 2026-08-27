# lab05 — build rules come from the shared file; see common/rv64.mk.
#
# This lab is the odd one out: it links a C file alongside the assembly, so it
# adds compute.o to the build and supplies the rule for it.
# `make help` lists every target.

PROG        = bridge
USE_UART    = 1
EXTRA_OBJS  = compute.o
EXTRA_CLEAN = compute.s

include ../../common/rv64.mk

compute.o: compute.c
	@echo "  CC      compute.c"
	@$(CC) $(CFLAGS) $(COPT) -c $< -o $@

# Compile the C to ASSEMBLY without assembling it, so you can read what the
# compiler produced. Try COPT=-O2 and diff the result against -O0.
COPT ?= -O0

.PHONY: cbuild
cbuild: compute.c
	@echo "  CC      compute.c ($(COPT)) -> compute.s"
	@$(CC) $(CFLAGS) $(COPT) -S -fverbose-asm compute.c -o compute.s
	@echo "  OK      open compute.s -- that is the compiler's assembly"
