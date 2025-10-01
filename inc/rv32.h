#ifndef NANORV32_H
#define NANORV32_H
#include "riscv32_regs.h"
#include "soc_regs.h"
#include "riscv-csr.h"



#define CPU_CLK_FREQ  10000000 /*10 MHz*/

#define PUSH_CUSTOM_TRAP_REGS
#define POP_CUSTOM_TRAP_REGS 

#define US_PER_SECOND 1000000

void risc_v_trap_handler(void) __attribute__((interrupt));


#endif // NANORV32_H