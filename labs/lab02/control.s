# lab02/control.s — branches, loops, and what the program counter is doing.
#
# Patterson & Hennessy, Computer Organization and Design (RISC-V, 2nd ed.),
# section 2.7 (instructions for making decisions).
#
# Build:  make          Run:  make run          Disassemble:  make dump
# Quit QEMU:  Ctrl-A  then  X
#
# From common/uart.s:  puts, print_int, newline

    .section .text.init
    .globl _start

    .equ TEST_BASE,   0x00100000
    .equ FINISH_PASS, 0x5555

_start:
    lla     sp, _stack_top

# ---------------------------------------------------------------- part 1
# Worked example: count from 1 to 5.
#
# There is no `for` and no `while`. A loop is a label, a comparison, and a
# jump backwards. That is all a loop has ever been -- the syntax in a
# high-level language is doing exactly this underneath.
#
# `1:` and `2:` are LOCAL labels. `1b` means "branch back to the nearest 1",
# `2f` means "forward to the nearest 2". They let you write loops without
# inventing a unique name for every one.

    lla     a0, msg_count
    call    puts

    li      s0, 1                   # s0 = counter (s registers survive calls)
    li      s1, 5                   # s1 = limit
1:  bgt     s0, s1, 2f              # if counter > limit, leave the loop
    mv      a0, s0
    call    print_int
    li      a0, 32                  # ASCII space
    call    putc
    addi    s0, s0, 1               # counter++
    j       1b                      # unconditional jump backwards
2:  call    newline

# ---------------------------------------------------------------- part 2
# TODO 1 -- sum the integers from 1 to 100.
#
# Expected: 5050
#
# Branch instructions you have:
#     beq  rs1, rs2, label     equal
#     bne  rs1, rs2, label     not equal
#     blt  rs1, rs2, label     less than          (signed)
#     bge  rs1, rs2, label     greater or equal   (signed)
#     bltu / bgeu              the unsigned versions
#
# `bgt` and `ble` also exist, as pseudo-instructions -- the assembler just
# swaps the operands and uses blt/bge. Check that in `make dump`.

    lla     a0, msg_sum
    call    puts
    # --- your code here ---

    call    newline

# ---------------------------------------------------------------- part 3
# TODO 2 -- find the largest value in an array.
#
# `numbers` below holds 8 doublewords, and `numbers_len` holds the count.
# Walk the array and print the largest value. Expected: 91
#
# Stepping through an array of 8-byte values means adding 8 to the address
# each time, not 1. Getting this wrong is the single most common mistake in
# this lab, and the symptom is a nonsense number rather than a crash.
#
#     la  t0, numbers      t0 = address of element 0
#     ld  t1, 0(t0)        t1 = element 0
#     addi t0, t0, 8       t0 now points at element 1

    lla     a0, msg_max
    call    puts
    # --- your code here ---

    call    newline

# ---------------------------------------------------------------- part 4
# TODO 3 -- classify each value in the array.
#
# For every element, print one character and no newline until the end:
#     'e' if it is even
#     'o' if it is odd
#
# Expected: oeoeoeoe  ... work it out from the data rather than trusting that.
#
# Testing the low bit is enough to know whether a number is even:
#     andi t2, t1, 1       t2 = 0 when even, 1 when odd
#
# Useful: putc takes an ASCII value in a0. 'e' is 101, 'o' is 111.

    lla     a0, msg_parity
    call    puts
    # --- your code here ---

    call    newline

# ---------------------------------------------------------------- done
    li      t0, TEST_BASE
    li      t1, FINISH_PASS
    sw      t1, 0(t0)
hang:
    j       hang

# ---------------------------------------------------------------- data
    .section .rodata
msg_count:  .string "part 1  counting: "
msg_sum:    .string "todo 1  sum 1..100 = "
msg_max:    .string "todo 2  largest value = "
msg_parity: .string "todo 3  parity: "

    .section .data
    .align 3
numbers:     .dword 13, 4, 27, 60, 91, 8, 45, 22
numbers_len: .dword 8
