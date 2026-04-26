BITS ?= 32

ifeq ($(BITS),64)
    EXEFILE = dither64
    ASMFILES = bwdither64 bwdither64new
    CCFMT = -m64
    NASMFMT = -f elf64
else
    EXEFILE = dither32
    ASMFILES = bwdither32 bwdither32new
    CCFMT = -m32
    NASMFMT = -f elf32
endif

OBJECTS = $(EXEFILE).o $(ASMFILES:=.o)
CCOPT = -g
NASMOPT = -g -F dwarf -w+all

.c.o:
	cc $(CCFMT) $(CCOPT) -c $<

.s.o:
	nasm $(NASMFMT) $(NASMOPT) -l $*.lst $<

$(EXEFILE): $(OBJECTS)
	cc $(CCFMT) $(CCOPT) -o $@ $^ -lm

.PHONY: clean 32 64 all

32:
	$(MAKE) BITS=32

64:
	$(MAKE) BITS=64

all: 32 64
	
clean:
	rm -f *.o *.lst dither32 dither64

