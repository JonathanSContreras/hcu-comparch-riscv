# RISC-V Lab Track — COSC 3341 Computer Architecture

Houston Christian University, College of Science and Engineering.

You write RISC-V assembly on the Raspberry Pi 4 you already own, cross-compile
it, run it under QEMU, and debug it with GDB. Same workflow an engineer uses on
a real embedded target, on hardware that costs you nothing extra.

This sits alongside Ripes rather than replacing it. Ripes shows you the
datapath and the pipeline. This shows you the toolchain.

## Setup

Connect to your Pi and run one command.

Open **TigerVNC Viewer** on your laptop, connect to `192.168.2.2`, and log in
as `pi`. That is the same connection you set up in your freshman Cyber Kit — if
you need a reminder, the Cyber Kit Setup and Configuration Guide covers it.

On the Pi desktop, open a terminal and run:

```sh
git clone https://github.com/JonathanSContreras/hcu-comparch-riscv.git ~/comparch
cd ~/comparch && ./setup.sh
```

It installs the cross-compiler, QEMU and the debugger, then builds and runs a
test program to prove the whole chain works. Ten to fifteen minutes, and it is
safe to run again if anything goes wrong.

**Turn your VPN off first.** It is the most common reason setup fails.

## Then

```sh
cd ~/comparch/labs/lab00
cat README.md
```

Lab 0 has no RISC-V programming in it. Its only job is to confirm your
environment works before the graded labs start.

## The labs

| Lab | Topic |
|---|---|
| [00](labs/lab00) | Environment setup and sanity check |
| [01](labs/lab01) | ISA basics: registers, arithmetic, load and store |
| [02](labs/lab02) | Branching and control flow |
| [03](labs/lab03) | Memory and the stack |
| [04](labs/lab04) | Procedures and calling conventions |
| [05](labs/lab05) | C ↔ assembly bridge *(optional)* |

Every lab works the same way:

```sh
make          # assemble and link
make run      # run under QEMU  — quit with Ctrl-A then X
make debug    # run paused, waiting for GDB
make dump     # disassemble and see the real machine code
make clean
make help
```

## When something breaks

```sh
~/comparch/scripts/sanity_check.sh
```

It rebuilds a known-good program and tells you whether the problem is your
environment or your code. Paste its output when you ask for help.

- [Quick reference](docs/quickref.md) — one page, everything you need after Lab 0
- [Troubleshooting](docs/troubleshooting.md) — symptoms and causes

## What you are running

RV64GC under `qemu-system-riscv64` on the `virt` machine, bare metal — no
operating system, no libc. Printing a character means storing a byte to a
device register at `0x10000000`. That is memory-mapped I/O, straight out of
Patterson & Hennessy chapter 2.
