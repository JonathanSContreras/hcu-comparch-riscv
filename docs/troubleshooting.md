# Troubleshooting

Work down the list. The first section fixes most problems.

## Start here

**Is your VPN off?** Quit the application entirely — disconnecting is not
enough, and corporate clients restart themselves. Check your menu bar or system
tray. This is the most common cause of "I can't reach my Pi."

**Is the link alive?**

```sh
ping 192.168.2.2          # from your laptop
```

If that fails, nothing else here will help. Check that the Ethernet cable is
connected at both ends, your laptop is on Wi-Fi, and internet sharing is
enabled on your laptop from Wi-Fi to the Ethernet adapter.

**Is the environment intact?**

```sh
~/comparch/scripts/sanity_check.sh
```

This builds a known-good program and runs it. It distinguishes "your code is
broken" from "your environment is broken", which need completely different
fixes. Paste its output when asking for help.

## Setup

| Symptom | Cause and fix |
|---|---|
| `setup.sh` fails partway through | Safe to re-run — it skips what is already installed. |
| `apt` cannot reach the repository | The Pi has no internet. Internet sharing is off on your laptop, or a VPN is running. Test with `ping -c 4 8.8.8.8` on the Pi. |
| `Not enough free disk space` | The toolchain needs roughly 1.2 GB. Find what is using it: `sudo du -xh / --max-depth=2 \| sort -rh \| head -20` |
| `The lab repository URL has not been filled in` | You are running an old copy of `setup.sh`. Pull the current one. |
| Packages installed but commands missing | A package name changed in your OS version. Show your TA. |

## Building

| Symptom | Cause and fix |
|---|---|
| `No RISC-V compiler found on PATH` | `setup.sh` did not finish. Re-run it. |
| `Error: illegal operands` on `addi` | Your immediate is bigger than 12 bits signed (−2048…2047). Use `li` into a register, then `add`. |
| `undefined reference to puts` | The lab's Makefile needs `USE_UART = 1`. Lab 0 deliberately does not use it. |
| `undefined reference to _stack_top` | You are not linking with `common/link.ld`. Build with `make`, not by calling `gcc` yourself. |
| `relocation truncated to fit` | A `la` to something too far away, usually a missing `.section` directive putting data somewhere unexpected. |

## Running

| Symptom | Cause and fix |
|---|---|
| `qemu-system-riscv64: not found` | `sudo apt install qemu-system-misc` — the binary lives in a differently named package. |
| Nothing prints, QEMU sits there | Your program never reached a store to `0x10000000`, or it branched past it. |
| It runs but never exits | Missing or unreachable write to the test finisher at `0x00100000`. Quit with `Ctrl-A` then `X`. |
| `Ctrl-C` does not quit QEMU | It is not supposed to. Use `Ctrl-A` then `X`. |
| Terminal is garbled after QEMU | Run `reset`. |
| `Bus error`, or a silent hang on a load | `ld` and `sd` need 8-byte-aligned addresses. Keep `.align 3` above your data and step pointers by 8. |
| Huge or negative numbers where you expected small ones | You used `lw` (4 bytes, sign-extended) instead of `ld` (8 bytes). |
| Jumps somewhere impossible after a `call` | Unbalanced stack, or `ra` overwritten by a nested call and not restored. |

## Debugging

| Symptom | Cause and fix |
|---|---|
| `gdb-multiarch: not found` | `sudo apt install gdb-multiarch` |
| GDB connects but registers are nonsense | Tell it the architecture: `set arch riscv:rv64` before `target remote`. |
| `Remote connection closed` | QEMU exited. Start `make debug` first, then connect. |
| `Address already in use` on port 1234 | An old QEMU is still running. `pkill qemu-system-riscv64`, or use `make debug GDB_PORT=1235`. |
| Breakpoint never hits | You set it on a label that got optimised away, or execution never reaches it. Try `break _start` first to confirm the connection works at all. |

## When you ask for help

Bring these. Having them ready makes the difference between a two-minute fix
and a twenty-minute one:

1. Which lab and which step
2. Whether `ping 192.168.2.2` succeeds
3. Whether you have a VPN installed, and whether it was running
4. The output of `scripts/sanity_check.sh`
5. The exact error message, copied and pasted rather than described
6. Which machine you ran the failing command on — your laptop or the Pi
