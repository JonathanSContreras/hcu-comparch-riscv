# uart.s — shared console helpers for the COSC 3341 RISC-V labs.
#
# There is no operating system here. No printf, no libc, nothing. Printing a
# character means storing one byte to a device register at a fixed address --
# memory-mapped I/O, exactly as described in Patterson & Hennessy chapter 2.
#
# Your lab links against this file so you do not rewrite the same print loop
# five times. Read it once; it is about forty instructions and there is no
# magic in any of them.
#
# Provided:
#     putc      a0 = character              print one character
#     puts      a0 = pointer to NUL string  print a string
#     print_int a0 = signed 64-bit integer  print it in decimal
#     newline   (no arguments)              print '\n'
#
# Register conventions used below (P&H 2.8, and the subject of Lab 4):
#     a0-a7   arguments and return values
#     t0-t6   temporaries -- a called function may destroy these
#     ra      return address, set by `call`, used by `ret`

    .section .text
    .globl putc, puts, print_int, newline

    .equ UART_BASE, 0x10000000      # NS16550A transmit-holding register
    .equ UART_LSR,  0x10000005      # line status register
    .equ LSR_TX_IDLE, 0x20          # bit 5: transmitter ready for a byte

# ASCII values, written out rather than as 'x' character literals. The UART
# takes a byte; a character IS a number, and in this course that is the point.
    .equ CH_NEWLINE, 10
    .equ CH_MINUS,   45
    .equ CH_ZERO,    48

# ---------------------------------------------------------------- putc
# Print the single character in a0.
#
# The LSR poll below is what real hardware requires: you may not hand the UART
# a byte until it says it has finished sending the previous one. QEMU is more
# forgiving and would work without it -- which is exactly why it is here. Code
# that only works on the emulator is not what this course is teaching.
putc:
    li      t0, UART_LSR
1:  lbu     t1, 0(t0)               # read the status register
    andi    t1, t1, LSR_TX_IDLE     # isolate bit 5
    beqz    t1, 1b                  # still busy -> read it again
    li      t0, UART_BASE
    sb      a0, 0(t0)               # <-- the actual output
    ret

# ---------------------------------------------------------------- puts
# Print the NUL-terminated string pointed to by a0.
puts:
    addi    sp, sp, -16             # make room on the stack
    sd      ra, 8(sp)               # save our return address: `call` below
    sd      s0, 0(sp)               # would otherwise overwrite it
    mv      s0, a0                  # s0 survives calls, a0 does not
1:  lbu     a0, 0(s0)
    beqz    a0, 2f                  # 0 byte marks the end
    call    putc
    addi    s0, s0, 1
    j       1b
2:  ld      ra, 8(sp)
    ld      s0, 0(sp)
    addi    sp, sp, 16
    ret

# ------------------------------------------------------------- newline
newline:
    li      a0, CH_NEWLINE
    tail    putc                    # tail call: jump to putc, let IT return

# ----------------------------------------------------------- print_int
# Print the signed 64-bit value in a0 in decimal.
#
# Digits come out of the division loop backwards, so they are pushed onto the
# stack and popped off in reverse. That is a real use of the stack for scratch
# space, which Lab 3 covers directly.
print_int:
    addi    sp, sp, -48
    sd      ra, 40(sp)
    sd      s0, 32(sp)
    sd      s1, 24(sp)

    mv      s0, a0
    li      s1, 0                   # s1 = how many digits we pushed

    bnez    s0, 1f                  # zero needs special handling: the loop
    li      a0, CH_ZERO             # below would emit nothing at all
    call    putc
    j       9f

1:  bgez    s0, 2f                  # non-negative -> skip the sign
    li      a0, CH_MINUS
    call    putc
    neg     s0, s0                  # note: this is wrong for the most
                                    # negative value, which has no positive
                                    # counterpart in two's complement
2:  li      t0, 10
3:  remu    t1, s0, t0              # t1 = s0 % 10
    addi    t1, t1, CH_ZERO         # digit value -> ASCII character
    addi    sp, sp, -8
    sd      t1, 0(sp)               # push it
    addi    s1, s1, 1
    divu    s0, s0, t0              # s0 = s0 / 10
    bnez    s0, 3b

4:  ld      a0, 0(sp)               # pop and print, which reverses them
    addi    sp, sp, 8
    call    putc
    addi    s1, s1, -1
    bnez    s1, 4b

9:  ld      ra, 40(sp)
    ld      s0, 32(sp)
    ld      s1, 24(sp)
    addi    sp, sp, 48
    ret
