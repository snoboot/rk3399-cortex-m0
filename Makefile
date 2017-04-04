#
# Copyright (c) 2017, Theobroma Systems Design und Consulting GmbH.
# All rights reserved.
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
USE_INTERNAL_TOOLCHAIN ?= 0
ifneq (${USE_INTERNAL_TOOLCHAIN}, 0)
	CROSS_COMPILE = crosstools/arm-cortex_m0-eabi/bin/arm-cortex_m0-eabi-
else
# For a default cross-compile we use the naming convention from crosstools-ng
# as this toolchain can be easily and quickly regenerated from source.
	CROSS_COMPILE ?= arm-cortex_m0-eabi-
endif

CC = $(CROSS_COMPILE)gcc
CXX = $(CROSS_COMPILE)g++
LD =  $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump

# Build platform
OUT ?= rk3399m0

V ?= 0
ifeq (${V},0)
	Q=@
else
	Q=
endif
export Q

ifneq (${USE_INTERNAL_TOOLCHAIN}, 0)
	DEP_CC = $(CC)
	DEP_CXX = $(CXX)
	DEP_LD = $(LD)
	DEP_OBJCOPY = $(OBJCOPY)
	DEP_OBJDUMP = $(OBJDUMP)
endif

# C sources
CSRC  = src/startup.c \
	src/main.c \
	src/suspend.c \
	src/dram.c \
	src/stopwatch.c

# Assembly sources
SSRC  =

# Flags definition
OPTFLAGS = -Os -g -ffunction-sections -fdata-sections -flto -fno-fat-lto-objects
INCPATHS = -Iinclude/ \
	   -Iinclude/shared/
DEFINE =

CFLAGS = $(INCPATHS) $(OPTFLAGS) $(DEFINE) -mcpu=cortex-m0
LDFLAGS = -nostdlib -nostartfiles -Wl,--gc-sections $(OPTFLAGS) -Wl,--build-id=none $(CFLAGS)
LIBS =

# Object defines
COBJ = $(CSRC:.c=.o)
SOBJ = $(SSRC:.s=.o)

LDSCRIPT = $(OUT).ld
LDSCRIPT_SRC = src/$(OUT).ld.S

OUTMAP = $(OUT).map
OUTELF = $(OUT).elf
OUTBIN = $(OUT).bin

all: $(OUTBIN)

$(COBJ) : %.o : %.c $(DEP_CC)
	@echo "  CC      $<"
	$(Q)$(CC) $(CFLAGS) -c $< -o $@

$(SOBJ) : $.o : %.s $(DEP_CC)
	@echo "  AS      $<"
	$(Q)$(CC) -x assembler-with-cpp $(CFLAGS) -c $< -o $@

$(LDSCRIPT): $(LDSCRIPT_SRC) $(DEP_CC)
	@echo "  LDSCRIPT  "
	$(Q)$(CC) $(CFLAGS) $(LDFLAGS) -P -E -D__LINKER__ -o $@ $<

$(OUTMAP) $(OUTELF) : $(COBJ) $(SOBJ) $(LDSCRIPT) $(DEP_CC)
	@echo "  LINK    $@"
	$(Q)$(CC) -o $@ $(CFLAGS) $(LDFLAGS) -Wl,-Map=$(OUTMAP) -Wl,-T$(LDSCRIPT) $(COBJ) $(SOBJ) $(LIBS)

$(OUTBIN) : $(OUTELF) $(DEP_OBJDUMP)
	@echo "  BIN     $@"
	$(Q)$(OBJCOPY) -O binary $(OUTELF) $(OUTBIN)

clean:
	@echo "  CLEAN"
	$(Q)rm -f $(SOBJ) $(COBJ) $(OUTMAP) $(OUTELF) $(OUTBIN) $(LDSCRIPT)

# Incantation to use an 'internal toolchain' via cosstool-ng

crosstools/crosstool-ng/bootstrap:
	@echo "  GIT     [submodule-update] crosstool-ng"
	$(Q)git submodule update --init --recursive

crosstools/crosstool-ng/configure: crosstools/crosstool-ng/bootstrap
	@echo "  GEN     $@"
	$(Q)(cd crosstools/crosstool-ng; ./bootstrap;)

crosstools/crosstool-ng/Makefile: crosstools/crosstool-ng/configure
	$(Q)(cd crosstools/crosstool-ng; ./configure --enable-local)

crosstools/crosstool-ng/ct-ng: crosstools/crosstool-ng/Makefile
	$(Q)make -C crosstools/crosstool-ng install MAKELEVEL=0

TOOLPATH = `pwd`/crosstools/arm-cortex_m0-eabi
CTNG_DEFCONFIG = crosstools/defconfig

crosstools/arm-cortex_m0-eabi/bin/arm-cortex_m0-eabi-gcc: $(CTNG_DEFCONFIG) crosstools/crosstool-ng/ct-ng
	@echo "  CT-NG   defconfig"
	$(Q)(cd crosstools/crosstool-ng; ./ct-ng defconfig DEFCONFIG=../defconfig)
	$(Q)sed -r -i.org s%CT_PREFIX_DIR=.*%CT_PREFIX_DIR=$(TOOLPATH)% crosstools/crosstool-ng/.config
	@echo "  CT-NG   build"
	$(Q)(cd crosstools/crosstool-ng; ./ct-ng build)

crosstools/arm-cortex_m0-eabi:
	@echo "  MKDIR   $@"
	$(Q)mkdir $@
