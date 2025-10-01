/* Start.S — CRT0 mínimo para RV32IM en QEMU 'virt'
 * - Coloca el stack
 * - Limpia .bss
 * - Copia .data (no-op si LMA==VMA)
 * - Ajusta mtvec al trap handler en C
 * - Llama a main()
 * - Si main retorna: ebreak + WFI loop
 */
    .option norelax
    .section .init
    .globl _start
_start:
    /* 1) SP al tope de RAM */
    la      sp, _stack_top

    /* 2) .bss = 0 */
    la      t0, _sbss
    la      t1, _ebss
1:  bgeu    t0, t1, 2f
    sw      zero, 0(t0)
    addi    t0, t0, 4
    j       1b
2:

    /* 3) Copiar .data de _sidata a [_sdata, _edata) */
    la      t0, _sdata      /* dst */
    la      t1, _edata
    la      t2, _sidata     /* src */
3:  bgeu    t0, t1, 4f
    lw      t3, 0(t2)
    sw      t3, 0(t0)
    addi    t0, t0, 4
    addi    t2, t2, 4
    j       3b
4:

    .extern risc_v_trap_handler
    la      t0, risc_v_trap_handler
    csrw    mtvec, t0

    /* 5) main() */
    .extern main
    call    main

halt:
    ebreak
1:  wfi
    j       1b
