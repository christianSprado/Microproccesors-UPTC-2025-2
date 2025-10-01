// trap.c — Default trap handler for RV32IM

#include <stdint.h>

// Weak attribute: allows user code to override if needed
__attribute__((weak))
void risc_v_trap_handler(void) {
    // Infinite loop on unexpected trap/interrupt
    while (1) {
        // could add a "ebreak" here for debug
        __asm__ volatile("wfi");
    }
}
