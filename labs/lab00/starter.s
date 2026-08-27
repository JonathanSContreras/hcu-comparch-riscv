# lab00/starter.s — setup verification.
#
# This program is already complete and working. Your job in Lab 0 is not to
# write RISC-V code -- it is to prove that your Pi can build and run it.
#
# Read it anyway. Every line of it is explained in the lab README, and you
# will be writing code like this from Lab 1 onward.
#
# Build and run:   make        then    make run
# Inspect it:      make dump
# Quit QEMU:       Ctrl-A  then  X

    .section .text.init
    .globl _start

# QEMU `virt` device addresses. There is no operating system running here, so
# printing a character means storing a byte straight to the serial port's
# data register. That is memory-mapped I/O.
    .equ UART_BASE,    0x10000000   # store a byte here to print a character
    .equ TEST_BASE,    0x00100000   # write FINISH_PASS here to power off
    .equ FINISH_PASS,  0x5555

_start:
    la      t0, msg                 # t0 = address of the first character
    li      t1, UART_BASE           # t1 = the UART's data register

print_loop:
    lbu     t2, 0(t0)               # load one byte, zero-extended
    beqz    t2, done                # a 0 byte marks the end of the string
    sb      t2, 0(t1)               # <-- the actual "print"
    addi    t0, t0, 1               # advance to the next character
    j       print_loop

done:
    li      t1, TEST_BASE           # shut QEMU down cleanly so that
    li      t2, FINISH_PASS         # `make run` returns to your shell
    sw      t2, 0(t1)

hang:
    j       hang

    .section .rodata
msg:
    # ---------------------------------------------------------------- TODO --
    # Replace <your name here> with your own name, then run `make run` again.
    # Seeing your own name proves you can edit, rebuild, and run -- which is
    # the entire point of Lab 0.
    .string "Hello, RISC-V -- <your name here>\n"
