#!/usr/bin/env bash
#
# sanity_check.sh — prove the RISC-V lab environment works end to end.
#
# Builds a known-good RV64GC program, runs it under qemu-system-riscv64, and
# checks that "Hello, RISC-V" actually came out of the emulated UART. This is
# the same check setup.sh runs at the end; it lives here so it can be re-run
# on its own at any time:
#
#     ~/comparch/scripts/sanity_check.sh
#
# Exit status: 0 = PASS, 1 = FAIL.

set -uo pipefail

EXPECTED="Hello, RISC-V"
QEMU_TIMEOUT=25

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"
COMMON="$REPO_ROOT/common"

# ------------------------------------------------------------------ output
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    BOLD=$(tput bold); RED=$(tput setaf 1); GRN=$(tput setaf 2)
    YLW=$(tput setaf 3); RST=$(tput sgr0)
else
    BOLD=""; RED=""; GRN=""; YLW=""; RST=""
fi
info() { printf '  %s\n' "$*"; }
warn() { printf '  %sWARN%s %s\n' "$YLW" "$RST" "$*"; }
fail() { printf '  %sFAIL%s %s\n' "$RED" "$RST" "$*" >&2; }

# ------------------------------------------------------------- toolchain
# setup.sh writes this; it is `KEY=value`, readable by both make and sh.
RISCV_PREFIX=""
# shellcheck source=/dev/null
[ -f "$COMMON/toolchain.env" ] && . "$COMMON/toolchain.env"

if [ -z "${RISCV_PREFIX:-}" ]; then
    for p in riscv64-linux-gnu- riscv64-unknown-elf- riscv64-elf-; do
        if command -v "${p}gcc" >/dev/null 2>&1; then RISCV_PREFIX="$p"; break; fi
    done
fi

CC="${RISCV_PREFIX}gcc"
QEMU="qemu-system-riscv64"

# `timeout` ships with coreutils on Raspberry Pi OS. Degrade gracefully rather
# than silently mis-reporting if it is ever absent.
if command -v timeout >/dev/null 2>&1;  then TIMEOUT_CMD="timeout"
elif command -v gtimeout >/dev/null 2>&1; then TIMEOUT_CMD="gtimeout"
else TIMEOUT_CMD=""; fi

# ------------------------------------------------------------ preflight
missing=0
if [ -z "$RISCV_PREFIX" ] || ! command -v "$CC" >/dev/null 2>&1; then
    fail "No RISC-V compiler found (looked for riscv64-linux-gnu-gcc)."
    info "     Fix: sudo apt install gcc-riscv64-linux-gnu"
    missing=1
fi
if ! command -v "$QEMU" >/dev/null 2>&1; then
    fail "$QEMU not found."
    info "     Fix: sudo apt install qemu-system-misc"
    missing=1
fi

# A missing debugger does not stop the labs building and running, so this is a
# warning and not a failure. It is checked here because finding out GDB is
# broken during a later lab is far worse than finding out now.
if command -v gdb-multiarch >/dev/null 2>&1; then
    GDB_OK=1
elif command -v "${RISCV_PREFIX}gdb" >/dev/null 2>&1; then
    GDB_OK=1
else
    GDB_OK=0
fi

[ "$missing" -eq 1 ] && exit 1

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# ------------------------------------------------------------- the check
# build_and_run <source.s> <outfile>  -> echoes captured output, returns status
build_and_run() {
    local src="$1" tag="$2"
    local elf="$WORK/$tag.elf" log="$WORK/$tag.log"

    if ! "$CC" -march=rv64gc -mabi=lp64d -g -Wall \
               -nostdlib -nostartfiles -no-pie -static \
               -Wl,--build-id=none -T "$COMMON/link.ld" \
               "$src" -o "$elf" > "$WORK/$tag.build" 2>&1; then
        return 2   # build failure
    fi

    # Reuse run_qemu.sh so QEMU flags live in exactly one place. timeout is a
    # safety net: a correct program powers itself off via the test finisher.
    local rc
    if [ -n "$TIMEOUT_CMD" ]; then
        "$TIMEOUT_CMD" "$QEMU_TIMEOUT" "$SCRIPTS_DIR/run_qemu.sh" "$elf" \
            < /dev/null > "$log" 2>&1
        rc=$?
    else
        "$SCRIPTS_DIR/run_qemu.sh" "$elf" < /dev/null > "$log" 2>&1
        rc=$?
    fi
    if [ $rc -eq 124 ]; then return 3; fi   # hung
    grep -qF "$EXPECTED" "$log" || return 4 # ran, but wrong output
    return 0
}

printf '\n%sRISC-V environment sanity check%s\n' "$BOLD" "$RST"
info "compiler : $CC"
info "emulator : $QEMU"
if [ "$GDB_OK" -eq 1 ]; then
    info "debugger : $(command -v gdb-multiarch 2>/dev/null || command -v "${RISCV_PREFIX}gdb")"
else
    warn "no debugger found -- 'make debug' will not work"
    info "     Fix: sudo apt install gdb-multiarch"
fi
[ -z "$TIMEOUT_CMD" ] && warn "'timeout' not found; a hung program will not be caught"
info ""

# Primary target is the student's own lab00 file, per the lab spec.
STUDENT_SRC="$REPO_ROOT/labs/lab00/starter.s"
REFERENCE_SRC="$SCRIPTS_DIR/hello.s"

student_rc=99
if [ -f "$STUDENT_SRC" ]; then
    info "building and running labs/lab00/starter.s ..."
    build_and_run "$STUDENT_SRC" student
    student_rc=$?
fi

if [ "$student_rc" -eq 0 ]; then
    printf '\n%s  PASS  %s RISC-V toolchain, QEMU, and UART output all working.\n\n' \
        "$BOLD$GRN" "$RST"
    exit 0
fi

# lab00/starter.s did not work. It may simply be that a student edited it.
# Fall back to the pristine reference program to tell those two cases apart --
# "your code is broken" and "your environment is broken" need different fixes.
warn "labs/lab00/starter.s did not produce the expected output."
info "retrying with the pristine reference program to find out why ..."
build_and_run "$REFERENCE_SRC" reference
ref_rc=$?

if [ "$ref_rc" -eq 0 ]; then
    printf '\n%s  PASS  %s Your environment is working correctly.\n\n' "$BOLD$GRN" "$RST"
    case "$student_rc" in
      2) warn "But labs/lab00/starter.s does not assemble. Your edits broke it." ;;
      3) warn "But labs/lab00/starter.s never exits. Check the loop at the end." ;;
      4) warn "But labs/lab00/starter.s did not print \"$EXPECTED\"." ;;
      *) warn "But labs/lab00/starter.s is missing." ;;
    esac
    info "This is a Lab 0 code problem, not a setup problem -- keep going."
    info "To restore the original: git checkout labs/lab00/starter.s"
    printf '\n'
    exit 0
fi

# Both failed -> the environment itself is broken.
printf '\n%s  FAIL  %s The RISC-V environment is not working.\n\n' "$BOLD$RED" "$RST"
case "$ref_rc" in
  2) fail "The reference program would not compile. Compiler output:"
     sed 's/^/       /' "$WORK/reference.build" 2>/dev/null | head -20 ;;
  3) fail "QEMU started but never exited (timed out after ${QEMU_TIMEOUT}s)."
     info "     QEMU runs, but the program never reached the shutdown device." ;;
  4) fail "QEMU ran but \"$EXPECTED\" never appeared. Captured output:"
     sed 's/^/       /' "$WORK/reference.log" 2>/dev/null | head -20
     info "     The UART address (0x10000000) may be wrong for this QEMU build." ;;
  *) fail "Could not run the reference program at all." ;;
esac
printf '\n  Show this output to your TA.\n\n'
exit 1
