#!/usr/bin/env bash
#
# setup.sh — one-time environment setup for the HCU COSC 3341 RISC-V lab track.
# Houston Christian University, College of Science and Engineering.
#
# Installs a RISC-V cross-compiler, the QEMU emulator, and a debugger onto a
# Raspberry Pi running Raspberry Pi OS, then verifies the whole chain works.
#
# Two supported ways to run it:
#
#   A) clone first
#        git clone <repo-url> ~/comparch
#        cd ~/comparch && ./setup.sh
#
#   B) straight from the web
#        curl -fsSL <raw-url>/setup.sh | bash
#
# The script works out which situation it is in and does the right thing.
#
# It is safe to run more than once: already-installed packages are skipped and
# nothing outside of apt packages and ~/comparch is ever touched.

set -uo pipefail

# ---------------------------------------------------------------- settings
REPO_URL="${REPO_URL:-https://github.com/JonathanSContreras/hcu-comparch-riscv.git}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/comparch}"
REQUIRED_MB=1200          # toolchain + QEMU + headroom
PACKAGES=(gcc-riscv64-linux-gnu gdb-multiarch make git)   # + a QEMU package, chosen below
TOTAL_STEPS=6

# ------------------------------------------------------------------ output
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    BOLD=$(tput bold); RED=$(tput setaf 1); GRN=$(tput setaf 2)
    YLW=$(tput setaf 3); CYN=$(tput setaf 6); RST=$(tput sgr0)
else
    BOLD=""; RED=""; GRN=""; YLW=""; CYN=""; RST=""
fi

STEP=0
step()  { STEP=$((STEP + 1)); printf '\n%s[%d/%d] %s%s\n' "$BOLD$CYN" "$STEP" "$TOTAL_STEPS" "$*" "$RST"; }
info()  { printf '      %s\n' "$*"; }
ok()    { printf '      %s+%s %s\n' "$GRN" "$RST" "$*"; }
skip()  { printf '      %s.%s %s\n' "$CYN" "$RST" "$*"; }
warn()  { printf '      %s!%s %s\n' "$YLW" "$RST" "$*"; }
die()   {
    printf '\n%s  SETUP FAILED  %s %s\n\n' "$BOLD$RED" "$RST" "$1"
    shift
    for line in "$@"; do printf '      %s\n' "$line"; done
    printf '\n'
    exit 1
}

printf '\n%s================================================================%s\n' "$BOLD" "$RST"
printf '%s  HCU COSC 3341 - RISC-V Lab Environment Setup%s\n' "$BOLD" "$RST"
printf '%s  Raspberry Pi 4 / Raspberry Pi OS / RV64GC%s\n' "$BOLD" "$RST"
printf '%s================================================================%s\n' "$BOLD" "$RST"

# =========================================================== 1. preflight
step "Checking this machine"

command -v apt-get >/dev/null 2>&1 || die \
    "This does not look like a Debian-based system." \
    "setup.sh expects Raspberry Pi OS (which is Debian-based)." \
    "It needs apt-get, which was not found."
ok "Debian-based system with apt"

ARCH="$(uname -m)"
case "$ARCH" in
    aarch64|armv7l|armv6l) ok "architecture: $ARCH" ;;
    *) warn "architecture is $ARCH, not the expected ARM Raspberry Pi."
       warn "Continuing anyway -- this should still work." ;;
esac

if [ "$(id -u)" -eq 0 ]; then
    warn "Running as root. The lab repo will be installed to /root/comparch,"
    warn "which is probably not what you want. Run as your normal user."
    SUDO=""
else
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
        ok "running as user '$(id -un)'; will use sudo for package installs"
    else
        die "sudo is not installed and you are not root." \
            "setup.sh needs administrator rights to install packages."
    fi
fi

# ========================================================== 2. disk space
step "Checking disk space"

AVAIL_MB=$(df -Pk "$HOME" 2>/dev/null | awk 'NR==2 {print int($4/1024)}')
if [ -z "$AVAIL_MB" ]; then
    warn "Could not determine free disk space. Continuing."
elif [ "$AVAIL_MB" -lt "$REQUIRED_MB" ]; then
    die "Not enough free disk space." \
        "Free:   ${AVAIL_MB} MB" \
        "Needed: ${REQUIRED_MB} MB (RISC-V toolchain + QEMU)" \
        "" \
        "Free some space and run this script again. To see what is using it:" \
        "    sudo du -xh / --max-depth=2 2>/dev/null | sort -rh | head -20"
else
    ok "${AVAIL_MB} MB free (need ~${REQUIRED_MB} MB)"
fi

# ============================================================ 3. network
step "Checking internet access"

net_ok=0
for host in deb.debian.org github.com; do
    if getent hosts "$host" >/dev/null 2>&1; then
        ok "can resolve $host"
        net_ok=1
    else
        warn "cannot resolve $host"
    fi
done

if [ "$net_ok" -eq 0 ]; then
    die "No internet connection." \
        "Your Pi reaches the internet through the Ethernet cable to your laptop," \
        "so the problem is almost always on the laptop side. Check that:" \
        "" \
        "  1. The Ethernet cable is connected at both ends." \
        "  2. Your laptop is connected to Wi-Fi." \
        "  3. Internet Sharing / connection sharing is ENABLED on your laptop," \
        "     shared from Wi-Fi to the Ethernet adapter." \
        "" \
        "Then confirm the Pi can see your laptop:" \
        "    ping -c 3 192.168.2.1"
fi

# =========================================================== 4. packages
step "Installing packages"

# Which package carries qemu-system-riscv64 depends on the Debian release.
# Bookworm ships it inside qemu-system-misc. Trixie split the RISC-V system
# emulators out into qemu-system-riscv, and on trixie qemu-system-misc does
# NOT contain it -- installing that alone leaves you with no emulator and no
# error. Ask apt which package actually exists rather than assuming.
QEMU_PKG=""
for cand in qemu-system-riscv qemu-system-misc; do
    if apt-cache show "$cand" >/dev/null 2>&1; then QEMU_PKG="$cand"; break; fi
done
if [ -z "$QEMU_PKG" ]; then
    die "Cannot find a QEMU package providing qemu-system-riscv64." \
        "Looked for: qemu-system-riscv, qemu-system-misc" \
        "" \
        "Try 'sudo apt-get update' first. If neither exists on your system," \
        "show this message to your TA."
fi
PACKAGES+=("$QEMU_PKG")
info "QEMU package for this release: $QEMU_PKG"

missing=()
for pkg in "${PACKAGES[@]}"; do
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
        skip "$pkg (already installed)"
    else
        missing+=("$pkg")
    fi
done

if [ "${#missing[@]}" -eq 0 ]; then
    ok "all ${#PACKAGES[@]} packages already present -- nothing to install"
else
    info "need to install: ${missing[*]}"
    info "refreshing package lists (this can take a minute) ..."
    if ! $SUDO apt-get update -qq; then
        warn "apt-get update reported a problem; trying the install anyway"
    fi
    info "installing ..."
    if ! $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"; then
        die "Package installation failed." \
            "Tried to install: ${missing[*]}" \
            "" \
            "Most common causes:" \
            "  - the internet connection dropped partway through" \
            "  - another program is holding the apt lock (wait, then retry)" \
            "  - the disk filled up" \
            "" \
            "It is safe to just run this script again."
    fi
    for pkg in "${missing[@]}"; do ok "$pkg installed"; done
fi

# --- verify the binaries we actually care about are now on PATH ------------
declare -a MISSING_BINS=()
for bin in qemu-system-riscv64 riscv64-linux-gnu-gcc gdb-multiarch make git; do
    command -v "$bin" >/dev/null 2>&1 || MISSING_BINS+=("$bin")
done
if [ "${#MISSING_BINS[@]}" -gt 0 ]; then
    die "Packages installed, but these commands are still missing:" \
        "    ${MISSING_BINS[*]}" \
        "" \
        "This usually means a package name changed in your OS version." \
        "Show this message to your TA."
fi
ok "verified: qemu-system-riscv64, riscv64-linux-gnu-gcc, gdb-multiarch"

# =========================================================== 5. lab files
step "Setting up the lab repository"

# Are we already running from inside a checkout of the repo? When the script is
# piped in from curl there is no file on disk, so this correctly comes out false.
SELF="${BASH_SOURCE[0]:-}"
REPO_DIR=""
if [ -n "$SELF" ] && [ -f "$SELF" ]; then
    CANDIDATE="$(cd "$(dirname "$SELF")" && pwd)"
    if [ -f "$CANDIDATE/common/rv64.mk" ] && [ -d "$CANDIDATE/labs/lab00" ]; then
        REPO_DIR="$CANDIDATE"
        ok "already inside the lab repo: $REPO_DIR"
        skip "skipping clone"
    fi
fi

if [ -z "$REPO_DIR" ]; then
    if [ -f "$INSTALL_DIR/common/rv64.mk" ]; then
        REPO_DIR="$INSTALL_DIR"
        ok "found an existing checkout at $REPO_DIR"
        if command -v git >/dev/null 2>&1 && [ -d "$REPO_DIR/.git" ]; then
            info "checking for lab updates ..."
            if git -C "$REPO_DIR" pull --ff-only >/dev/null 2>&1; then
                ok "up to date"
            else
                # Never clobber student work -- just say so and move on.
                warn "could not fast-forward (you may have local edits)."
                warn "that is fine; your existing files were left untouched."
            fi
        fi
    else
        case "$REPO_URL" in
            *CHANGEME*)
                die "The lab repository URL has not been filled in yet." \
                    "Edit REPO_URL at the top of setup.sh, or run:" \
                    "    REPO_URL=https://github.com/<org>/hcu-comparch-riscv.git bash setup.sh"
                ;;
        esac
        info "cloning $REPO_URL"
        info "     into $INSTALL_DIR"
        if ! git clone --quiet "$REPO_URL" "$INSTALL_DIR"; then
            die "Could not clone the lab repository." \
                "URL: $REPO_URL" \
                "" \
                "Check that the URL is correct and that you have internet access."
        fi
        REPO_DIR="$INSTALL_DIR"
        ok "cloned to $REPO_DIR"
    fi
fi

chmod +x "$REPO_DIR"/scripts/*.sh 2>/dev/null || true

# --- record the detected toolchain prefix for the Makefiles ----------------
# common/toolchain.env uses KEY=value syntax, which both make and sh can read.
RISCV_PREFIX=""
for p in riscv64-linux-gnu- riscv64-unknown-elf- riscv64-elf-; do
    if command -v "${p}gcc" >/dev/null 2>&1; then RISCV_PREFIX="$p"; break; fi
done
printf '# Written by setup.sh -- detected RISC-V toolchain. Safe to delete.\nRISCV_PREFIX=%s\n' \
    "$RISCV_PREFIX" > "$REPO_DIR/common/toolchain.env"
ok "toolchain recorded: ${RISCV_PREFIX}gcc"

# ======================================================= 6. sanity check
step "Verifying the environment end to end"
info "compiling and running labs/lab00/starter.s under QEMU ..."

if "$REPO_DIR/scripts/sanity_check.sh"; then
    printf '%s================================================================%s\n' "$BOLD$GRN" "$RST"
    printf '%s  SETUP COMPLETE%s\n' "$BOLD$GRN" "$RST"
    printf '%s================================================================%s\n\n' "$BOLD$GRN" "$RST"
    info "Your lab files are in: $REPO_DIR"
    info ""
    info "Start Lab 0:"
    info "    cd $REPO_DIR/labs/lab00"
    info "    cat README.md"
    info "    make          # assemble and link"
    info "    make run      # run it in QEMU"
    info ""
    info "Quick reference: $REPO_DIR/docs/quickref.md"
    info "Re-run this check any time: $REPO_DIR/scripts/sanity_check.sh"
    printf '\n'
    exit 0
else
    printf '\n%s================================================================%s\n' "$BOLD$RED" "$RST"
    printf '%s  SETUP INCOMPLETE%s\n' "$BOLD$RED" "$RST"
    printf '%s================================================================%s\n\n' "$BOLD$RED" "$RST"
    info "The packages installed, but the test program did not run correctly."
    info "The sanity check output above says what went wrong."
    info ""
    info "It is safe to run this script again:  bash $REPO_DIR/setup.sh"
    printf '\n'
    exit 1
fi
