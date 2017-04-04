#
# Copyright (c) 2016, ARM Limited and Contributors. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# Neither the name of ARM nor the names of its contributors may be used
# to endorse or promote products derived from this software without specific
# prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#

# Cross Compile
#
# For a default cross-compile we use the naming convention from crosstools-ng
# as this toolchain can be easily and quickly regenerated from source.
CROSS_COMPILE ?= arm-cortex_m0-eabi-

# Build architecture
ARCH := cortex-m0

# Build platform
PLAT_M0	?= rk3399m0

V ?= 0
ifeq (${V},0)
	Q=@
else
	Q=
endif
export Q

.SUFFIXES:

INCLUDES		+= -Iinclude/ \
			   -Iinclude/shared/

# NOTE: Add C source files here
C_SOURCES		:= src/startup.c \
			   src/main.c	\
			   src/suspend.c \
			   src/dram.c	\
			   src/stopwatch.c

# Flags definition
COMMON_FLAGS		:= -g -mcpu=$(ARCH) -mthumb -Wall -Os -nostdlib -mfloat-abi=soft
CFLAGS			:= -ffunction-sections -fdata-sections -fomit-frame-pointer -fno-common
ASFLAGS			:= -Wa,--gdwarf-2
LDFLAGS			:= -Wl,--gc-sections -Wl,--build-id=none

# Cross tool
CC			:= ${CROSS_COMPILE}gcc
CPP			:= ${CROSS_COMPILE}cpp
AR			:= ${CROSS_COMPILE}ar
OC			:= ${CROSS_COMPILE}objcopy
OD			:= ${CROSS_COMPILE}objdump
NM			:= ${CROSS_COMPILE}nm

define SOURCES_TO_OBJS
	$(patsubst %.c,%.o,$(filter %.c,$(1))) \
	$(patsubst %.S,%.o,$(filter %.S,$(1)))
endef

CSRC := $(C_SOURCES)
OBJS := $(CSRC:.c=.o) $(SSRC:.s=.o)

LINKERFILE		:= $(PLAT_M0).ld
MAPFILE			:= $(PLAT_M0).map
ELF 			:= $(PLAT_M0).elf
BIN 			:= $(PLAT_M0).bin
LINKERFILE_SRC		:= src/$(PLAT_M0).ld.S

%.o : %.c
	@echo "  CC      $<"
	$(Q)$(CC) $(COMMON_FLAGS) $(CFLAGS) $(INCLUDES) -MMD -MT $@ -c $< -o $@

$.o : %.s
	@echo "  AS      $<"
	$(Q)$(CC) -x assembler-with-cpp $(COMMON_FLAGS) $(ASFLAGS) -c $< -o $@

.DEFAULT_GOAL := $(BIN)

$(LINKERFILE): $(LINKERFILE_SRC)
	$(CC) $(COMMON_FLAGS) $(INCLUDES) -P -E -D__LINKER__ -MMD -MF $@.d -MT $@ -o $@ $<
-include $(LINKERFILE).d

$(ELF) : $(OBJS) $(LINKERFILE)
	@echo "  LD      $@"
	$(Q)$(CC) -o $@ $(COMMON_FLAGS) $(LDFLAGS) -Wl,-Map=$(MAPFILE) -Wl,-T$(LINKERFILE) $(OBJS)

$(BIN) : $(ELF)
	@echo "  BIN     $@"
	$(Q)$(OC) -O binary $< $@

clean:
	@echo "  CLEAN"
	$(Q)rm -f $(OBJS) $(ELF) $(BIN) $(LINKERFILE)

$(eval $(call MAKE_OBJS,$(BUILD),$(SOURCES),$(1)))
