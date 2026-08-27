# Instructor Notes — RISC-V Lab Track

**Not for distribution to students.** Delete this file, or keep it out of
whatever you hand them.

## What this is

A lab track for COSC 3341 that runs a RISC-V environment on the Raspberry Pi 4
students already own from freshman year. Students connect over VNC from their
own laptop, write RV64 assembly, cross-compile it with GCC, run it under QEMU,
and debug it with GDB.

It **complements Ripes rather than replacing it.** Ripes stays the tool for
datapath and pipeline visualisation. This gives the compile-run-debug workflow
that Ripes does not.

## Status

| | |
|---|---|
| Lab 0 | Complete. Setup verification, no graded content. |
| Labs 1–5 | Written, with TODOs. Ordering **not** final — see below. |
| Tested on hardware | **Yes, 2026-08-26.** Raspberry Pi 4, Debian 13 (trixie), aarch64. |

Tested from a clean clone: `setup.sh` end to end and again a second time,
`scripts/sanity_check.sh` standalone, all six labs built, ran and cleaned, a
real GDB session that breakpoints and single-steps, and every TODO solved to
confirm the checkpoint values in each README.

**Caveat on the test machine.** It runs Debian 13 (trixie), not the Raspberry
Pi OS image students have. The package split described below was found because
of that difference, so testing on trixie was worth more than testing on a
matching image would have been — but a student Pi should still be tested before
release.

Labs are deliberately independent. No lab refers to another by number, and
nothing is shared between them except `common/`. Reorder them freely to match
your lecture sequence; nothing needs editing if you do.

| Lab | Topic | P&H |
|---|---|---|
| 1 | ISA basics: registers, arithmetic, load/store | 2.2–2.6 |
| 2 | Branching and control flow | 2.7 |
| 3 | Memory and the stack | 2.6, 2.8 |
| 4 | Procedures and calling conventions | 2.8 |
| 5 | C ↔ assembly bridge *(optional)* | 2.8, 2.12 |

## What each lab expects to take

Roughly one class period each, assuming students arrive with the environment
working. Lab 0 is the one that protects that assumption — run it early, in
class, and do not let anyone skip the GDB step. Discovering GDB is broken
during Lab 4 costs a whole period.

## Deliverables and submission

Each lab README asks for source, terminal output, and a short handwritten
trace or explanation. The handwritten part is doing real work: it is where a
student who pattern-matched their way to a correct answer becomes visible.

The traces to weight most heavily:

- **Lab 3** — what happened when they removed one `addi sp, sp, 8` on purpose.
  A student who can explain why the failure surfaced somewhere unrelated has
  understood the stack.
- **Lab 4** — the stack diagram for `fact(3)`. Hard to fake.

## Things students reliably get wrong

1. **Stepping an array pointer by 1 instead of 8.** Produces nonsense values
   rather than a crash, so they do not know they are wrong. Lab 2, Lab 3.
2. **Assuming `t0`–`t6` survive a call.** Lab 4 is built to make this happen
   on purpose, so it is a teaching moment rather than a mystery.
3. **Unbalanced stack.** The failure appears far from the cause. Worth saying
   out loud before Lab 3 rather than after.
4. **`Ctrl-C` to quit QEMU.** It is `Ctrl-A` then `X`. This is printed by
   `make run` and is in every README, and they will still do it.
5. **VPN.** Every networking problem, all semester. Lead with it.

## Answer keys

There are none in this repository. Every lab has a worked example as Part 1,
which is the pattern the TODOs follow. If you want keys, keep them in a
separate private repository rather than a branch here — a branch is one
`git checkout` away from a student who is curious.

## Updating labs mid-semester

`setup.sh` runs `git pull --ff-only` when it finds an existing checkout, and
deliberately does **not** clobber local changes. A student with edited files
keeps them and gets a warning. That means a mid-semester fix reaches students
who re-run `setup.sh`, and does not silently destroy anyone's work.

If you change a lab after students have started it, tell them explicitly. Do
not rely on the pull.

## The QEMU package name differs by Debian release

`qemu-system-riscv64` lives in **`qemu-system-misc`** on Bookworm and in
**`qemu-system-riscv`** on Trixie. On Trixie, `qemu-system-misc` no longer
contains the binary at all — it installs cleanly and leaves you with no
emulator and no error message.

`setup.sh` asks apt which package exists rather than assuming. If you ever see
a student with the toolchain installed and `qemu-system-riscv64: not found`,
this is why, and re-running `setup.sh` fixes it.

## Before this goes to students

Done once on a Debian 13 Pi 4. Repeat on a real student image:

1. `setup.sh` on a freshly imaged Pi 4 (2 GB), start to finish
2. `setup.sh` again on the same Pi — it must be safe twice
3. `scripts/sanity_check.sh` returns PASS
4. Every lab: `make`, `make run`, `make dump`, `make clean`
5. `make debug` on at least one lab, with a real GDB session that breaks,
   steps, and reads registers
6. Solve the TODOs yourself and confirm the expected outputs in each README's
   Checkpoints section are correct

Working under emulation on a laptop is not evidence any of this works on a Pi.
Running it on a Pi found five defects that reading it did not.

## Why `lla` and not `la`

The labs use `lla` throughout. With this toolchain `la` generates an
`auipc` + `ld` pair that loads the address **through the global offset
table** — a dynamic-linking mechanism with no business in a bare-metal
program, and one that does not match anything in Patterson & Hennessy.
`lla` generates `auipc` + `addi`, computing the address directly from the
program counter, which is what the textbook describes and what students
should see in `make dump`.

If a student writes `la` out of habit their code still works. The
disassembly just stops matching the README, which is worth a sentence in
class rather than a correction.

## Known limits

- **`print_int` and the most negative number.** `neg` has no valid result for
  the most negative 64-bit value. Not worth fixing; worth knowing if a student
  finds it, because finding it is a good sign.
- **No input.** The UART is transmit-only in these labs. Nothing reads from
  the console.
- **Single hart.** QEMU runs with `-smp 1` so execution order is predictable.
  Anything about concurrency is out of scope here.
