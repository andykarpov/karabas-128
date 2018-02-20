# ERRATA for PCB rev.A:

1) LM2596S has been a bit improperly routed, so there are a bit of noise. Possibly fixes: solder capacitors as close as possible to the unit.

2) It is better to power PAL coder via noise filter, so you need to cut one of the 5V track that power AD724 and put a ferrite bead or inductor + a ceramic and electrolytic caps to it as close as possible

3) MiniDin8 for RGB output has a mirrored layout
 
4) CLK on ZX BUS edge connector is not inverted. This can cause problems on ZX Spectrum peripherial devices that uses clock to sync, like DivMMC, etc.
Possibly fix: cut the track from ZX BUS edge connector and route Z80_CLK (from Z80 pin 6) via one of the free inverted hex buffer IC4 (pins 5,6 for example).

