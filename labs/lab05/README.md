# Lab 05 — C ↔ Assembly Bridge *(optional)*

## Objective

See what a C compiler actually produces. Call C functions from assembly, then
read the assembly the compiler generated for those same functions and match it
against what you would have written by hand.

Maps to **Patterson & Hennessy, *Computer Organization and Design* (RISC-V,
2nd ed.), sections 2.8 and 2.12** — supporting procedures, and translating and
starting a program.

This lab is optional and comes last on purpose. Everything in it makes more
sense once you have written procedures by hand.

## Background

There is nothing special about compiled code. `gcc` emits RISC-V assembly,
that assembly goes through the same assembler and linker you have been using,
and the result honours the same calling convention you followed by hand. That
is why `bridge.s` can `call add_two` without knowing or caring that `add_two`
came from C.

Two commands matter here:

```sh
make cbuild      # compile compute.c to compute.s and stop -- read it
make dump        # disassemble the finished program
```

`make cbuild` is the interesting one. It stops after the compiler and before
the assembler, so `compute.s` is the compiler's own output, comments and all.

## Instructions

1. `make` and `make run`. Part 1 calls a C function from assembly.
2. Complete **TODO 1** — call `sum_to`, `fact` and `scale`.
3. Complete **TODO 2** — call `largest`, passing a pointer.
4. Run `make cbuild` and open `compute.s`. For each function, find:
   - `add_two` — count the instructions. It is doing one addition.
   - `sum_to` — the backward branch that forms the loop
   - `fact` — the prologue: which registers get saved, and where
   - `largest` — how the array pointer advances
   - `scale` — there is no `mul` and no `div`. Find out what it did instead.
5. Now rebuild at a higher optimisation level and compare the same functions:

   ```sh
   make clean && make cbuild COPT=-O2
   ```

   This is the interesting half of the lab. Do not skip it.

## Checkpoints

- Part 1 prints `42`.
- TODO 1 prints `5050`, `3628800`, `18`.
- TODO 2 prints `91`.
- At `-O0`, **every** function has a stack frame — including `add_two`, which
  calls nothing and needs none. The compiler is not being clever at `-O0`; it
  gives each function the same uniform treatment and spills every variable to
  memory. `add_two` takes around ten instructions to add two numbers.
- At `-O2`, `add_two` collapses to **two** instructions: `add a0, a0, a1` and
  `ret`. No frame, no spills. *That* is the leaf versus non-leaf distinction
  you implemented by hand, and it only becomes visible once the compiler is
  allowed to optimise. Compare `fact` at `-O2` — it still needs a frame,
  because it still calls something.
- `scale` computes `(x * 8) / 4` using **shifts** at both levels — no `mul`,
  no `div`. At `-O2` it is a single `slli a0, a0, 1`: the compiler worked out
  that multiplying by 8 and dividing by 4 is multiplying by 2. Work out why
  that is valid, and when it would stop being valid.
- At `-O2`, `sum_to` may not contain a loop at all. If so, explain what the
  compiler did instead.

## Deliverables

- `bridge.s` with both TODOs completed
- Terminal output of `make run`
- The `compute.s` produced at `-O0`
- A short handwritten comparison of **one** function: the compiler's version
  against how you would have written it. Where it differs, say whether the
  compiler is doing something smarter or just something different.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `undefined reference to add_two` | `compute.o` did not build. Run `make clean && make`. |
| Wrong values from `largest` | You passed the value instead of the address. Use `la`, not `ld`. |
| `compute.s` is unreadable at `-O2` | Expected. Read the `-O0` version first. |
| `add_two` has a stack frame at `-O0` | Expected — the compiler frames everything at `-O0`. Rebuild at `-O2`. |
| `fact` result wrong above 20 | 64-bit overflow, not a compiler bug. |

General problems — toolchain, QEMU, GDB — are in `docs/troubleshooting.md`.
