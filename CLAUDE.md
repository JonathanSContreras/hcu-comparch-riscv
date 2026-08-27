# CLAUDE.md — hcu-comparch-riscv

Context file for Claude Code sessions on this repository. Read this before touching anything.

Status markers used throughout:
- **[LOCKED]** — decided by faculty or validated in practice. Do not relitigate. If you think one is wrong, say so and stop; do not silently work around it.
- **[PROPOSED]** — my working design. Reasonable to change, but flag the change.
- **[OPEN]** — genuinely undecided, usually blocked on someone else.

---

## 1. What this project is

A RISC-V lab track for **COSC 3341 — Computer Architecture**, Fall 2026, at Houston Christian University (College of Science and Engineering).

Students run a RISC-V emulation environment (QEMU) **on their own Raspberry Pi 4 (2 GB)**, which they already own from freshman year. They write RISC-V assembly, cross-compile it with GCC, run it under QEMU, and debug it with GDB.

This is **not a standalone course**. It is a lab track bolted onto an existing lecture course taught by Professor Aguilar out of Patterson & Hennessy. Every lab must map onto lecture content, not stand apart from it.

This is a **real production deliverable**. Real students will run this on real hardware in a real classroom, with a TA (me) on the hook when it breaks. Code accordingly: fail loudly, print useful errors, never assume a clean environment.

### Relationship to Ripes [LOCKED]

The course already uses **Ripes** for datapath and pipeline visualization. This lab track **complements Ripes; it does not replace it.**

- Ripes → visualization layer. Datapath, pipeline stages, hazards.
- Pi/QEMU → realistic compile-run-debug workflow. Toolchain, Makefiles, GDB, memory-mapped I/O.

Never write documentation or lab text that positions this as a Ripes replacement.

---

## 2. People

| Person | Role | Relevance |
|---|---|---|
| **Jonathan** | Lab Assistant & TA, CoSE | Me. Author and owner of this repo. |
| **Professor Aguilar** | Faculty lead, COSC 3341 | Approved the proposal. Owns the lecture schedule and final say on curriculum. |
| **Dr. Mardini** | Faculty, database course | Separate project. Not relevant here. |
| **Ethan Matuska** | Lab Director | Hardware/lab policy. Not relevant here unless hardware is needed. |

---

## 3. Locked decisions

Confirmed by Professor Aguilar via email, then reflected in proposal v0.3 ("Direction Confirmed").

| Decision | Value |
|---|---|
| Course | COSC 3341, Computer Architecture, Fall 2026 |
| ISA target | **RV64** (RV64GC toolchain, RV64I-level instruction usage in labs) |
| Pedagogy | **Assembly-first.** C appears only later, as an optional bridge to inspect generated assembly. |
| Textbook | Patterson & Hennessy, *Computer Organization and Design: RISC-V Edition*, 2nd Ed. |
| Lab format | In-class |
| Submission | Source code + terminal output + screenshot (where useful) + short handwritten trace/explanation |
| Structure | Lab 0 (setup check) + 4–5 content labs |
| Ripes | Complementary, not a replacement |
| Emulator | `qemu-system-riscv64 -machine virt -bios none -nographic` |
| Toolchain | `riscv64-linux-gnu-*` (apt on Raspberry Pi OS) |
| Debugger | `gdb-multiarch` against the QEMU GDB stub, port 1234 |
| I/O method | **UART MMIO** at `0x10000000` |

### Why RV64 and not RV32I [LOCKED — this changed mid-project]

The original plan was RV32I. Professor Aguilar asked for RV64 because his course materials use RV64. It turned out to be the *easier* path, not a compromise:

- `gcc-riscv64-linux-gnu` is a **standard apt package** on Raspberry Pi OS. One line, installs clean.
- `riscv32-unknown-elf-gcc` is frequently **not in apt** and can require a ~30 minute source build of the GNU toolchain. On 30+ student Pis simultaneously, that is a non-starter.

Everything else (QEMU flags, UART MMIO addresses, GDB setup) is identical between the two. If you find any RV32 references left in this repo, they are stale — fix them.

### Why UART MMIO and not semihosting [LOCKED]

Semihosting tunnels output through the GDB/QEMU host. It is a debugger trick with **no hardware analog**, which is exactly backwards for a Computer Architecture course.

UART MMIO has students writing a byte to a memory address that maps to a hardware register. That is memory-mapped I/O straight out of P&H Ch. 2, and it sets up Ch. 4. Every lab inherits this pattern, so Lab 0 establishes the real thing from the start. The extra code is roughly ten instructions.

---

## 4. Open items

| # | Item | Blocked on | Impact |
|---|---|---|---|
| 1 | Enrollment count | In-person meeting with Aguilar | Support planning, whether labs can be pair-based |
| 2 | Week-by-week lecture schedule | In-person meeting with Aguilar | **Final ordering and content of Labs 1–5** |

**Consequence for you:** Labs 1–5 are scaffolded but their content is *not* frozen. Build them so topics can be reordered without rework — no cross-lab dependencies beyond `common/`, no "as you saw in Lab 3" references in prose. Lab 0 is fully unblocked; build it out completely.

---

## 5. Environment and constraints

### Hardware [LOCKED]
- **Raspberry Pi 4, 2 GB.** Students already own these. No procurement, no budget, no loaners.
- 2 GB is the constraint to design against. QEMU `virt` with 128 MB guest RAM is plenty; do not go allocating gigabytes.
- Students also own Cyber Kits (Ethernet cable, USB-Ethernet adapter) from freshman year.

### Where code runs
- **Everything in this repo runs ON the Pi** — Raspberry Pi OS, arm64, Debian Bookworm base.
- Students **SSH into the Pi** from their own laptops (Windows, macOS, or Linux).
- Host side is therefore **SSH only**. No host-side tooling to build or test. Do not write PowerShell scripts, do not write anything that assumes the student's laptop OS.
- Target shell: `bash` as shipped on RPi OS. Avoid bashisms newer than 5.x, avoid GNU-only flags that Debian's coreutils lacks.

### Networking [LOCKED]
Direct laptop-to-Pi Ethernet with static IPs baked into the course image:

- Pi: `192.168.2.2`
- Host laptop: `192.168.2.1`

`raspberrypi.local` / mDNS is **deprecated and must not appear anywhere**. On shared campus Wi-Fi it caused students to SSH into each other's Pis. This is a known past failure — do not reintroduce it.

**VPN is the single most common connection failure.** Any networking troubleshooting doc must lead with "disconnect from VPN."

---

## 6. Technical reference

### Package install (Raspberry Pi OS)

```bash
sudo apt-get install -y \
    gcc-riscv64-linux-gnu \
    qemu-system-misc \
    gdb-multiarch \
    make \
    git
```

Note: the binary is **not** in a package named after itself. Which package carries it depends on the Debian release, and this bites silently:

| Release | Package |
|---|---|
| Bookworm | `qemu-system-misc` |
| **Trixie** | **`qemu-system-riscv`** — `qemu-system-misc` no longer contains it |

On trixie, installing `qemu-system-misc` succeeds and leaves the machine with no emulator and no error. `setup.sh` asks apt which of the two exists rather than assuming. Verify with `qemu-system-riscv64 --version`, never with `dpkg -l`.

### Memory map (QEMU `virt` machine)

| Address | Purpose |
|---|---|
| `0x10000000` | UART0 THR — write a byte here to emit a character |
| `0x10000005` | UART0 LSR — bit 5 (`0x20`) set means transmitter ready |
| `0x80000000` | Where `-bios none -kernel` loads and begins execution |

### Build / run / debug

```bash
# assemble
riscv64-linux-gnu-as -march=rv64gc -o hello.o hello.s

# link at 0x80000000
riscv64-linux-gnu-ld -T ../common/link.ld -o hello.elf hello.o

# run
qemu-system-riscv64 -machine virt -bios none -nographic -kernel hello.elf

# debug: terminal 1
qemu-system-riscv64 -machine virt -bios none -nographic -kernel hello.elf -S -gdb tcp::1234
# debug: terminal 2
gdb-multiarch hello.elf -ex 'target remote :1234'
```

**Exit QEMU is `Ctrl-A` then `X`.** Students will not guess this. It must appear in Lab 0, in every lab README, and in the `run` target's output. Assume someone will otherwise close their SSH session with a QEMU process still running.

### Reference linker script (`common/link.ld`)

```ld
OUTPUT_ARCH("riscv")
ENTRY(_start)

SECTIONS
{
  . = 0x80000000;

  .text   : { *(.text.init) *(.text*) }
  .rodata : { *(.rodata*) }
  .data   : { *(.data*) }
  .bss    : { *(.bss*) *(COMMON) }

  . = ALIGN(16);
  . += 0x1000;
  stack_top = .;
}
```

### Reference `hello.s` (Lab 0 sanity check)

```asm
        .section .text.init
        .globl _start
_start:
        la      sp, stack_top
        la      a0, msg
        call    puts
halt:   wfi
        j       halt

# a0 = pointer to NUL-terminated string
puts:
        li      t0, 0x10000000      # UART0 transmit-holding register
1:      lbu     t1, 0(a0)
        beqz    t1, 2f
        sb      t1, 0(t0)           # memory-mapped I/O write
        addi    a0, a0, 1
        j       1b
2:      ret

        .section .rodata
msg:    .asciz  "Hello, RISC-V!\n"
```

**Use `lla`, not `la`, for address formation.** With this toolchain `la` emits `auipc` + `ld` through the global offset table — a dynamic-linking mechanism with no place in a bare-metal program, and not what P&H describes. `lla` emits `auipc` + `addi`, which is the pair the textbook teaches and the one students should see in `make dump`. Every lab uses `lla`; the snippet above is illustrative and predates that decision.

QEMU's UART accepts writes without a readiness check, so the minimal version above works. **Introducing the LSR poll (`0x10000005`, bit `0x20`) is good lab material** — it is the difference between "works in the emulator" and "correct against the device", and it is a natural talking point for real hardware. Keep the polling version out of Lab 0 (Lab 0 must be as simple as possible) and consider it for a content lab.

---

## 7. Repository layout [PROPOSED]

**[LOCKED as built — this is the actual tree, not a proposal.]**

```
hcu-comparch-riscv/
├── CLAUDE.md               # this file
├── README.md               # student-facing entry point
├── setup.sh                # one-shot environment bootstrap
├── common/
│   ├── link.ld             # shared linker script, load at 0x80000000
│   ├── uart.s              # shared putc/puts/print_int/newline
│   └── rv64.mk             # shared make rules, included by each lab Makefile
├── labs/
│   ├── lab00/              # README.md, Makefile, starter.s
│   └── lab01/ … lab05/     # same shape
├── scripts/
│   ├── sanity_check.sh     # environment self-check, run by setup.sh and by students
│   ├── run_qemu.sh         # qemu wrapper; --debug adds -S -gdb tcp::1234
│   └── hello.s             # pristine reference program for the sanity check
└── docs/
    ├── quickref.md
    ├── troubleshooting.md
    └── instructor-notes.md
```

Earlier drafts of this file named `lab0/`, `common/lab.mk`, `scripts/verify.sh`, and separate `run.sh` / `debug.sh`. Those names were never built and are not coming back — one `run_qemu.sh --debug` beats two scripts that drift apart. If you are reading an old copy, this tree wins.

Rationale: each lab directory is **self-contained and copy-pasteable**. A student should be able to `cd lab2 && make run` and have it work, with no knowledge of the repo root. Shared logic lives in `common/` and is pulled in by `include ../common/lab.mk`.

### Makefile conventions [PROPOSED]

Every lab Makefile exposes the same targets. Consistency matters more than cleverness here — students learn the interface once.

| Target | Behavior |
|---|---|
| `make` / `make all` | Assemble and link to `<lab>.elf` |
| `make run` | Build, then run under QEMU. Prints the `Ctrl-A X` reminder first. |
| `make debug` | Build, launch QEMU paused with GDB stub, print the exact `gdb-multiarch` command to run in a second terminal |
| `make dump` | `riscv64-linux-gnu-objdump -d` the ELF — useful for the C bridge lab |
| `make clean` | Remove `*.o`, `*.elf` |

Keep the Makefiles readable. Students will be asked to look at them. No recursive make, no generated rules, no `.SECONDEXPANSION`.

---

## 8. `setup.sh` requirements [LOCKED behavior]

This is the highest-risk file in the repo. It runs once per student on 30-ish Pis, likely all in the same class period, and if it fails the lab period is lost.

### Dual bootstrap — detect and adapt

There is **one script**, with two valid entry points. This was a deliberate call: a separate clone-only bootstrapper splits the student experience into two scripts, and someone always runs the wrong one.

1. **Clone-first:** student runs `git clone …` then `./setup.sh`. Script detects it is already inside the repo → skips cloning, continues.
2. **Curl-pipe:** student runs `curl -fsSL … | bash`. Script detects it is *not* in the repo → clones to `~/comparch` → continues from there.

Detection should be positive and specific (e.g. presence of `common/link.ld` and a `.git` dir relative to the script's own location), not a guess based on `$0` alone, which is unreliable under `curl | bash`.

### Hard requirements

- **Idempotent.** Running it twice must be safe and must not duplicate anything. Students will run it twice.
- **Never fail silently.** `set -euo pipefail`, and trap errors with a message that names the step that failed.
- **Check before install.** If `qemu-system-riscv64` already works, say so and skip, don't reinstall.
- **Verify at the end.** Terminate by invoking `scripts/verify.sh` and printing an unambiguous PASS/FAIL summary. "It printed a lot of text" is not a success signal a student can read.
- **No `sudo` beyond `apt-get`.** Do not chown, do not write outside `$HOME` and the package manager.
- **Assume flaky campus network.** apt can fail mid-run. Retry once, then fail with a clear "re-run this script" message.
- **Assume a non-clean Pi.** These are two-year-old student machines with arbitrary prior coursework on them.

### `scripts/verify.sh`

Independent of setup. A student who says "it's broken" should be able to run this and paste the output to me. Checks, each printing PASS/FAIL:

1. `riscv64-linux-gnu-as --version` and `-ld` present
2. `qemu-system-riscv64 --version` present
3. `gdb-multiarch --version` present
4. Repo present and readable at expected path
5. End-to-end: build `lab0/hello.s` in a temp dir and confirm QEMU emits `Hello, RISC-V!`

Item 5 is the one that matters. The first four can all pass while the toolchain still produces something QEMU won't run.

---

## 9. Lab content

### Lab 0 — Environment Setup & Sanity Check [unblocked, build fully]

The only job of Lab 0 is confirming the full toolchain works end-to-end **before** content labs begin. It is not a graded content lab.

Student path: SSH to Pi → run `setup.sh` → `cd lab0 && make run` → see `Hello, RISC-V!` → run `make debug`, set a breakpoint at `_start`, step one instruction, inspect a register → done.

Include the GDB step. Discovering GDB is broken during Lab 3 is much worse than discovering it during Lab 0.

### Labs 1–5 [scaffold now, content pending schedule]

| Lab | Topic | Focus |
|---|---|---|
| 1 | ISA Basics & Registers | Arithmetic, logical ops, load/store, register conventions |
| 2 | Branching and Control Flow | Conditionals, loops, program counter behavior |
| 3 | Memory and the Stack | Stack frames, `sp`/`ra`, manual memory layout |
| 4 | Procedures and Calling Conventions | ABI, caller/callee-saved registers, recursion |
| 5 | C ↔ Assembly Bridge (**optional**) | Compile C at `-O0`, inspect generated RV64 assembly |

Ordering follows the lecture schedule and **is not final**. Build each lab so it can move without edits to any other lab.

### Lab README template [PROPOSED]

Every lab README uses the same sections, in this order:

1. **Objective** — one paragraph, tied explicitly to a P&H chapter/section
2. **Background** — what's new since the last lab
3. **Instructions** — numbered steps
4. **Checkpoints** — explicit "you should see X" moments so students self-verify mid-lab
5. **Deliverables** — source, terminal output, screenshot, handwritten trace
6. **Troubleshooting** — lab-specific failures only; general ones go in `docs/troubleshooting.md`

---

## 10. Working agreements

- **Ask before adding dependencies.** Anything beyond the five apt packages listed above needs a reason. Every dependency is another thing that fails on 30 Pis at once.
- **No frameworks, no build systems beyond `make`.** Students are reading these files.
- **Assembly is the deliverable, not the scaffolding.** Do not write Python helpers that hide what the toolchain is doing. If a step is tedious, that tedium is often the lesson.
- **Comment the assembly heavily.** These files are teaching material first and code second.
- **Do not overstate what the system does.** If something is manual, the docs say it is manual. No aspirational automation, no implying a script does something it doesn't. This has bitten me before on other projects.
- **Prefer targeted edits over rewrites** when iterating on existing files.
- **Flag anything that contradicts this file** rather than resolving it yourself.

---

## 11. Definition of done

Before any lab is considered complete:

- [ ] `setup.sh` runs clean on a freshly imaged Pi 4 (2 GB)
- [ ] `setup.sh` runs clean a **second** time on the same Pi
- [ ] `scripts/verify.sh` returns all PASS
- [ ] `make`, `make run`, `make debug`, `make clean` all work from inside the lab directory
- [ ] `make debug` produces a GDB session that can break, step, and read registers
- [ ] README instructions followed literally, start to finish, with no prior knowledge assumed
- [ ] `Ctrl-A X` documented in the README and printed by `make run`
- [ ] No mDNS / `raspberrypi.local` references anywhere
- [ ] No RV32 / `riscv32` references anywhere
- [ ] Lab objective cites a specific P&H chapter or section

**Testing on real hardware is required before anything ships to students.** Working under emulation on a dev machine is not evidence it works on a Pi.

**Met 2026-08-26** on a Raspberry Pi 4 running Debian 13, from a clean clone: every box above, plus solving each lab's TODOs to confirm its documented checkpoint values. That pass found five defects invisible in the source — the QEMU package split, a GOT-based `la`, a duplicate make recipe, a lab that would not link from a fresh checkout, and three wrong expected values in lab READMEs.

The test machine ran Debian 13 rather than the student Raspberry Pi OS image. That is what exposed the packaging problem, so it was worth more than a matching image — but a real student Pi has still not been tested.

---

## 12. Related context

- **Proposal doc:** `riscv_ca_proposal_v0.3.docx`, "Direction Confirmed", rebuilt 2026-08-26 in the CoSE house style. The v0.1 draft it replaces still specified RV32I, a `riscv32-unknown-elf` toolchain, six labs with no Lab 0, and never mentioned Ripes — only its open-questions table had been updated, so the document contradicted itself. Both v0.1 files are archived. Version-bump the Status field in the header with every change.
- **Cyber Kit Setup and Configuration Guide:** separate 26-page document covering Pi networking and TigerVNC, used in COSC 1351. That guide is the authority on laptop-to-Pi connection; this repo should link to it rather than duplicate it.
