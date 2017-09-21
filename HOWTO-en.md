# Assembly instructions:

It's recommended to start assembly process from soldering an SMD components on the PCB, like IC10, IC11, IC13, L1, C3, C37, C38, C39 and C40. To solder Altera's CPLD  EPM7128STC100 it's strongly recommended to use a hot air or soldering station with a special solder tip "mini-wave" to perform a drag soldering.

Soldering of the rest of components is not so important. I did mounted a DIP panels first, then resistors, diodes, capacitors, transistors, connectors, etc.

Warning: Please do not put any DIP IC's into their sockets on the PCB before a first programming of the CPLD. 

## Common warnings:

1) jumpers settings:

* jumper **JP1**: always in the bottom position
* jumpers **JP2/JP3**: depends on the ROM IC used (W27C512, 27C512, 27C256, AT28C256) and must be switched in the following positions:
	* for W27C512 / 27C512 / 27C256: JP2 in the bottom position, JP3 in the upper position
	* for AT28C256: JP2 in the upper position, JP3 in the bottom position
* jumper **JP5** is used to switch an internal speaker on and off. Left position means "On" state, right position - "Off" state.

2) I skipped to use a rectifier **B1**, instead of it i soldered two wires. It allows me to mount C34 in horizontal position.

3) FFC connectors **X7** and **X8** for keyboard must be placed the same way like described on the working prototype photos. Their orientation is highly important.

4) You can use any other low-power general purpose transistors instead of **BC548** with the same pinout and features.

5) You can use soviet union's **KT361** transistors instead of **2SA1175**. Emmiter on the bottom, Base on the top.

6) You can try to use a 1206 or 0805 SMD capacitors instead of wired ones, soldering them on top (or bottom) of their places.

7) ROM firmware:

- The original 32kB ZX Spectrum ROM for 64kB ROM IC (27C512 or W27C512) should be programmed on both halfs, but only upper bank will be used (when A15=1).
- The original 32kB ZX Spectrum ROM for 32kB ROM IC (27C256 or AT28C256) should be programmed as is.

## Uploading firmware into the Altera EPM7128STC100 CPLD:

* connect USB Blaster to the X6 "JTAG" connector
* power on the PCB
* open karabas_128.pof in the Quartus Programmer, then tick a "program" checkbox, then push the "Program" button.
* after firmware is uploaded, power down the board, as well as disconnect your USB Blaster from the board
* your board is ready to run

## First run

Correctly soldered and programmed board does not require any additional adjustments.
 
All other tweaks could be performed via changing the CPLD firmware, as described above.

## Upgrade to support mode switch

It is posible to switch between pentagon and ula48 (with contended memory emulation) screen modes.

To enable this feature one small hardware patch should be applied, like described on the photo below. A diode should be soldered between A11 and N_RESET signals, anode to A11 and cathode to N_RESET.

Then you'll be able to switch using hotkeys RESET+1 for pentagon mode and RESET+2 for ula48 mode.

Special thanks goes to **solegstar** from zx-pk.ru!!!

![image](https://github.com/andykarpov/karabas-128/raw/master/docs/mode_switch_patch.jpg)
