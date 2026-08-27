# Lab 03 — Memory and the Stack

## Objective

Work with memory directly: walk an array, rearrange it in place, and use the
stack as scratch space. By the end you should be able to explain what `sp`
points at, which direction it moves, and what breaks when it is left wrong.

Maps to **Patterson & Hennessy, *Computer Organization and Design* (RISC-V,
2nd ed.), sections 2.6 and 2.8** — memory operands, and supporting procedures
in computer hardware.

## Background

The stack is not a feature of the processor. There is no push instruction and
no pop instruction. There is a register, `sp`, that everyone has agreed points
at the top of a region of memory, and two ordinary instructions:

```
    addi  sp, sp, -8        # "push": move sp down, making room
    sd    t0, 0(sp)         #         store into the room you just made

    ld    t0, 0(sp)         # "pop":  read it back
    addi  sp, sp, 8         #         release the space
```

The stack grows **downwards** — towards lower addresses. Pushing makes `sp`
smaller. This is convention, not physics, but every RISC-V toolchain and every
piece of code you will link against assumes it.

In this program nothing sets up the stack for you. `la sp, _stack_top` at the
top of `_start` is the whole of it, and `_stack_top` is a symbol defined by
`common/link.ld`. Open that file and find where the 16 KB comes from.

Two rules that matter more than they look:

1. **Keep `sp` 16-byte aligned** at function boundaries. Adjust in multiples
   of 16 even when you only need 8.
2. **Whatever you push, you must pop.** If `sp` is wrong when you return, the
   `ret` reads a return address from the wrong place. The program does not
   crash where the bug is — it crashes somewhere unrelated, later.

## Instructions

1. `make` and `make run`. Part 1 is a worked example showing `sp` move.
2. Complete **TODO 1** — reverse the array in place.
3. Complete **TODO 2** — print it reversed using the stack, leaving memory
   untouched.
4. Complete **TODO 3** — check `sp` is back where it started.
5. Then deliberately break it: delete one `addi sp, sp, 8` and run again.
   Record what happened.

## Checkpoints

- Part 1: the second `sp` value is exactly **8 less** than the first, and the
  value read back is `12345`.
- TODO 1 prints `60 50 40 30 20 10`.
- TODO 2 prints `10 20 30 40 50 60` — the **original** order, not the reversed
  one. That is correct, and it is the most useful thing in this lab. TODO 1
  reversed the array *in memory*, so TODO 2 reads an already-reversed array and
  prints it in reverse, which puts it back. Reversing data and printing in
  reverse order are different operations, and here they cancel out. Predict
  this before you run it; if it surprises you, work out why until it does not.
- TODO 3 prints `balanced`.
- After you break it on purpose: it does **not** print `LEAKED` and stop
  politely. Note what it actually does.

## Deliverables

- `memory.s` with all three TODOs completed
- Terminal output of `make run`
- A short handwritten explanation of what happened when you removed the
  `addi sp, sp, 8`, and why the failure appeared where it did rather than at
  the line you changed

## Troubleshooting

| Symptom | Cause |
|---|---|
| Jumps somewhere random after a `call` | Unbalanced stack — `ra` was restored from the wrong address. |
| `Bus error` / silent hang on `ld` | Address not 8-byte aligned. Keep `.align 3` and move pointers in steps of 8. |
| Reversal produces the original array | Your two pointers crossed and swapped everything back. Stop when they meet. |
| Values correct but order wrong by one | The last element is at `base + (count-1)*8`, not `base + count*8`. |

General problems — toolchain, QEMU, GDB — are in `docs/troubleshooting.md`.
