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
   - `add_two` — how few instructions is it really?
   - `sum_to` — the backward branch that forms the loop
   - `fact` — the prologue: which registers get saved, and where
   - `largest` — how the array pointer advances
   - `scale` — there is no `mul` and no `div`. Find out what it did instead.
5. Rebuild at a higher optimisation level and compare:

   ```sh
   make clean && make cbuild COPT=-O2
   ```

## Checkpoints

- Part 1 prints `42`.
- TODO 1 prints `5050`, `3628800`, `18`.
- TODO 2 prints `91`.
- In `compute.s`, `fact` has a stack frame and `add_two` does not — the same
  leaf versus non-leaf split you implemented by hand.
- `scale` computes `(x * 8) / 4` using **shifts**, not multiply and divide.
  Work out why that is valid and when it would stop being valid.
- At `-O2`, `sum_to` may not contain a loop at all. If so, explain what the
  compiler did.

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
| `fact` result wrong above 20 | 64-bit overflow, not a compiler bug. |

General problems — toolchain, QEMU, GDB — are in `docs/troubleshooting.md`.
