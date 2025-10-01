#include <stdint.h>
#include <stdio.h>
#include "soc_emu_gpio.h"
#include "soc_uart.h"

static char wr_buffer[256] = "";

static inline void delay(volatile uint32_t count) {
    while (count--) { asm volatile("nop"); }
}

void main(void) {
    volatile uint32_t sw_value = 1;

    emu_gpio_init();
    uart_init(115200);

    // Mensajes iniciales por UART
    uart_puts("Bienvenido! u=incrementar, d=decrementar, salir: Ctrl+A, X\n");
    uart_puts("GPIO listo. Rango: 0x00..0xFF\n");

    // Publica estado inicial
    emu_gpio_write_port((uint8_t)sw_value);
    sprintf(wr_buffer, "GPIO State: 0x%02X\r\n", (uint8_t)sw_value);
    uart_puts(wr_buffer);

    while (1) {
        while (uart_tstc()) {          // ¿hay dato disponible?
            char c = uart_getc();      // lee un caracter

            if (c == 'u') {
                sw_value++;            // incrementa
            } else if (c == 'd') {
                if (sw_value > 0) {    // evita underflow 0 -> 0xFFFFFFFF
                    sw_value--;
                }
            }

            // Limita a 8 bits (0..0xFF)
            if (sw_value > 0xFFu) {
                sw_value = 0xFFu;
            }

            // Escribe al GPIO e informa por UART
            emu_gpio_write_port((uint8_t)sw_value);
            sprintf(wr_buffer, "GPIO State: 0x%02X\r\n", (uint8_t)sw_value);
            uart_puts(wr_buffer);
        }

        // Pequeño respiro al CPU (opcional)
        delay(1000);
    }
}
