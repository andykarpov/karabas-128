#!/bin/sh

ghdl -a --ieee=synopsys karabas_128.vhd 
ghdl -a --ieee=synopsys karabas_128_tb.vhd 
ghdl -e --ieee=synopsys karabas_128_tb
ghdl -r --ieee=synopsys karabas_128_tb --stop-time=100ms --wave=karabas_128.ghw

