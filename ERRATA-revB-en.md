# ERRATA for PCB rev.B:

1) LDO regulator 3.3V is not required, so it can be jumped with 0Ohm resistor.

2) CLK on ZX BUS edge connector is not inverted. This can cause problems on ZX Spectrum peripherial devices that uses clock to sync, like DivMMC, etc.
Possibly fix: cut the track from ZX BUS edge connector and route Z80_CLK (from Z80 pin 6) via one of the free inverted hex buffer IC4 (pins 5,6 for example).

