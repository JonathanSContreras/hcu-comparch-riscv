# Lab 04 — Procedures and Calling Conventions

## Objective

Write procedures that call other procedures, including one that calls itself.
By the end you should be able to look at any function's first four instructions
and say what it is about to do to the stack, and why.

Maps to **Patterson & Hennessy, *Computer Organization and Design* (RISC-V,
2nd ed.), section 2.8** — supporting procedures in computer hardware.

## Background

`call` is a pseudo-instruction for `jal ra, target`: jump to the target and
record the address of the following instruction in `ra`. `ret` is `jalr zero,
0(ra)`: jump back to whatever `ra` holds.

Which means: **`ra` holds exactly one return address.** If a procedure calls
anything at all, the nested `call` overwrites `ra` and the outer procedure has
lost its way home. Saving `ra` on the stack is not bookkeeping — it is the
mechanism that makes nesting possible.

That gives two shapes of procedure:

| | Leaf | Non-leaf |
|---|---|---|
| Calls anything? | No | Yes |
| Needs a stack frame? | No | Yes |
| Must save `ra`? | No | Yes |

The rest is the **application binary interface** — a convention about who is
responsible for which registers:

- **Caller-saved** (`t0`–`t6`, `a0`–`a7`): a procedure you call is free to
  destroy these. If you need one afterwards, save it before you call.
- **Callee-saved** (`s0`–`s11`): a procedure you call must return these
  unchanged. If you want to use one, you save and restore it yourself.

None of this is enforced by hardware. It is enforced by everyone following it,
which is why your code can call `print_int` at all.

## Instructions

1. `make` and `make run`. Part 1 is a worked leaf procedure.
2. Complete **TODO 1** — `sum_to`, a leaf procedure.
3. Complete **TODO 2** — `fact`, recursive. Use the frame pattern in the
   comments.
4. Complete **TODO 3** — predict, then demonstrate, which registers survive a
   call.
5. `make dump` and compare the first instructions of `square` and `fact`.

## Checkpoints

- Part 1 prints `144`.
- TODO 1 prints `5050`.
- TODO 2 prints `3628800`. Then try `fact(25)` — the answer is wrong, and it is
  wrong for a reason that has nothing to do with your code. Work out what.
- TODO 3: one register keeps its value across the call and one does not.
  You should have predicted which before running it.
- In `make dump`: `square` has no `addi sp, sp, -N` at all. `fact` does. That
  difference is the whole lab.

## Deliverables

- `procedures.s` with all three TODOs completed
- Terminal output of `make run`
- A short handwritten stack diagram for `fact(3)`: draw each frame as it is
  pushed, show what `ra` and your saved `n` contain in each, and show the
  frames unwinding
- One sentence explaining the `fact(25)` result

## Troubleshooting

| Symptom | Cause |
|---|---|
| Returns to a strange place, or hangs | `ra` was overwritten by a nested `call` and not restored. |
| Recursion never terminates | Base case is missing or unreachable — `fact(0)` and `fact(1)` must both return 1 without recursing. |
| Correct for small `n`, wrong for large | 64-bit overflow, not a logic error. `20!` is the largest that fits. |
| A value changes across a call for no reason | You kept it in `t0`–`t6`. Those are caller-saved. |

General problems — toolchain, QEMU, GDB — are in `docs/troubleshooting.md`.
