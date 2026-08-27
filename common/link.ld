/* link.ld — memory layout for QEMU's `virt` machine, RV64GC bare metal.
 *
 * You should not need to edit this file for any lab. It is here so you can
 * see exactly where your code and data land in memory.
 *
 * The virt machine puts RAM at 0x8000_0000. Because we boot with
 * `-bios none`, QEMU loads our ELF there and the hart begins executing at
 * the ELF entry point (_start) directly -- no bootloader, no OS.
 *
 * Memory-mapped devices live BELOW RAM:
 *     0x0010_0000   SiFive test finisher  (write 0x5555 to power off)
 *     0x1000_0000   NS16550A UART         (store a byte = print a char)
 */

OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 64M
}

SECTIONS
{
    /* .text.init is listed first so _start sits at the very base of RAM,
     * which makes disassembly output easy to follow. */
    .text : {
        *(.text.init)
        *(.text .text.*)
    } > RAM

    .rodata : {
        *(.rodata .rodata.*)
    } > RAM

    .data : {
        *(.data .data.*)
    } > RAM

    .bss : {
        __bss_start = .;
        *(.bss .bss.*)
        *(COMMON)
        __bss_end = .;
    } > RAM

    /* 16 KB of stack, growing down from _stack_top. Set up your stack
     * pointer with `la sp, _stack_top` if a lab needs one. */
    . = ALIGN(16);
    _stack_bottom = .;
    . += 16K;
    _stack_top = .;

    _end = .;

    /* Note: we deliberately do NOT define __global_pointer$. Leaving it
     * undefined disables linker relaxation to gp-relative addressing, which
     * would otherwise break code that never initializes gp. */

    /DISCARD/ : { *(.comment) *(.note.*) *(.riscv.attributes) }
}
