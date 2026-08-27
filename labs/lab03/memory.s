# lab03/memory.s — memory layout, the stack, and why sp moves.
#
# Patterson & Hennessy, Computer Organization and Design (RISC-V, 2nd ed.),
# sections 2.6 and 2.8 (memory operands; supporting procedures).
#
# Build:  make          Run:  make run          Disassemble:  make dump
# Quit QEMU:  Ctrl-A  then  X
#
# From common/uart.s:  puts, print_int, newline, putc

    .section .text.init
    .globl _start

    .equ TEST_BASE,   0x00100000
    .equ FINISH_PASS, 0x5555

_start:
    lla     sp, _stack_top          # the stack starts at the TOP of the
                                    # region link.ld reserved, and grows DOWN

# ---------------------------------------------------------------- part 1
# Worked example: where does the stack actually live?
#
# Nothing initialises sp for you. There is no operating system to do it. The
# `la sp, _stack_top` above is the entire "stack setup" for this program, and
# _stack_top is a symbol the linker script defines.
#
# Print sp, push a value, print sp again. The address gets SMALLER.

    lla     a0, msg_sp1
    call    puts
    mv      a0, sp
    call    print_int
    call    newline

    addi    sp, sp, -8              # make room for one doubleword
    li      t0, 12345
    sd      t0, 0(sp)               # store it there

    lla     a0, msg_sp2
    call    puts
    mv      a0, sp
    call    print_int
    call    newline

    lla     a0, msg_popped
    call    puts
    ld      t0, 0(sp)               # read it back
    addi    sp, sp, 8               # release the space
    mv      a0, t0
    call    print_int
    call    newline
    # Note the ordering above. The `ld` deliberately comes AFTER `call puts`.
    # t0 is caller-saved, so puts is entitled to destroy it -- and it does.
    # Loading first and printing second would print whatever puts happened to
    # leave behind. If that sounds like a detail, it is the same detail that
    # ends up costing you an afternoon later in the course.

# ---------------------------------------------------------------- part 2
# TODO 1 -- reverse an array in place.
#
# `data` holds 6 doublewords. Reverse the order of the elements in memory,
# then print them. Expected after reversing: 60 50 40 30 20 10
#
# Use two pointers: one at the first element, one at the last. Swap what they
# point at, move them towards each other, stop when they meet or cross.
#
# The last element is at:  address_of_data + (count - 1) * 8

    lla     a0, msg_rev
    call    puts
    # --- your code here ---

    call    newline

# ---------------------------------------------------------------- part 3
# TODO 2 -- use the stack as scratch space.
#
# Print the elements of `data` in reverse WITHOUT modifying memory:
#   1. walk the array forwards, pushing each element onto the stack
#   2. walk back, popping and printing
#
# This is the same trick print_int uses to emit decimal digits, which come
# out of the division loop backwards. Read that routine in common/uart.s if
# you want to see it working.
#
# Whatever you push, you must pop. If sp is not back where it started when
# you are done, the next `call` will return to the wrong place -- and the
# failure will look nothing like a stack problem.

    lla     a0, msg_stack
    call    puts
    # --- your code here ---

    call    newline

# ---------------------------------------------------------------- part 4
# TODO 3 -- prove you balanced the stack.
#
# Save the value of sp into s2 at the very start of TODO 2, and compare it to
# sp here. Print "balanced" if they match and "LEAKED" if they do not.
#
# Deliberately break it afterwards: remove one `addi sp, sp, 8` and watch
# what happens. Write down what you observe -- it is part of the deliverable.

    lla     a0, msg_check
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
msg_sp1:    .string "part 1  sp before push = "
msg_sp2:    .string "part 1  sp after push  = "
msg_popped: .string "part 1  value read back = "
msg_rev:    .string "todo 1  reversed in memory: "
msg_stack:  .string "todo 2  reversed via stack: "
msg_check:  .string "todo 3  stack is "
str_ok:     .string "balanced"
str_bad:    .string "LEAKED"

    .section .data
    .align 3
data:     .dword 10, 20, 30, 40, 50, 60
data_len: .dword 6
