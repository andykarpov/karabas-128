# Karabas-128 Revision History:

## Revision A

First working revision of karabas-128.
See ERRATA for bugs and issues )


## Revision B

- Fixed bug in incorrectly routed RGB connector (thanks to Nika that reported about this issue)

- Rerouted power lines, LM8596 should be more stable

- Added inductor + cap filter for AD724 to reduce digital noise

- Added a trimcap to adjust AD724 frequency

- Replaced TL712 tape in module with CD4069 (thanks to tank-uk)

- Added 3V3 regulator to support EPM3128 CPLD

- Added LED to indicate power on


## Revision B1

- CLK_BUS signal on ZX BUS edge connector is routed via free IC4 inverter

- Removed 3V3 regulator, because EPM3128 has less i/o lines than EPM7128, so - unsupported

- Added diode for mode switch feature (RESET+1, RESET+2, etc)

