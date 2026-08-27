# Lab 01 — ISA Basics: Registers, Arithmetic, Load and Store

## Objective

Write RISC-V assembly that manipulates values in registers and moves them
between registers and memory. By the end you should be able to read a short
assembly program and say what is in every register at every step.

Maps to **Patterson & Hennessy, *Computer Organization and Design* (RISC-V,
2nd ed.), sections 2.2–2.6** — operations of the computer hardware, operands,
signed and unsigned numbers, and representing instructions.

## Background

A RISC-V processor has 32 general-purpose registers. Arithmetic happens
**only** between registers — there is no instruction that adds two numbers in
memory. To work with a value in memory you load it into a register, operate on
it, and store it back. That constraint is the defining feature of a
load/store architecture, and it is why this lab spends time on `ld` and `sd`.

Registers have both a number and a conventional name. `x5` and `t0` are the
same register; the names describe how the calling convention expects them to
be used. `make dump` prints the numbers, which is a useful reality check.

Two instruction forms appear constantly:

| Form | Example | Meaning |
|---|---|---|
| register–register | `add t2, t0, t1` | `t2 = t0 + t1` |
| register–immediate | `addi t2, t0, 25` | `t2 = t0 + 25`, constant baked into the instruction |

The immediate is 12 bits, signed — roughly −2048 to +2047. Larger constants
need more than one instruction, which is what `li` quietly does for you.

## Instructions

1. `cd` into this directory and run `make` to confirm it builds.
2. Run `make run`. Part 1 is a worked example and should print `42`.
3. Open `registers.s` and complete **TODO 1**, **TODO 2**, and **TODO 3** in
   order. Build and run after each one rather than writing all three first.
4. Run `make dump` and find the instructions the assembler generated for your
   code.

## Checkpoints

- After step 2: you see `part 1  17 + 25 = 42`.
- After TODO 1: `todo 1  (100 - 58) + 7 = 49`.
- After TODO 2: the low byte of `0x00012345` is `0x45`, which is **69** in
  decimal, and shifting right by 4 gives **4660**. Predict both before running.
- After TODO 3: `todo 3  value + 1000 via memory = 75565`.
- In `make dump`: find your `la` instruction and confirm it became **two**
  instructions (`auipc` then `addi`). RISC-V has no single instruction that
  loads a 64-bit address.

## Deliverables

- `registers.s` with all three TODOs completed
- Terminal output of `make run`
- A short handwritten trace of **TODO 3**: for each instruction you wrote, the
  register or memory location it changed and its value afterwards

## Troubleshooting

| Symptom | Cause |
|---|---|
| `Error: illegal operands` on `addi` | Your immediate is larger than 12 bits. Use `li` into a register first, then `add`. |
| Prints a huge or negative number | You loaded with `lw` (4 bytes, sign-extended) instead of `ld` (8 bytes). |
| Hangs instead of exiting | Execution never reached the power-off block. Check you did not add a branch that skips it. |
| `Bus error` or nothing prints | `ld`/`sd` need 8-byte-aligned addresses. Keep the `.align 3` in the data section. |

General problems — toolchain, QEMU, GDB — are in `docs/troubleshooting.md`.
