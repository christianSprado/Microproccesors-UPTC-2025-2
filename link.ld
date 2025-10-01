/* link.ld — Bare-metal RV32IM para QEMU 'virt' (RAM en 0x80000000)
 * Ubica .init/.text/.rodata/.data/.bss en DRAM
 * Exporta símbolos para Start.S: _sbss/_ebss/_sdata/_edata/_sidata/_stack_top
 */
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
  RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 128M
}

/* opcional (small data) */
PROVIDE(__global_pointer$ = ORIGIN(RAM) + 0x800);

SECTIONS
{
  . = ORIGIN(RAM);

  /* Asegura _start al comienzo */
  .init : {
    KEEP(*(.init))
  } > RAM

  .text : {
    *(.text .text.*)
    *(.gnu.linkonce.t.*)
  } > RAM

  .rodata : {
    *(.rodata .rodata.*)
    *(.gnu.linkonce.r.*)
  } > RAM

  /* VMA y LMA en RAM; _sidata se define con LOADADDR por generalidad */
  .data : ALIGN(4) {
    _sdata = .;
    *(.sdata .sdata.*)
    *(.data .data.*)
    *(.gnu.linkonce.d.*)
    _edata = .;
  } > RAM AT> RAM

  _sidata = LOADADDR(.data);

  .bss (NOLOAD) : ALIGN(4) {
    _sbss = .;
    *(.bss .bss.*)
    *(COMMON)
    _ebss = .;
  } > RAM

  /* Pila descendente al tope de RAM */
  . = ORIGIN(RAM) + LENGTH(RAM);
  PROVIDE(_stack_top = .);
  PROVIDE(_end = .);
}
