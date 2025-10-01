# Microproccesors-UPTC-2025-2
Parcial 2. 

Estos son los archivos para la compilación de un contadore limitado a 8 bits.
Son el resultado del segundo punto del parcial de microprocesadores del semestre 2025-2


2). Make file, start.s

start.s
Nos guiamos del main que nos brinda el taller, en la carpeta inc están los headers con mapas de registros y csr y en la carpeta src están los drivers UART/GPIO/timer y nwelib. Los headers hacen acceso a los registros y csr entonces nuestro arranque debe poder escribir mtvec (vecstor de trampas).
Qemu virtual sitúa la DRAM en 0x8000_0000 y cargamos el ELF con bios none -kernel app.elf qemu salta directo a nuestro _start 
Como estamos en baremetal debemos inicializar el stack, limpiar .bss y si hace falta copiar .datay también transferir el control a main.

-	Empezamos con el archivo start.s
    

.option norelax descativa ciertos descuidos de esamblador como símbolos pequeños
.section .init donde colocamos la sección  

.globl _start / etiqueta _start:
Declaramos y definimos el punto de entrada del programa

la sp, _stack_top
Cargamos la dirección del tope de pila en sp. _stack_top lo define link.ld al final de la RAM

¿Por qué?* La **.bss** (variables globales no inicializadas) debe arrancar en **cero**.  
*Detalles:*  
- `_sbss` y `_ebss` son símbolos del linker (inicio/fin de `.bss`)




linker
Define la memoria y el layout de secciones. Para QEMU virt usamos RAM en 0x80000000. Exporta símbolos para Start.S y define _end (útil para stubs Newlib)

-	ENTRY(_start) obliga a que el punto de entrada sea nuestro _start de Start.S.
-	 PROVIDE(_end = .); soluciona el error de stub_stdlib.c que busca _end.
-	__global_pointer$ es opcional (apoyo a small data).

MAKE
-	Usar el toolchain con newlib: CROSS ?= riscv-none-elf-.
-	Incluir Zicsr: -march=rv32im_zicsr.
-	Generar ELF, LST (desensamblado) y BIN.
-	Objetivos “amigables”: make, make run, make gdbserver, make gdb.


Trap.c

Start.S pone mtvec = risc_v_trap_handler. Debemos definir ese símbolo para evitar “undefined reference”. Con un handler débil:

#include <stdint.h>
__attribute__((weak))
void risc_v_trap_handler(void) {
    while (1) { __asm__ volatile("wfi"); }
}


ESTRUCTURA DE LOS ARCHIVOS DEL PROGRAMA
Midtemr_II_qemu/
 ├─ Start.S
 ├─ link.ld
 ├─ Makefile
 ├─ main.c
 ├─ inc/
 │   ├─ rv32.h        → alias a riscv32.h si hace falta
 │   ├─ rv32_regs.h   → alias a riscv32_regs.h si hace falta
 │   ├─ riscv-csr.h
 │   ├─ soc_regs.h
 │   ├─ soc_uart.h
 │   ├─ systimer.h
 │   └─ soc_emu_gpio.h
 └─ src/
     ├─ stub_stdlib.c
     ├─ soc_uart.c
     ├─ systimer.c
     ├─ soc_emu_gpio.c
     └─ trap.c        ← handler  (lo agregamos nosotros)
 

Creamos ya los 3 archivos: star.s make fike y el linker
AHORA EJECUTAMOS CON MAKE CLEAR PARA LIMPIAR PARA BORRAR CUALQUIER CARPETA BUILD CON LOS ELF BIN ETC
DESPUES CON MAKE COMPILA DE CERO Y GENERA LOS ARCHIVOS ANTERIOR MENCIONADOS PARA CORRECTO FUNCIONAMIENTO.

 
El warning nos dice que en el MAIN una comparación de un valor sin signo con <0 siempre es falsa nos ice que la parte if (sw_value < 0) hace una comparación con un valor sin d¿signo y siempre es falsa (si el error esta en el main es el posible bug)
“Y el error que nos da esque debemos incluir riscv-csr.h que exige el compilador use una flag – march con la extensión Zicsr para acceder a CSR” zicsr habilita instrucciones de CSR que es el control and status registers y lo solucionamos agregando en el make file ampliando : -march=rv32im_zicsr


En el main dice que para salir hay que oprimir CTRL + A y después C pero en realidad para salir de qemu es con X
DESPUES:   ……………………….

EN UN TERMINAL LANZAMOS QEMU CON EL SIGUIENTE COMANDO: 
qemu-system-riscv32 -M virt -nographic -serial mon:stdio -bios none -kernel build/app.elf -S -s

•	qemu-system-riscv32 → ejecuta QEMU para RISC-V de 32 bits.
•	-M virt → usa la máquina “virt” (RAM en 0x8000_0000, UART 16550 en 0x1000_0000, etc.).
•	-nographic → sin ventana gráfica; todo por terminal.
•	-serial mon:stdio → multiplexa monitor y UART en la misma terminal.
•	-bios none → no carga firmware; saltará a tu _start del ELF.
•	-kernel build/app.elf → carga tu binario.
•	-S → no arranca la CPU; queda en reset esperando a GDB.
•	-s → abre el servidor GDB en tcp::1234 (equivale a -gdb tcp::1234

DESPUES VAMOS A OTRO TERMINAL Y EJECUTAMOS: 

riscv-none-elf-gdb build/app.elf      # abre tu programa en el depurador
target remote :1234                          # se conecta al QEMU (que escucha en el puerto 1234)
monitor system_reset                       # reinicia la CPU al inicio (_start)
break main                                        # pone un breakpoint en main()
continue                                           # corre hasta entrar a main
next                                                  # avanza una línea (ejecuta la declaración de sw_value)
watch sw_value                              # vigila cambios en la variable sw_value
continue                                         # sigue ejecutando y se detendrá cada vez que sw_value cambie


se va a demorar en el ultimo comando de gdb 



 

En las líneas rojas mostramos los valores de sw_value, lo que pasa esque en QEMU al presionar la tecla d decrementamosen el contaodr de l bash de la fecha azul, ahí presionamos d para decrementar y cuando ya está en cero vuelve y decrementa cuando no debería ser asi, debería mantenerse en cero. Lo que esta ocurriendo es underflow en vez de -1 se convierte en ese numero grande 4294967295 porque definimos 
Aca vemos como el viejo valor es 0 y si lo volvemos a dar d para bajar el contador por el error hace underflow: que el resultado sea tan pequeño que no sea representable.
Cuando sw_value es unit32_t (ósea entero sin signo) y bajamo de cero el valor se convierte en 0Xffffffff 
Como es unsigned el valor nunca puede ser menor a cero.

LA SOLUCION ES CAMBIARLO A INT32_T es decir cuanod hace el sw_value < 0 lo vuelve a cero y no hay salto
Int32_t : es entero con signo tanto negativo como positivo
Pero esta solución deja que el contador baje a números negativos y si es por UART y por gpio no podemos permitir, entonces lo que debemos es cambiar la lógica y solo decrementar si es mayor a cero

Lo que pasa esque al hacer la comparación jamás se cumplirá entonces eso provaca el underflow y como es de 32 bits lo que hará es tomar el valos de 0xFFFFFFFF




Headers con nombre mixtos rv32 y riscv32
Falto zicsr: que es una extensión del ISA para manipular los CSR: y estos son registros especiales de control/estado del procesador 
Bare metal: sin sistema operativo
UART: periferico 
GDB: depurador que se conecta con QEMU para mirar memoria, registros, poner breakpoints, varianles y asi
QEMU: emulador de hardware, agarra nuestro ELF RV32 como si fuera un chip deverdad
RV32: conjunto de instrucciones de riscv de 32 bits 


AHORA LO VAMOS A ARREGLAR

En nuestro main tenemos: 

else if (c == 'd') {
    sw_value--;              // puede decrementar 0 → 0xFFFFFFFF (underflow)
}
if (sw_value < 0) { sw_value = 0; }  // nunca se cumple: sw_value es unsigned


y lo modificamos:

else if (c == 'd') {
    if (sw_value > 0) sw_value--;    // evita 0 → 0xFFFFFFFF
}
// ya no usamos (sw_value < 0) porque es unsigned y jamás será < 0

sw_value es uint32_t (sin signo). En C, 0−1 “se envuelve” a 0xFFFFFFFF. Al prohibir decrementar en 0, el underflow no ocurre. Resultado: el contador nunca salta a 0xFFFFFFFF; se queda en 0..255 como debe.
AHORA LIMPIAMOS LOS ARCHIVOS CON MAKE CLEAN Y VOLVEMOS A COMPILAR CON MAKE
DESPUES VOLVEMOS A LOS COMANDOS DE QEMU Y GDB PARA DEPURAR Y VERIFICAMOS
Ahora si el contador no debe hacer underflow y tiene un limite de 255 contando el 0
 
