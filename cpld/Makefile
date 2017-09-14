###################################################################
# Karabas-128 Project Makefile v1.0
# 
# Specify the basename of the design (project) and top level entity
###################################################################

PROJECT = karabas_128
TOP_LEVEL_ENTITY = karabas_128
#SYNC_MODE = classic 
SYNC_MODE = pentagon 

###################################################################
# Part, Family, Boardfile revA or revB, etc

FAMILY = "MAX7000S"
PART = EPM7128STC100-15
BOARDFILE = revA

###################################################################
# Sources

SRCS = karabas_128.vhd

###################################################################
# Additional variables

PWD := $(shell pwd)
QUARTUS_HOME := $(shell dirname `which quartus_pgm`)
PROJECT_FILE = $(PROJECT)_$(BOARDFILE)
ASSIGNMENT_FILES = $(PROJECT_FILE).qpf $(PROJECT_FILE).qsf

ifeq ($(SYNC_MODE), classic)
SYNC_MODE_PARAM = set_parameter -name SYNC_MODE 0
else
SYNC_MODE_PARAM = set_parameter -name SYNC_MODE 1
endif

###################################################################
# Main Targets
#
# all: build everything
# clean: remove output files and database
# program: program your device with the compiled design
###################################################################

all: smart.log $(PROJECT_FILE).asm.rpt $(PROJECT_FILE).sta.rpt

clean: 
	rm -f *.rpt \
		*.chg \
		smart.log \
		*.htm \
		*.eqn \
		*.pin \
		*.sof \
		*.pof \
		*.qsf \
		*.qpf \
		*.summary \
		*.smsg \
		*.cof \
		*.cdf \
		*.jdi \
		*.map \
		*.sld \

	rm -rf db \
		incremental_db \

map: smart.log $(PROJECT_FILE).map.rpt
fit: smart.log $(PROJECT_FILE).fit.rpt
asm: smart.log $(PROJECT_FILE).asm.rpt
sta: smart.log $(PROJECT_FILE).sta.rpt
smart: smart.log

###################################################################
# Executable Configuration
###################################################################

MAP_ARGS = --read_settings_file=on --write_settings_file=off
FIT_ARGS = --read_settings_file=off --write_settings_file=off
ASM_ARGS = --read_settings_file=off --write_settings_file=off 
STA_ARGS = 

###################################################################
# Target implementations
###################################################################

STAMP = echo done >

$(PROJECT)_$(BOARDFILE).map.rpt: map.chg $(SOURCE_FILES) 
	quartus_map $(MAP_ARGS) $(PROJECT_FILE) -c $(PROJECT_FILE)
	$(STAMP) fit.chg

$(PROJECT)_$(BOARDFILE).fit.rpt: fit.chg $(PROJECT_FILE).map.rpt
	quartus_fit $(FIT_ARGS) $(PROJECT_FILE) -c $(PROJECT_FILE)
	$(STAMP) asm.chg
	$(STAMP) sta.chg

$(PROJECT)_$(BOARDFILE).asm.rpt: asm.chg $(PROJECT_FILE).fit.rpt
	quartus_asm $(ASM_ARGS) $(PROJECT_FILE) -c $(PROJECT_FILE)

$(PROJECT)_$(BOARDFILE).sta.rpt: sta.chg $(PROJECT_FILE).fit.rpt
	quartus_sta $(STA_ARGS) $(PROJECT_FILE) 

smart.log: $(ASSIGNMENT_FILES)
	quartus_sh --determine_smart_action $(PROJECT_FILE) > smart.log

###################################################################
# Project initialization
###################################################################

$(ASSIGNMENT_FILES):

	quartus_sh --prepare -f $(FAMILY) -d $(PART) -t $(TOP_LEVEL_ENTITY) $(PROJECT_FILE) 
	-cat $(BOARDFILE) >> $(PROJECT_FILE).qsf
	-echo "$(SYNC_MODE_PARAM)\n" >> $(PROJECT_FILE).qsf
map.chg:
	$(STAMP) map.chg
fit.chg:
	$(STAMP) fit.chg
sta.chg:
	$(STAMP) sta.chg
asm.chg:
	$(STAMP) asm.chg

###################################################################
# Programming the device
###################################################################

program: $(PROJECT_FILE).pof
	quartus_pgm --no_banner --mode=jtag -o "P;$(PROJECT_FILE).pof"

