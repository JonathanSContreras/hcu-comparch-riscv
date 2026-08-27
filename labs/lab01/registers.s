# lab01/registers.s — ISA basics: registers, arithmetic, load and store.
#
# Patterson & Hennessy, Computer Organization and Design (RISC-V, 2nd ed.),
# sections 2.2 - 2.6.
#
# Build:  make          Run:  make run          Disassemble:  make dump
# Quit QEMU:  Ctrl-A  then  X
#
# You will not write a print routine. common/uart.s gives you:
#     puts       a0 = address of a NUL-terminated string
#     print_int  a0 = a signed 64-bit number
#     newline    prints '\n'
# Read that file when you are curious how printing actually works.

    .section .text.init
    .globl _start

    .equ TEST_BASE,   0x00100000    # SiFive test finisher: powers QEMU off
    .equ FINISH_PASS, 0x5555

_start:
    lla     sp, _stack_top          # uart.s calls functions, so we need a
                                    # stack. link.ld defines _stack_top.

# ---------------------------------------------------------------- part 1
# Worked example. Read it, run it, then move to part 2.
#
# li  = "load immediate"       put a constant into a register
# add = register + register
# addi = register + a constant folded into the instruction itself
#
# Notice in `make dump` that `li` is a PSEUDO-INSTRUCTION: the assembler
# turns it into a real instruction (usually `addi x, zero, n`). RISC-V has
# no "load a constant" instruction, because it does not need one.

    lla     a0, msg_sum
    call    puts

    li      t0, 17                  # t0 = 17
    li      t1, 25                  # t1 = 25
    add     t2, t0, t1              # t2 = t0 + t1   -> 42

    mv      a0, t2
    call    print_int
    call    newline

# ---------------------------------------------------------------- part 2
# TODO 1 -- subtraction and immediates.
#
# Compute (100 - 58) + 7 using `sub` and `addi`, leaving the result in t3,
# then print it. Expected: 49
#
# Useful:  sub  rd, rs1, rs2      rd = rs1 - rs2
#          addi rd, rs1, imm      rd = rs1 + imm   (imm fits in 12 bits)

    lla     a0, msg_todo1
    call    puts
    # --- your code here ---

    call    newline

# ---------------------------------------------------------------- part 3
# TODO 2 -- logical operations and shifts.
#
# Starting from the value in `value` below, print:
#     a) the value AND 0xFF        (its lowest 8 bits)
#     b) the value shifted right by 4    (slli / srli shift left / right)
#
# Useful:  andi rd, rs1, imm
#          srli rd, rs1, shamt     shift right, filling with zeros
#          slli rd, rs1, shamt     shift left
#
# Think about what shifting right by 4 does to a number in decimal terms
# before you run it. You should be able to predict the output.

    lla     a0, msg_todo2
    call    puts
    # --- your code here ---

    call    newline

# ---------------------------------------------------------------- part 4
# TODO 3 -- load and store.
#
# `value` lives in memory, not in a register. To use it you must LOAD it.
#
#     la  t0, value       t0 = the ADDRESS of value
#     ld  t1, 0(t0)       t1 = the 8 bytes AT that address
#
# Load `value`, add 1000 to it, store the result back into `result`, then
# load `result` and print it. Storing and re-loading is pointless work here
# and is done on purpose: it is the load/store cycle the whole ISA is built
# around, and you should see it happen at least once explicitly.
#
# Useful:  ld  rd, offset(rs)      load 8 bytes  (RV64 doubleword)
#          sd  rs2, offset(rs1)    store 8 bytes

    lla     a0, msg_todo3
    call    puts
    # --- your code here ---

    call    newline

# ---------------------------------------------------------------- done
    li      t0, TEST_BASE
    li      t1, FINISH_PASS
    sw      t1, 0(t0)               # power off so `make run` returns
hang:
    j       hang

# ---------------------------------------------------------------- data
    .section .rodata
msg_sum:    .string "part 1  17 + 25 = "
msg_todo1:  .string "todo 1  (100 - 58) + 7 = "
msg_todo2:  .string "todo 2  low byte and shifted: "
msg_todo3:  .string "todo 3  value + 1000 via memory = "

    .section .data
    .align 3                        # 8-byte alignment, required for ld/sd
value:      .dword 74565            # 0x00012345
result:     .dword 0
