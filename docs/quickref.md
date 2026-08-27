# Quick Reference — RISC-V Labs

One page. Everything you need after Lab 0.

## Connect to your Pi

```sh
ssh pi@192.168.2.2
```

**Turn off your VPN first.** It is the single most common reason this fails.
Quit the VPN application entirely — disconnecting is not enough, and some
clients restart themselves.

If `ssh` times out, check the link before anything else:

```sh
ping 192.168.2.2
```

## Build and run a lab

```sh
cd ~/comparch/labs/lab01
make            # assemble and link
make run        # run under QEMU
make dump       # disassemble — see the real machine code
make clean      # delete build artifacts
make help       # list every target
```

**Quit QEMU with `Ctrl-A` then `X`.** Not `Ctrl-C`. If you close your SSH
session with QEMU still running, it keeps running on the Pi.

## Debug with GDB

Terminal 1:

```sh
make debug      # QEMU starts paused, waiting for a debugger
```

Terminal 2 — a second SSH session to the same Pi:

```sh
cd ~/comparch/labs/lab01
gdb-multiarch bridge.elf        # use your lab's .elf name
```

Then at the `(gdb)` prompt:

| Command | What it does |
|---|---|
| `target remote :1234` | connect to the waiting QEMU |
| `break _start` | stop at the first instruction |
| `continue` | run to the next breakpoint |
| `stepi` | execute exactly one instruction |
| `info registers` | show all 32 registers |
| `info registers t0 t1` | show just those two |
| `x/8xg $sp` | examine 8 doublewords at the stack pointer |
| `layout asm` | live disassembly pane |
| `quit` | leave GDB |

## Registers

| Name | Also | Purpose | Survives a call? |
|---|---|---|---|
| `zero` | `x0` | always 0, writes are discarded | — |
| `ra` | `x1` | return address | no |
| `sp` | `x2` | stack pointer | yes |
| `a0`–`a7` | `x10`–`x17` | arguments and return values | no |
| `t0`–`t6` | `x5`–`x7`, `x28`–`x31` | temporaries | **no** |
| `s0`–`s11` | `x8`–`x9`, `x18`–`x27` | saved registers | **yes** |

## Instructions you will use constantly

```
    li    t0, 42            load a constant
    mv    t1, t0            copy a register
    add   t2, t0, t1        t2 = t0 + t1
    addi  t2, t0, 5         t2 = t0 + 5      (constant fits in 12 bits)
    sub   t2, t0, t1        t2 = t0 - t1

    ld    t0, 0(t1)         load 8 bytes from the address in t1
    sd    t0, 0(t1)         store 8 bytes to the address in t1
    lbu   t0, 0(t1)         load 1 byte, zero-extended
    la    t0, label         t0 = the ADDRESS of label

    beq   t0, t1, L         branch if equal
    bne   t0, t1, L         branch if not equal
    blt   t0, t1, L         branch if less than      (signed)
    bge   t0, t1, L         branch if >=             (signed)
    j     L                 jump, always

    call  name              call a procedure
    ret                     return from one
```

Local labels: `1:` and `2:` can be reused. `1b` branches back to the nearest
`1:`, `1f` forwards.

## Console helpers

Labs 1 and later link `common/uart.s`:

| Call | Argument | Effect |
|---|---|---|
| `putc` | `a0` = ASCII value | print one character |
| `puts` | `a0` = address of a NUL-terminated string | print a string |
| `print_int` | `a0` = signed 64-bit value | print it in decimal |
| `newline` | — | print `\n` |

## Something is wrong

```sh
~/comparch/scripts/sanity_check.sh
```

That rebuilds a known-good program and tells you whether the problem is your
environment or your code. Paste its output when you ask for help.

Fuller list of failures and causes: `docs/troubleshooting.md`.
