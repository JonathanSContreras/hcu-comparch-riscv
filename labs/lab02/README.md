# Lab 02 — Branching and Control Flow

## Objective

Build loops and conditionals out of the only tools the hardware provides: a
comparison and a jump. By the end you should be able to look at a `while` loop
in any language and describe the branch instructions underneath it.

Maps to **Patterson & Hennessy, *Computer Organization and Design* (RISC-V,
2nd ed.), section 2.7** — instructions for making decisions.

## Background

The processor keeps a **program counter**: the address of the instruction it is
about to run. Normally it advances by the size of one instruction and continues.
A branch instruction changes it conditionally; a jump changes it unconditionally.
Everything else — `if`, `while`, `for`, `switch` — is built from those two.

RISC-V compares and branches in a single instruction:

```
    blt   t0, t1, somewhere      # if t0 < t1, jump to somewhere
```

There is no separate compare instruction and no flags register to check
afterwards. If you have written x86 or ARM assembly, that difference is worth
sitting with.

Two things that look like real instructions but are not:

- `bgt a, b, L` assembles as `blt b, a, L` — same instruction, operands swapped.
- `j L` assembles as `jal zero, L` — jump and link, discarding the link into
  `x0`, which can never be written.

`make dump` shows you what actually got assembled.

## Instructions

1. `make` and then `make run`. Part 1 counts to 5 and is a worked example.
2. Complete **TODO 1** (sum 1 to 100), then build and run.
3. Complete **TODO 2** (largest element in an array).
4. Complete **TODO 3** (print parity of each element).
5. `make dump` and locate the backward branch that forms your loop in TODO 1.

## Checkpoints

- Part 1 prints `1 2 3 4 5`.
- TODO 1 prints `5050`. If it prints `5150` or `4950`, your loop runs one
  iteration too many or too few — an off-by-one in the branch condition.
- TODO 2 prints `91`.
- TODO 3 prints eight characters. Work out what they should be from the data
  before you run it; the point is that you can predict it.
- In `make dump`, your loop's closing branch jumps to a **lower** address than
  the instruction it sits at. That backward jump is the loop.

## Deliverables

- `control.s` with all three TODOs completed
- Terminal output of `make run`
- A short handwritten explanation of **TODO 2**: which register held the
  running maximum, which held the array address, and how you knew when to stop

## Troubleshooting

| Symptom | Cause |
|---|---|
| QEMU hangs and never returns | Infinite loop — your exit condition is never true. Quit with `Ctrl-A` then `X` and check the branch direction. |
| Array walk prints nonsense | You advanced the pointer by 1 instead of 8. Each doubleword is 8 bytes. |
| Off by one in a count | `blt` versus `ble` — decide whether the limit itself should be included. |
| Values look correct but negative | `bltu`/`bgeu` are unsigned. With signed data use `blt`/`bge`. |

General problems — toolchain, QEMU, GDB — are in `docs/troubleshooting.md`.
