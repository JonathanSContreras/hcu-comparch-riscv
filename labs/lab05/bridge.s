# lab05/bridge.s — the assembly half of the C bridge lab.
#
# Patterson & Hennessy, Computer Organization and Design (RISC-V, 2nd ed.),
# sections 2.8 and 2.12 (procedures; translating and starting a program).
#
# This file calls the C functions in compute.c. Same calling convention, same
# registers, same stack -- the compiler is playing by exactly the rules you
# followed by hand in the procedures lab.
#
# Build:  make          Run:  make run
# See the compiler's assembly:  make cbuild   then open compute.s
# Quit QEMU:  Ctrl-A  then  X

    .section .text.init
    .globl _start

    .equ TEST_BASE,   0x00100000
    .equ FINISH_PASS, 0x5555

# Declared in compute.c, compiled separately, linked together.
    .extern add_two, sum_to, fact, largest, scale

_start:
    lla     sp, _stack_top

# ---------------------------------------------------------------- part 1
# Worked example: call a C function from assembly.
#
# Arguments go in a0 and a1, the result comes back in a0. You are not doing
# anything special here -- this is the same `call` you have been using all
# along, and the C compiler emitted a procedure that honours the same ABI.

    lla     a0, msg_add
    call    puts
    li      a0, 30
    li      a1, 12
    call    add_two                 # C: add_two(30, 12)
    call    print_int
    call    newline

# ---------------------------------------------------------------- part 2
# TODO 1 -- call the rest of them.
#
# Call sum_to(100), fact(10), and scale(9) and print each result.
# Expected: 5050, 3628800, 18

    lla     a0, msg_rest
    call    puts
    # --- your code here ---

    call    newline

# ---------------------------------------------------------------- part 3
# TODO 2 -- pass a pointer.
#
# Call largest(values, values_len) and print the result. Expected: 91
#
# The first argument is an ADDRESS, so use `la` rather than `ld`. C's
# `const long *values` is nothing more exotic than a register holding an
# address -- exactly what you were doing by hand in the array labs.

    lla     a0, msg_largest
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
msg_add:     .string "part 1  add_two(30, 12) = "
msg_rest:    .string "todo 1  sum_to, fact, scale: "
msg_largest: .string "todo 2  largest(values) = "

    .section .data
    .align 3
values:     .dword 13, 4, 27, 60, 91, 8, 45, 22
values_len: .dword 8
