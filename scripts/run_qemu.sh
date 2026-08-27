#!/usr/bin/env bash
#
# run_qemu.sh — launch an RV64GC bare-metal ELF under qemu-system-riscv64.
#
# Usage:
#   run_qemu.sh <program.elf>                 run it
#   run_qemu.sh --debug [--port N] <prog.elf> halt at _start, wait for GDB
#
# Called by the per-lab Makefiles (`make run`, `make debug`), but it works
# standalone too.

set -euo pipefail

QEMU=qemu-system-riscv64
MACHINE=virt
MEM=64M          # plenty for these labs; keeps QEMU's footprint small
PORT=1234
DEBUG=0
ELF=""

usage() {
    sed -n '3,10p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --debug)     DEBUG=1; shift ;;
        --port)      PORT="${2:?--port needs a number}"; shift 2 ;;
        -h|--help)   usage 0 ;;
        -*)          echo "run_qemu.sh: unknown option '$1'" >&2; usage 1 ;;
        *)           ELF="$1"; shift ;;
    esac
done

if [ -z "$ELF" ]; then
    echo "run_qemu.sh: no ELF file given" >&2
    usage 1
fi

if [ ! -f "$ELF" ]; then
    echo "run_qemu.sh: '$ELF' does not exist -- did you run 'make' first?" >&2
    exit 1
fi

if ! command -v "$QEMU" >/dev/null 2>&1; then
    echo "run_qemu.sh: $QEMU not found." >&2
    echo "             Install it with: sudo apt install qemu-system-misc" >&2
    echo "             (or re-run ~/comparch/setup.sh)" >&2
    exit 1
fi

# -bios none      : no OpenSBI firmware; our ELF IS the whole system
# -nographic      : wire the guest UART straight to this terminal
# -smp 1          : one hart, so execution order is easy to reason about
QEMU_ARGS=(
    -machine "$MACHINE"
    -bios none
    -nographic
    -m "$MEM"
    -smp 1
    -kernel "$ELF"
)

if [ "$DEBUG" -eq 1 ]; then
    # -S freezes the CPU before the first instruction; -gdb opens the stub.
    QEMU_ARGS+=( -S -gdb "tcp::${PORT}" )

    # Pad so the inline descriptions line up whatever port number is in use.
    CONNECT_CMD=$(printf '%-28s' "target remote :${PORT}")

    cat <<BANNER

  QEMU is paused at _start, waiting for a debugger on port ${PORT}.

  Open a SECOND terminal on the Pi (another SSH session) and run:

      cd $(pwd)
      gdb-multiarch ${ELF}

  Then, at the (gdb) prompt:

      set arch riscv:rv64         only if gdb did not detect it
      ${CONNECT_CMD}connect to QEMU
      break _start                stop at the first instruction
      layout asm                  show a live disassembly pane
      stepi                       execute exactly one instruction
      info registers              dump all 32 registers
      continue                    run until the next breakpoint

  Quit QEMU with:  Ctrl-A  then  X

BANNER
fi

exec "$QEMU" "${QEMU_ARGS[@]}"
