Introduction
============

This repository contains the Cortex-M0 firmware used with the RK3399
to implement power-management functionality and helpers (e.g. DRAM
frequency switching support).

Build instructions
==================

This repository requires a toolchain configured suitably to build
Cortex-M0 (the M0 differs from other M-family cores by being a ARMv6-M
instead of a ARMv7-M, which entails such differences as it not having
a hardware divide instructions).

The make-infrastructure supports both
 * using an external toolchain (pre-installed on your system)
 * building and using an "internal" toolchain

Using an internal toolchain (and have crosstools-ng build it for you)
---------------------------------------------------------------------

To use an internal toolchain (i.e. have the make-infrastructure build
it for you and keep it installed locally within your workarea), simply
specify "USE_INTERNAL_TOOLCHAIN=1" as part of your invocation to make.

Example::

	make USE_INTERNAL_TOOLCHAIN=1

Using an external toolchain via CROSS_COMPILE
---------------------------------------------

A Cortex-M0 toolchain is needed to be set as a CROSS_COMPILE
toolchain.  If the CROSS_COMPILE variable is not specified, it
defaults to 'arm-cortex_m0-eabi-'.

If you have an external (i.e. preinstalled) toolchain in your path or
want to provide an absolute path, the CROSS_COMPILE variable can be
used.

Example::

	make CROSS_COMPILE=/opt/my-toolchain/bin/arm-cortex_m0-eabi-

Building an external toolchain
------------------------------

To build a compatible toolchain from scratch, a configuration script
for crosstools-ng is included. Please refer to the crosstools-ng
documentation for details of installing and using crosstools-ng.

To use this included configuration and build a compatible toolchains,
follow the steps shown in this example:

Example::

	ct-ng defconfig DEFCONFIG=$SRCTOP/crosstools/defconfig
	ct-ng build
