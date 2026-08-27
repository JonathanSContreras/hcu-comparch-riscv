# hello.s — the environment sanity check for the HCU Computer Architecture lab.
#
# This is NOT a lab assignment. It exists so setup.sh can prove the whole
# chain works end to end: compiler -> linker -> QEMU -> your terminal.
# If this prints "Hello, RISC-V" you have a working RISC-V environment.
#
# The target is RV64GC: the 64-bit base integer ISA plus the standard G
# extensions and C (compressed) instructions. There is no operating system
# here -- no Linux, no libc, no printf. The program runs on the bare machine,
# so printing a character means storing a byte to a device register at a fixed
# memory address. That is memory-mapped I/O.

    .section .text.init
    .globl _start

# QEMU's `virt` machine memory map (the two addresses we care about):
    .equ UART_BASE,    0x10000000   # NS16550A serial port; store a byte here
                                    # and it appears in the terminal
    .equ TEST_BASE,    0x00100000   # SiFive "test finisher" device
    .equ FINISH_PASS,  0x5555       # writing this word powers the machine off

_start:
    la      t0, msg                 # t0 = address of the first character
    li      t1, UART_BASE           # t1 = the UART's data register

print_loop:
    lbu     t2, 0(t0)               # load one byte (zero-extended) from t0
    beqz    t2, done                # a 0 byte marks the end of the string
    sb      t2, 0(t1)               # <-- the actual "print": store to the UART
    addi    t0, t0, 1               # advance to the next character
    j       print_loop

done:
    # Tell QEMU to shut down cleanly, so `make run` returns to your shell
    # instead of hanging. On real hardware there would be nothing to return
    # to, which is why bare-metal programs normally just spin forever.
    #
    # Note we use `sw` (store word, 32 bits) and not `sd` (store doubleword,
    # 64 bits) even though this is RV64: the finisher register is 32 bits wide.
    li      t1, TEST_BASE
    li      t2, FINISH_PASS
    sw      t2, 0(t1)

hang:
    j       hang                    # unreachable, but never fall off the end

    .section .rodata
msg:
    .string "Hello, RISC-V\n"       # .string appends the terminating 0 byte
