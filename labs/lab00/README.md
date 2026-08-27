# Lab 00 — Setup Verification

**This lab has no RISC-V programming in it.** Its only job is to confirm that
your Raspberry Pi can assemble, link, run, and debug a RISC-V program before
the real labs begin. If something in your environment is broken, we want to
find out now and not in week four.

Target: **RV64GC** under `qemu-system-riscv64`.

## Before you start

You should already have run the setup script:

```sh
cd ~/comparch && ./setup.sh
```

## Step 1 — Build it

```sh
cd ~/comparch/labs/lab00
make
```

Expected:

```
  AS      starter.s
  LD      starter.elf
  OK      built starter.elf (rv64gc/lp64d)
```

## Step 2 — Run it

```sh
make run
```

Expected output, after which QEMU exits on its own and you get your shell back:

```
Hello, RISC-V -- <your name here>
```

> If QEMU ever *doesn't* exit on its own, quit it with **Ctrl-A** then **X**.
> This is the single most useful thing to remember all semester.

## Step 3 — Prove you can change it

Open `starter.s`, find the `TODO` near the bottom, and replace
`<your name here>` with your actual name. Then:

```sh
make run
```

Seeing your own name means the full edit → assemble → link → emulate loop
works on your machine. That is the whole point of Lab 0.

## Step 4 — Look at the machine code

```sh
make dump
```

This disassembles your program. A few things to notice, because they come
back repeatedly later in the course:

- `la t0, msg` was a **pseudo-instruction**. It is not a real RISC-V
  instruction; the assembler turned it into two (`auipc` + `addi`).
- Registers print as `x5`, `x6`, `x7` rather than `t0`, `t1`, `t2`. Those are
  the same registers — `t0` is just a conventional name for `x5`.
- Some instructions are only **2 bytes** long and start with `c.` (like
  `c.addi`). Those are compressed instructions, the "C" in RV64GC.

## Step 5 — Confirm the debugger works

```sh
make debug
```

That prints connection instructions and waits. Open a **second SSH session**
to the Pi, follow the printed steps to attach `gdb-multiarch`, then try
`stepi` a few times and `info registers`. Quit QEMU with **Ctrl-A**, **X**.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `No RISC-V compiler found on PATH` | `setup.sh` did not finish — re-run it |
| `qemu-system-riscv64 not found` | `sudo apt install qemu-system-misc` |
| `make run` prints nothing and hangs | UART address wrong for your QEMU version — tell the TA |
| Terminal acts strange after QEMU | run `reset` |

## Handing in

Paste the output of `make run` (showing your name) and `make dump`.

> _Exact submission instructions to be added by the instructor._
