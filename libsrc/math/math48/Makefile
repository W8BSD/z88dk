#
# Wahey, a messed up makefile for building libraries!
#

include ../../Make.config

TARGET ?= test

#NEWLIBGLOBS := "$(NEWLIB_DIRECTORY)/math/float/math48/c/sccz80/*.asm" "$(NEWLIB_DIRECTORY)/math/float/math48/c/sdcc_ix/*.asm" "$(NEWLIB_DIRECTORY)/math/float/math48/lm/c/sccz80/*.asm" "$(NEWLIB_DIRECTORY)/math/float/math48/lm/c/sdcc_ix/*.asm" "$(NEWLIB_DIRECTORY)/math/float/math48/lm/z80/*.asm" "$(NEWLIB_DIRECTORY)/math/float/math48/z80/*.asm"

AFILES = $(wildcard *.asm)
CFILES  = $(wildcard *.c) 
OBJECTS = $(CFILES:.c=.o) $(AFILES:.asm=.o)

CFLAGS += -DFLOAT_IS_48BITS

all: dirs $(OUTPUT_DIRECTORY)/math48.lib $(OUTPUT_DIRECTORY)/math48_ixiy.lib \
	$(OUTPUT_DIRECTORY)/math48_z80n.lib \
	$(OUTPUT_DIRECTORY)/math48_z180.lib \
	$(OUTPUT_DIRECTORY)/math48_ez80_z80.lib


$(OUTPUT_DIRECTORY)/math48.lib: $(addprefix obj/z80/, $(OBJECTS))
	@$(ASSEMBLER) -d -O=obj/z80/x/x -I.. -mz80 -D__CLASSIC @newlibfiles.lst
	TYPE=z80 $(LIBLINKER) -x$(OUTPUT_DIRECTORY)/math48 @math48.lst

$(OUTPUT_DIRECTORY)/math48_z180.lib: $(addprefix obj/z180/, $(OBJECTS))
	@$(ASSEMBLER) -d -O=obj/z180/x/x -I.. -mz180 -D__CLASSIC @newlibfiles.lst
	TYPE=z180 $(LIBLINKER) -x$(OUTPUT_DIRECTORY)/math48_z180 @math48.lst

$(OUTPUT_DIRECTORY)/math48_z80n.lib: $(addprefix obj/z80n/, $(OBJECTS))
	@$(ASSEMBLER) -d -O=obj/z80n/x/x -I.. -mz80n -D__CLASSIC @newlibfiles.lst
	TYPE=z80n $(LIBLINKER) -x$(OUTPUT_DIRECTORY)/math48_z80n @math48.lst

$(OUTPUT_DIRECTORY)/math48_ez80_z80.lib: $(addprefix obj/ez80_z80/, $(OBJECTS))
	@$(ASSEMBLER) -d -O=obj/ez80_z80/x/x -I.. -mez80_z80 -D__CLASSIC @newlibfiles.lst
	TYPE=ez80_z80 $(LIBLINKER) -x$(OUTPUT_DIRECTORY)/math48_ez80_z80 @math48.lst

$(OUTPUT_DIRECTORY)/math48_ixiy.lib: $(addprefix obj/ixiy/, $(OBJECTS))
	@$(ASSEMBLER) -d -O=obj/ixiy/x/x -I.. -mz80 -IXIY -D__CLASSIC @newlibfiles.lst
	TYPE=ixiy $(LIBLINKER) -x$(OUTPUT_DIRECTORY)/math48_ixiy -IXIY @math48.lst

dirs:
	@mkdir -p obj/z80 obj/ixiy obj/r2k obj/z80/cimpl obj/z80n/cimpl obj/z180/cimpl obj/ez80_z80/cimpl

.PHONY: dirs

clean:
	$(RM) *.o* *.sym *.map *.err zcc_opt.def *.i
	$(RM) -fr obj
