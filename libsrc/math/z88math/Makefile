#

include ../../Make.config

vpath %.c ../cimpl/

AFILES  = $(wildcard c/sccz80/*.asm) $(wildcard z80/*asm)
CFILES  = cosh.c sinh.c tanh.c modf.c tofix16.c fromfix16.c fmin.c fmax.c
OBJECTS = $(AFILES:.asm=.o) $(CFILES:.c=.o)

CFLAGS +=  -math-z88 -D__Z88__ -D__NATIVE_MATH__ -DFLOAT_IS_48BITS

all: dirs $(OUTPUT_DIRECTORY)/z88_math.lib $(OUTPUT_DIRECTORY)/bbc_math.lib $(OUTPUT_DIRECTORY)/bbc_math_ixiy.lib \
	$(OUTPUT_DIRECTORY)/bbc_math_z80n.lib \
	$(OUTPUT_DIRECTORY)/bbc_math_z180.lib \
	$(OUTPUT_DIRECTORY)/bbc_math_ez80_z80.lib


$(OUTPUT_DIRECTORY)/z88_math.lib: $(addprefix obj/z88/, $(OBJECTS))
	TYPE=z88 $(LIBLINKER) -x$(OUTPUT_DIRECTORY)/z88_math @z88math.lst

$(OUTPUT_DIRECTORY)/bbc_math.lib: $(addprefix obj/z80/, $(OBJECTS))
	TYPE=z80 $(LIBLINKER) -x$(OUTPUT_DIRECTORY)/bbc_math @z88math.lst

$(OUTPUT_DIRECTORY)/bbc_math_z80n.lib: $(addprefix obj/z80n/, $(OBJECTS))
	TYPE=z80n $(LIBLINKER) -x$(OUTPUT_DIRECTORY)/bbc_math_z80n @z88math.lst

$(OUTPUT_DIRECTORY)/bbc_math_ez80_z80.lib: $(addprefix obj/ez80_z80/, $(OBJECTS))
	TYPE=ez80_z80 $(LIBLINKER) -x$(OUTPUT_DIRECTORY)/bbc_math_ez80_z80 @z88math.lst

$(OUTPUT_DIRECTORY)/bbc_math_z180.lib: $(addprefix obj/z180/, $(OBJECTS))
	TYPE=z180 $(LIBLINKER) -x$(OUTPUT_DIRECTORY)/bbc_math_z180 @z88math.lst

$(OUTPUT_DIRECTORY)/bbc_math_ixiy.lib: $(addprefix obj/ixiy/, $(OBJECTS))
	TYPE=z80 $(LIBLINKER) -IXIY -x$(OUTPUT_DIRECTORY)/bbc_math_ixiy @z88math.lst

obj/z88/%.o: %.c
	$(ZCC) +test -mz80 $(CFLAGS) -o $@  $^


obj/z88/%.o: %.asm
	$(Q)$(ASSEMBLER) -I../ -I$(Z88DK_LIB) -mz80 -D__CLASSIC -DFORz88 -Oobj/z88 $^

dirs:
	@mkdir -p obj/z80/c/sccz80 obj/ixiy/c/sccz80 obj/z88/c/sccz80 obj/z80/z80 obj/ixiy/z80 obj/z88/z80 

clean:
	$(RM) *.o* *.sym *.map *.err zcc_opt.def *.i *.opt
	$(RM) -fr obj

