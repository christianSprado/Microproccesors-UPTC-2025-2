# Makefile — Build & run en QEMU 'virt' (RV32IM)
# Por defecto usamos un toolchain con newlib:
CROSS ?= riscv-none-elf-

CC      := $(CROSS)gcc
AS      := $(CROSS)gcc
LD      := $(CROSS)gcc
OBJDUMP := $(CROSS)objdump
OBJCOPY := $(CROSS)objcopy
GDB     := $(CROSS)gdb

ARCH    := -march=rv32im_zicsr -mabi=ilp32 -mcmodel=medany
CFLAGS  := $(ARCH) -O0 -g3 -Wall -Wextra -ffreestanding -fno-builtin -fdata-sections -ffunction-sections -Iinc
ASFLAGS := $(ARCH) -g3 -Iinc
LDFLAGS := $(ARCH) -T link.ld -nostdlib -nostartfiles -Wl,--gc-sections

BUILD   := build
TARGET  := $(BUILD)/app.elf

SRCS_C  := main.c src/stub_stdlib.c src/soc_uart.c src/systimer.c src/soc_emu_gpio.c src/trap.c
SRCS_S  := Start.S
OBJS    := $(SRCS_C:%.c=$(BUILD)/%.o) $(SRCS_S:%.S=$(BUILD)/%.o)

all: $(TARGET)

$(BUILD):
	@mkdir -p $(BUILD)/src

$(BUILD)/%.o: %.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/%.o: %.S | $(BUILD)
	$(AS) $(ASFLAGS) -c $< -o $@

$(TARGET): $(OBJS) link.ld
	$(LD) $(OBJS) $(LDFLAGS) -Wl,-Map,$(TARGET:.elf=.map) -Wl,--start-group -lc -lgcc -Wl,--end-group -o $@
	$(OBJDUMP) -D $@ > $(TARGET:.elf=.lst)
	$(OBJCOPY) -O binary $@ $(TARGET:.elf=.bin)

clean:
	rm -rf $(BUILD)

run: $(TARGET)
	qemu-system-riscv32 -M virt -nographic -bios none -kernel $(TARGET)

gdbserver: $(TARGET)
	qemu-system-riscv32 -M virt -nographic -bios none -kernel $(TARGET) -S -s

gdb: $(TARGET)
	$(GDB) $(TARGET) -ex 'target remote :1234' -ex 'layout regs'

.PHONY: all clean run gdbserver gdb
