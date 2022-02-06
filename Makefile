###### GD32V Makefile ######


######################################
# target
######################################
TARGET = longan-impact


######################################
# building variables
######################################
# debug build?
DEBUG = 1
# optimization
OPT = -Os -mtune=nuclei-200-series

# Build path
BUILD_DIR = build

FIRMWARE_DIR := firmware
SYSTEM_CLOCK := 8000000U

######################################
# source
######################################
# C sources
C_SOURCES =  \
$(wildcard $(FIRMWARE_DIR)/standard_peripheral/src/*.c) \
$(wildcard $(FIRMWARE_DIR)/standard_peripheral/*.c) \
$(wildcard $(FIRMWARE_DIR)/nuclei/stubs/*.c) \
$(wildcard $(FIRMWARE_DIR)/nuclei/drivers/*.c) \
$(FIRMWARE_DIR)/gd32vf103c_longan_nano.c \
$(wildcard src/*.c) \
# $(wildcard $(FIRMWARE_DIR)/usbfs_driver/src/*.c) \

# ASM sources
ASM_SOURCES =  \
$(FIRMWARE_DIR)/nuclei/init/start.S \
$(FIRMWARE_DIR)/nuclei/init/entry.S

######################################
# firmware library
######################################
#PERIFLIB_SOURCES = \
# $(wildcard Lib/*.a)

#######################################
# binaries
#######################################

PREFIX = riscv-nuclei-elf-
CC = $(PREFIX)gcc
AS = $(PREFIX)gcc -x assembler-with-cpp
CP = $(PREFIX)objcopy
AR = $(PREFIX)ar
SZ = $(PREFIX)size
OD = $(PREFIX)objdump
HEX = $(CP) -O ihex
BIN = $(CP) -O binary -S

#######################################
# CFLAGS
#######################################
# cpu
ARCH = -march=rv32imac -mabi=ilp32 -mcmodel=medlow

# macros for gcc
# AS defines
# AS_DEFS =

# C defines
C_DEFS =  \
-DUSE_STDPERIPH_DRIVER \
-DHXTAL_VALUE=$(SYSTEM_CLOCK) \
-DDEBUG_USART_BAUDRATE=57600U \
#-DUSE_USB_FS \

# AS includes
AS_INCLUDES =

# C includes
C_INCLUDES =  \
-I./include \
-I$(FIRMWARE_DIR)/standard_peripheral/include \
-I$(FIRMWARE_DIR)/standard_peripheral \
-I$(FIRMWARE_DIR)/nuclei/drivers \
-I$(FIRMWARE_DIR) \
#-I$(FIRMWARE_DIR)/usbfs_driver/include \

# compile gcc flags
ASFLAGS := $(CFLAGS) $(ARCH) $(AS_DEFS) $(AS_INCLUDES) $(OPT) -Wl,-Bstatic

CFLAGS := $(CFLAGS) $(ARCH) $(C_DEFS) $(C_INCLUDES) $(OPT) -Wl,-Bstatic  -ffunction-sections -fdata-sections

ifeq ($(DEBUG), 1)
CFLAGS += -g -gdwarf-2
endif

# Generate dependency information
CFLAGS += -std=gnu11 -MMD -MP #.deps/$(notdir $(<:.c=.d)) -MF$(@:%.o=%.d) -MT$(@:%.o=%.d)

#######################################
# LDFLAGS
#######################################
# link script
LDSCRIPT = $(FIRMWARE_DIR)/longan_nano_flashxip.lds

# libraries
#LIBS = -lc_nano -lm
LIBDIR =
LDFLAGS = $(OPT) $(ARCH) -T$(LDSCRIPT) $(LIBDIR) $(LIBS) $(PERIFLIB_SOURCES) -Wl,--cref -Wl,--no-relax -Wl,--gc-sections -Wl,-M=$(BUILD_DIR)/$(TARGET).map -nostartfiles

# default action: build all
all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/$(TARGET).bin

#######################################
# build the application
#######################################
# list of objects
OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
vpath %.c $(sort $(dir $(C_SOURCES)))
# list of ASM program objects
OBJECTS += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:.S=.o)))
vpath %.S $(sort $(dir $(ASM_SOURCES)))

$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR) .deps
	@echo "CC $<"
	@$(CC) -c $(CFLAGS) -MMD -MP \
		-MF .deps/$(notdir $(<:.c=.d)) \
		-Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.c=.lst)) $< -o $@

$(BUILD_DIR)/%.o: %.S Makefile | $(BUILD_DIR) .deps
	@echo "AS $<"
	@$(AS) -c $(CFLAGS) -MMD -MP  \
		-MF .deps/$(notdir $(<:.S=.d)) $< -o $@

$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS) Makefile
	@echo "LD $@"
	@$(CC) $(OBJECTS) $(LDFLAGS) -o $@
	@echo "OD $@"
	@$(OD) $(BUILD_DIR)/$(TARGET).elf -xS > $(BUILD_DIR)/$(TARGET).S $@
	@echo "SIZE $@"
	@$(SZ) $@

$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	@echo "OBJCOPY $@"
	@$(HEX) $< $@

$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	@echo "OBJCOPY $@"
	@$(BIN) $< $@

$(BUILD_DIR):
	mkdir $@

.deps:
	mkdir $@

#######################################
# clean up
#######################################

clean:
	-rm -fR .deps $(BUILD_DIR)

#######################################
# dependencies
#######################################
-include $(shell mkdir .deps 2>/dev/null) $(wildcard .deps/*)

# *** EOF ***
