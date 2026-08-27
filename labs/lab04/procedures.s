# lab04/procedures.s — procedures, the ABI, and recursion.
#
# Patterson & Hennessy, Computer Organization and Design (RISC-V, 2nd ed.),
# section 2.8 (supporting procedures in computer hardware).
#
# Build:  make          Run:  make run          Disassemble:  make dump
# Quit QEMU:  Ctrl-A  then  X
#
# From common/uart.s:  puts, print_int, newline, putc

    .section .text.init
    .globl _start

    .equ TEST_BASE,   0x00100000
    .equ FINISH_PASS, 0x5555

# The RISC-V calling convention. Nothing in the hardware enforces any of this.
# It is an agreement, and it is the only reason your code can call a routine
# written by someone else -- including everything in common/uart.s.
#
#   a0-a7    arguments in, results out (a0 and a1)
#   ra       return address. `call` writes it, `ret` jumps to it.
#   t0-t6    CALLER-saved: a function you call may destroy these.
#            If you need one to survive a call, save it yourself.
#   s0-s11   CALLEE-saved: a function you call must give them back unchanged.
#            If YOU use one, you must save and restore it.
#   sp       stack pointer, 16-byte aligned at every call boundary

_start:
    la      sp, _stack_top

# ---------------------------------------------------------------- part 1
# Worked example: a leaf procedure.
#
# `square` calls nothing, so it never needs the stack and never touches ra.
# That is what makes it a "leaf". Compare its prologue to `fact` below.

    la      a0, msg_square
    call    puts
    li      a0, 12
    call    square                  # a0 = 12 -> returns 144 in a0
    call    print_int
    call    newline

# ---------------------------------------------------------------- part 2
# TODO 1 -- write `sum_to`.
#
#   input:  a0 = n
#   output: a0 = 1 + 2 + ... + n
#
# Write it as a proper procedure ending in `ret`, called with `call sum_to`.
# It calls nothing, so like `square` it needs no stack frame at all.
#
# Expected for n = 100: 5050

    la      a0, msg_sumto
    call    puts
    li      a0, 100
    call    sum_to
    call    print_int
    call    newline

# ---------------------------------------------------------------- part 3
# TODO 2 -- write `fact`, recursively.
#
#   input:  a0 = n
#   output: a0 = n!
#
# This one calls itself, so it is NOT a leaf. Before the recursive call you
# must save anything you need afterwards -- at minimum `ra`, because the
# nested `call` will overwrite it, and your own `n`.
#
# The frame pattern, which is worth memorising:
#
#     addi  sp, sp, -16
#     sd    ra, 8(sp)          # save return address
#     sd    s0, 0(sp)          # save any callee-saved register you use
#     ...                      # body, including recursive calls
#     ld    ra, 8(sp)
#     ld    s0, 0(sp)
#     addi  sp, sp, 16
#     ret
#
# Expected for n = 10: 3628800
#
# Try it with n = 25 afterwards and explain the result. It is not a bug in
# your code.

    la      a0, msg_fact
    call    puts
    li      a0, 10
    call    fact
    call    print_int
    call    newline

# ---------------------------------------------------------------- part 4
# TODO 3 -- demonstrate the caller/callee-saved split.
#
# Put a value in t0 and a value in s0. Print both. Call `clobber` below.
# Print both again.
#
# One of them survives and one does not. Predict which BEFORE running it,
# then read `clobber` and confirm you were right. That difference is the
# entire content of the calling convention.

    la      a0, msg_clobber
    call    puts
    # --- your code here ---

    call    newline

# ---------------------------------------------------------------- done
    li      t0, TEST_BASE
    li      t1, FINISH_PASS
    sw      t1, 0(t0)
hang:
    j       hang

# ================================================================ procedures

# square: a0 = a0 * a0. Leaf -- no stack, no ra to save.
square:
    mul     a0, a0, a0
    ret

# TODO 1 -- replace this stub with a real implementation.
# It returns -1 so the program builds and runs before you have written it.
# When your checkpoint says 5050 and you see -1, this is why.
sum_to:
    li      a0, -1
    ret

# TODO 2 -- replace this stub with a real implementation.
fact:
    li      a0, -1
    ret


# clobber: deliberately writes to a caller-saved and a callee-saved register,
# and restores only the one the convention says it must. Read it after you
# have made your prediction in TODO 3.
clobber:
    addi    sp, sp, -16
    sd      s0, 0(sp)               # s0 is callee-saved: we borrow it, so
                                    # we are obliged to hand it back
    li      t0, 999                 # t0 is caller-saved: not our problem
    li      s0, 999
    ld      s0, 0(sp)               # ... and here we hand it back
    addi    sp, sp, 16
    ret

# ---------------------------------------------------------------- data
    .section .rodata
msg_square:  .string "part 1  square(12) = "
msg_sumto:   .string "todo 1  sum_to(100) = "
msg_fact:    .string "todo 2  fact(10) = "
msg_clobber: .string "todo 3  t0 and s0 across a call: "
